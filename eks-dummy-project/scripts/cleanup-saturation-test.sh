#!/bin/bash

# ========================================
# Script para limpiar el escenario de saturación de recursos
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
NC='\033[0m' # No Color

# Variables
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST_FILE="$PROJECT_ROOT/kubernetes/resource-saturation-test.yaml"

echo -e "${YELLOW}🧹 Limpiando escenario de saturación de recursos...${NC}"
echo ""

# Verificar si el archivo existe
if [ ! -f "$MANIFEST_FILE" ]; then
    echo -e "${RED}❌ Archivo de manifiesto no encontrado: $MANIFEST_FILE${NC}"
    exit 1
fi

# Mostrar recursos antes de limpiar
echo -e "${BLUE}📊 Recursos antes de la limpieza:${NC}"
echo "----------------------------------------"
kubectl get pods -l app=nginx-saturation-test 2>/dev/null || echo "No hay pods del test de saturación"
kubectl get services -l app=nginx-saturation-test 2>/dev/null || echo "No hay servicios del test de saturación"
kubectl get configmaps -l app=nginx-saturation-test 2>/dev/null || echo "No hay configmaps del test de saturación"
echo ""

# Eliminar recursos usando el manifiesto
echo -e "${BLUE}🗑️  Eliminando recursos...${NC}"
kubectl delete -f "$MANIFEST_FILE" --ignore-not-found=true

# Esperar a que se eliminen los pods
echo -e "${YELLOW}⏳ Esperando que los pods se eliminen...${NC}"
sleep 10

# Verificar que se eliminaron
echo -e "${BLUE}✅ Verificando limpieza...${NC}"
echo "----------------------------------------"

# Verificar pods
PODS_REMAINING=$(kubectl get pods -l app=nginx-saturation-test --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$PODS_REMAINING" -eq 0 ]; then
    echo -e "${GREEN}✅ Todos los pods eliminados${NC}"
else
    echo -e "${YELLOW}⚠️  Aún hay $PODS_REMAINING pods pendientes de eliminación${NC}"
    kubectl get pods -l app=nginx-saturation-test
fi

# Verificar servicios
SERVICES_REMAINING=$(kubectl get services -l app=nginx-saturation-test --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$SERVICES_REMAINING" -eq 0 ]; then
    echo -e "${GREEN}✅ Todos los servicios eliminados${NC}"
else
    echo -e "${YELLOW}⚠️  Aún hay $SERVICES_REMAINING servicios pendientes de eliminación${NC}"
fi

# Verificar configmaps
CONFIGMAPS_REMAINING=$(kubectl get configmaps -l app=nginx-saturation-test --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$CONFIGMAPS_REMAINING" -eq 0 ]; then
    echo -e "${GREEN}✅ Todos los configmaps eliminados${NC}"
else
    echo -e "${YELLOW}⚠️  Aún hay $CONFIGMAPS_REMAINING configmaps pendientes de eliminación${NC}"
fi

# Mostrar estado final del cluster
echo -e "\n${BLUE}📊 Estado final del cluster:${NC}"
echo "----------------------------------------"
kubectl get nodes
echo ""
kubectl get pods --all-namespaces | grep -v "kube-system" || echo "No hay pods en namespaces de usuario"

# Limpiar eventos antiguos (opcional)
echo -e "\n${BLUE}🧽 Limpiando eventos antiguos...${NC}"
echo "Esto puede tomar un momento..."
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | grep -E "(nginx-saturation-test|Scheduled|FailedScheduling)" | tail -5 || echo "No hay eventos relacionados con el test"

echo -e "\n${GREEN}✅ Limpieza completada${NC}"
echo ""
echo -e "${BLUE}📋 Comandos útiles para verificar:${NC}"
echo "kubectl get pods --all-namespaces"
echo "kubectl get services --all-namespaces"
echo "kubectl top nodes"
echo "kubectl get events --sort-by='.lastTimestamp'" 