#!/bin/bash

# ========================================
# Script para limpiar el escenario OOMKilled
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
MANIFEST_FILE="$PROJECT_ROOT/kubernetes/oomkilled-test.yaml"

echo -e "${YELLOW}🧹 Limpiando escenario OOMKilled...${NC}"
echo ""

# Verificar si el archivo existe
if [ ! -f "$MANIFEST_FILE" ]; then
    echo -e "${RED}❌ Archivo de manifiesto no encontrado: $MANIFEST_FILE${NC}"
    exit 1
fi

# Mostrar recursos antes de limpiar
echo -e "${BLUE}📊 Recursos antes de la limpieza:${NC}"
echo "----------------------------------------"
kubectl get pods -l app=oomkilled-test 2>/dev/null || echo "No hay pods de oomkilled-test"
kubectl get pods -l app=oomkilled-aggressive 2>/dev/null || echo "No hay pods de oomkilled-aggressive"
kubectl get services -l app=oomkilled-test 2>/dev/null || echo "No hay servicios del test OOMKilled"
kubectl get configmaps -l app=oomkilled-test 2>/dev/null || echo "No hay configmaps del test OOMKilled"
echo ""

# Eliminar recursos usando el manifiesto
echo -e "${BLUE}🗑️  Eliminando recursos OOMKilled...${NC}"
kubectl delete -f "$MANIFEST_FILE" --ignore-not-found=true

# Esperar a que se eliminen los pods
echo -e "${YELLOW}⏳ Esperando que los pods se eliminen...${NC}"
sleep 15

# Verificar que se eliminaron
echo -e "${BLUE}✅ Verificando limpieza...${NC}"
echo "----------------------------------------"

# Verificar pods oomkilled-test
PODS_TEST_REMAINING=$(kubectl get pods -l app=oomkilled-test --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$PODS_TEST_REMAINING" -eq 0 ]; then
    echo -e "${GREEN}✅ Todos los pods de oomkilled-test eliminados${NC}"
else
    echo -e "${YELLOW}⚠️  Aún hay $PODS_TEST_REMAINING pods de oomkilled-test pendientes de eliminación${NC}"
    kubectl get pods -l app=oomkilled-test
fi

# Verificar pods oomkilled-aggressive
PODS_AGGRESSIVE_REMAINING=$(kubectl get pods -l app=oomkilled-aggressive --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$PODS_AGGRESSIVE_REMAINING" -eq 0 ]; then
    echo -e "${GREEN}✅ Todos los pods de oomkilled-aggressive eliminados${NC}"
else
    echo -e "${YELLOW}⚠️  Aún hay $PODS_AGGRESSIVE_REMAINING pods de oomkilled-aggressive pendientes de eliminación${NC}"
    kubectl get pods -l app=oomkilled-aggressive
fi

# Verificar servicios
SERVICES_REMAINING=$(kubectl get services -l app=oomkilled-test --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$SERVICES_REMAINING" -eq 0 ]; then
    echo -e "${GREEN}✅ Todos los servicios eliminados${NC}"
else
    echo -e "${YELLOW}⚠️  Aún hay $SERVICES_REMAINING servicios pendientes de eliminación${NC}"
fi

# Verificar configmaps
CONFIGMAPS_REMAINING=$(kubectl get configmaps -l app=oomkilled-test --no-headers 2>/dev/null | wc -l || echo "0")
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

# Limpiar eventos antiguos relacionados con OOMKilled
echo -e "\n${BLUE}🧽 Limpiando eventos OOMKilled antiguos...${NC}"
echo "Eventos OOMKilled recientes (se limpiarán automáticamente):"
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | grep -E "(OOMKilled|Killed|OutOfMemory)" | tail -5 || echo "No hay eventos OOMKilled recientes"

# Verificar uso de memoria del cluster
echo -e "\n${BLUE}📊 Uso de memoria del cluster después de la limpieza:${NC}"
echo "--------------------------------------------------------"
kubectl top nodes 2>/dev/null || echo "❌ kubectl top no disponible (instalar metrics-server)"

echo -e "\n${GREEN}✅ Limpieza OOMKilled completada${NC}"
echo ""
echo -e "${BLUE}📋 Comandos útiles para verificar:${NC}"
echo "kubectl get pods --all-namespaces"
echo "kubectl get services --all-namespaces"
echo "kubectl top nodes"
echo "kubectl top pods"
echo "kubectl get events --sort-by='.lastTimestamp' | grep -E '(OOMKilled|Killed)'"
echo ""
echo -e "${YELLOW}💡 Nota: Los eventos OOMKilled se mantienen en el historial de eventos${NC}"
echo "   pero se limpiarán automáticamente después de un tiempo." 