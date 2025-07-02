#!/bin/bash

# ========================================
# Script para probar saturación de recursos en EKS
# ========================================

set -e

# Cargar variables de entorno
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load-env.sh"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables del test
NAMESPACE="default"
DEPLOYMENT="nginx-saturation-test"
SERVICE="nginx-saturation-service"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${PURPLE}🔥 ESCENARIO: SATURACIÓN DE RECURSOS EN EKS${NC}"
echo -e "${PURPLE}===============================================${NC}"
echo ""

# Función para mostrar estado de recursos
show_resource_status() {
    echo -e "${CYAN}📊 Estado de recursos del cluster:${NC}"
    echo "----------------------------------------"
    
    echo -e "${BLUE}Nodos:${NC}"
    kubectl get nodes -o wide
    
    echo -e "\n${BLUE}Uso de recursos por nodo:${NC}"
    kubectl top nodes 2>/dev/null || echo "❌ kubectl top no disponible (instalar metrics-server)"
    
    echo -e "\n${BLUE}Pods del test:${NC}"
    kubectl get pods -l app=$DEPLOYMENT -o wide
    
    echo -e "\n${BLUE}Uso de recursos por pod:${NC}"
    kubectl top pods -l app=$DEPLOYMENT 2>/dev/null || echo "❌ kubectl top no disponible"
}

# Función para mostrar eventos
show_events() {
    echo -e "\n${CYAN}📅 Eventos recientes:${NC}"
    echo "------------------------"
    kubectl get events --sort-by='.lastTimestamp' | tail -15
}

# Función para mostrar logs de un pod
show_pod_logs() {
    local pod_name=$1
    local container_name=${2:-nginx}
    
    echo -e "\n${CYAN}📋 Logs del pod $pod_name (contenedor: $container_name):${NC}"
    echo "----------------------------------------"
    kubectl logs $pod_name -c $container_name --tail=20 2>/dev/null || echo "No se pudieron obtener logs"
}

# Función para monitoreo continuo
monitor_saturation() {
    echo -e "\n${YELLOW}🔍 Iniciando monitoreo de saturación...${NC}"
    echo "Presiona Ctrl+C para detener el monitoreo"
    echo ""
    
    local iteration=1
    while true; do
        echo -e "${BLUE}--- Iteración $iteration ---${NC}"
        echo "$(date '+%H:%M:%S')"
        
        # Estado de pods
        echo -e "\n${GREEN}Pods:${NC}"
        kubectl get pods -l app=$DEPLOYMENT --no-headers | while read line; do
            pod_name=$(echo $line | awk '{print $1}')
            status=$(echo $line | awk '{print $3}')
            ready=$(echo $line | awk '{print $2}')
            echo "  $pod_name: $status ($ready)"
        done
        
        # Contar pods por estado
        local pending_count=$(kubectl get pods -l app=$DEPLOYMENT --no-headers | grep -c "Pending" || echo "0")
        local running_count=$(kubectl get pods -l app=$DEPLOYMENT --no-headers | grep -c "Running" || echo "0")
        local ready_count=$(kubectl get pods -l app=$DEPLOYMENT --no-headers | grep -c "1/1\|2/2" || echo "0")
        
        echo -e "\n${YELLOW}Resumen:${NC}"
        echo "  Total pods: $(kubectl get pods -l app=$DEPLOYMENT --no-headers | wc -l)"
        echo "  Running: $running_count"
        echo "  Ready: $ready_count"
        echo "  Pending: $pending_count"
        
        # Alertas
        if [ "$pending_count" -gt 0 ]; then
            echo -e "${RED}⚠️  Hay $pending_count pods en Pending (posible saturación)${NC}"
        fi
        
        if [ "$ready_count" -eq 0 ] && [ "$running_count" -gt 0 ]; then
            echo -e "${YELLOW}⚠️  Hay pods Running pero no Ready (readiness probe fallando)${NC}"
        fi
        
        echo ""
        sleep 30
        iteration=$((iteration + 1))
    done
}

