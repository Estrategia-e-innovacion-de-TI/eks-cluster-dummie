#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CLUSTER_NAME="eks-dummy-test"

echo -e "${GREEN} Iniciando monitoreo del cluster...${NC}"

# Función para mostrar estadísticas
show_stats() {
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${YELLOW} $(date)${NC}"
    echo -e "${BLUE}===============================================${NC}"
    
    echo -e "${GREEN} Estado del cluster:${NC}"
    kubectl get nodes --no-headers | wc -l | xargs echo "  Nodos activos:"
    
    echo -e "${GREEN} Estado de pods:${NC}"
    kubectl get pods -A --no-headers | wc -l | xargs echo "  Total pods:"
    kubectl get pods -A --field-selector=status.phase=Running --no-headers | wc -l | xargs echo "  Pods running:"
    kubectl get pods -A --field-selector=status.phase=Pending --no-headers | wc -l | xargs echo "  Pods pending:"
    
    echo -e "${GREEN} Uso de recursos:${NC}"
    kubectl top nodes 2>/dev/null || echo "  Metrics server not available"
    
    echo -e "${GREEN} Logs recientes (últimas 5 líneas):${NC}"
    kubectl logs -l app=sample-logger --tail=5 2>/dev/null | head -5 || echo "  No logs available"
    
    echo ""
}

# Monitoreo continuo
if [ "$1" = "watch" ]; then
    echo -e "${YELLOW} Monitoreo continuo activado (Ctrl+C para salir)...${NC}"
    while true; do
        clear
        show_stats
        sleep 30
    done
else
    show_stats
fi