#!/bin/bash

# Script para testear escenario OOMKilled
# Autor: EKS Dummy Project
# Descripción: Despliega y monitorea pods que serán terminados por OOMKilled

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con colores
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para limpiar recursos
cleanup() {
    print_status "Limpiando recursos del test OOMKilled..."
    kubectl delete -f kubernetes/oomkilled-scenario.yaml --ignore-not-found=true
    print_success "Limpieza completada"
}

# Trap para limpiar al salir
trap cleanup EXIT

# Verificar que kubectl esté disponible
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl no está instalado o no está en el PATH"
    exit 1
fi

# Verificar conexión al cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "No se puede conectar al cluster Kubernetes"
    exit 1
fi

print_status "🚀 Iniciando test de escenario OOMKilled..."
print_status "📊 Este test creará pods que serán terminados por OOMKilled"

# Desplegar el escenario
print_status "📦 Desplegando escenario OOMKilled..."
kubectl apply -f kubernetes/oomkilled-scenario.yaml

# Esperar a que los pods estén corriendo
print_status "⏳ Esperando a que los pods estén corriendo..."
kubectl wait --for=condition=Ready pods -l app=oomkilled-test --timeout=60s

print_success "✅ Pods desplegados correctamente"

# Mostrar estado inicial
print_status "📋 Estado inicial de los pods:"
kubectl get pods -l app=oomkilled-test

print_status "🔍 Monitoreando eventos de OOMKilled..."
print_status "⏰ Los pods deberían ser terminados en los próximos 2-3 minutos..."

# Monitorear eventos en tiempo real
echo ""
print_warning "=== MONITOREO DE EVENTOS OOMKILLED ==="
print_warning "Presiona Ctrl+C para detener el monitoreo"
echo ""

# Función para monitorear eventos
monitor_oomkilled() {
    local count=0
    local max_attempts=60  # 5 minutos máximo
    
    while [ $count -lt $max_attempts ]; do
        echo "⏱️  Verificando eventos... (intento $((count + 1))/$max_attempts)"
        
        # Verificar eventos de OOMKilled
        oom_events=$(kubectl get events --field-selector reason=OOMKilling --sort-by='.lastTimestamp' 2>/dev/null | grep oomkilled-test || true)
        
        if [ -n "$oom_events" ]; then
            print_success "🎯 ¡OOMKilled detectado!"
            echo "$oom_events"
            break
        fi
        
        # Mostrar estado actual de pods
        echo "📊 Estado actual de pods:"
        kubectl get pods -l app=oomkilled-test --no-headers | while read line; do
            pod_name=$(echo "$line" | awk '{print $1}')
            status=$(echo "$line" | awk '{print $3}')
            restarts=$(echo "$line" | awk '{print $4}')
            echo "  - $pod_name: $status (restarts: $restarts)"
        done
        
        # Verificar si hay pods en CrashLoopBackOff
        crashloop_pods=$(kubectl get pods -l app=oomkilled-test --no-headers | grep CrashLoopBackOff || true)
        if [ -n "$crashloop_pods" ]; then
            print_warning "🔄 Pods en CrashLoopBackOff detectados (probable OOMKilled):"
            echo "$crashloop_pods"
        fi
        
        echo ""
        sleep 5
        count=$((count + 1))
    done
    
    if [ $count -eq $max_attempts ]; then
        print_warning "⏰ Tiempo de espera agotado. Verificando estado final..."
    fi
}

# Ejecutar monitoreo
monitor_oomkilled

# Mostrar estado final
print_status "📋 Estado final de los pods:"
kubectl get pods -l app=oomkilled-test

print_status "📊 Eventos relacionados con OOMKilled:"
kubectl get events --field-selector reason=OOMKilling --sort-by='.lastTimestamp' 2>/dev/null | grep oomkilled-test || print_warning "No se encontraron eventos OOMKilled"

print_status "📝 Logs de un pod (si está disponible):"
pod_name=$(kubectl get pods -l app=oomkilled-test --no-headers | head -1 | awk '{print $1}')
if [ -n "$pod_name" ]; then
    kubectl logs "$pod_name" --tail=20 2>/dev/null || print_warning "No se pudieron obtener logs"
fi

print_success "✅ Test de escenario OOMKilled completado"
print_status "💡 Los pods deberían haber sido terminados por OOMKilled debido al límite de memoria de 50Mi" 