# Paso 1: Verificar estado inicial del cluster
echo -e "${BLUE}1️⃣ Verificando estado inicial del cluster...${NC}"
show_config

if ! validate_aws_credentials; then
    echo -e "${RED}❌ No se pueden validar las credenciales AWS${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Cluster verificado${NC}"
echo ""

# Paso 2: Mostrar estado inicial
echo -e "${BLUE}2️⃣ Estado inicial del cluster:${NC}"
show_resource_status
echo ""

# Paso 3: Desplegar el escenario de saturación
echo -e "${BLUE}3️⃣ 🚨 Desplegando escenario de saturación...${NC}"
kubectl apply -f "$PROJECT_ROOT/kubernetes/resource-saturation-test.yaml"

echo -e "${YELLOW}⏳ Esperando que los pods se inicien...${NC}"
sleep 30

# Paso 4: Mostrar estado después del despliegue
echo -e "${BLUE}4️⃣ Estado después del despliegue:${NC}"
show_resource_status
show_events

# Paso 5: Mostrar logs de un pod para verificar el resource-hog
echo -e "${BLUE}5️⃣ Verificando logs del resource-hog...${NC}"
POD_NAME=$(kubectl get pods -l app=$DEPLOYMENT -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$POD_NAME" ]; then
    show_pod_logs "$POD_NAME" "resource-hog"
else
    echo "❌ No se encontraron pods del deployment"
fi

# Paso 6: Diagnóstico detallado
echo -e "\n${BLUE}6️⃣ 🔍 DIAGNÓSTICO DETALLADO${NC}"
echo "================================"

echo -e "\n${CYAN}Descripción de pods:${NC}"
kubectl describe pods -l app=$DEPLOYMENT | head -50

echo -e "\n${CYAN}Descripción del deployment:${NC}"
kubectl describe deployment $DEPLOYMENT

echo -e "\n${CYAN}Descripción del servicio:${NC}"
kubectl describe service $SERVICE

# Paso 7: Análisis de eventos de scheduling
echo -e "\n${BLUE}7️⃣ 📊 Análisis de eventos de scheduling:${NC}"
echo "====================================="
kubectl get events --sort-by='.lastTimestamp' | grep -E "(Scheduled|FailedScheduling|Insufficient)" | tail -10

# Paso 8: Opción de monitoreo continuo
echo -e "\n${BLUE}8️⃣ 📈 ¿Quieres monitoreo continuo?${NC}"
echo "Presiona 'y' para iniciar monitoreo continuo, cualquier otra tecla para continuar..."
read -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    monitor_saturation
fi

# Paso 9: Resumen final
echo -e "\n${GREEN}✅ RESUMEN DEL ESCENARIO${NC}"
echo "========================"
echo "🎯 Objetivo: Simular saturación de recursos en EKS"
echo "📦 Desplegado: $DEPLOYMENT con 5 réplicas"
echo "🔧 Características:"
echo "   - Readiness probe mal configurado (/noexiste)"
echo "   - Resource-hog consumiendo CPU y memoria progresivamente"
echo "   - Solicitudes de recursos altas (800m CPU, 512Mi memoria)"
echo ""
echo "📊 Resultados esperados:"
echo "   - Pods en estado Running pero no Ready"
echo "   - Posibles pods en Pending por recursos insuficientes"
echo "   - Eventos de scheduling con 'Insufficient cpu/memory'"
echo ""
echo "🧹 Para limpiar:"
echo "   kubectl delete -f $PROJECT_ROOT/kubernetes/resource-saturation-test.yaml"
echo ""
echo "🔍 Para monitorear:"
echo "   kubectl get pods -l app=$DEPLOYMENT"
echo "   kubectl describe pods -l app=$DEPLOYMENT"
echo "   kubectl get events --sort-by='.lastTimestamp'" 