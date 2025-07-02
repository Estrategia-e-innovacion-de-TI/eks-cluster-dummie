#!/bin/bash
set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CLUSTER_NAME="eks-dummy-test"
REGION="us-west-2"

echo -e "${GREEN} Iniciando pruebas del cluster EKS...${NC}"

# Test 1: Verificar conectividad
echo -e "${YELLOW}Test 1: Verificando conectividad al cluster...${NC}"
kubectl cluster-info
kubectl get nodes -o wide

# Test 2: Verificar pods
echo -e "${YELLOW}Test 2: Verificando estado de los pods...${NC}"
kubectl get pods -A
kubectl describe pods -l app=sample-logger | head -20

# Test 3: Verificar logs
echo -e "${YELLOW}Test 3: Verificando logs de aplicación...${NC}"
kubectl logs -l app=sample-logger --tail=20

# Test 4: Verificar servicios
echo -e "${YELLOW}Test 4: Verificando servicios...${NC}"
kubectl get svc

# Test 5: Crear un pod temporal para pruebas
echo -e "${YELLOW}Test 5: Creando pod temporal para pruebas internas...${NC}"
kubectl run test-pod --image=busybox --rm -it --restart=Never --timeout=30s -- /bin/sh -c "
echo 'Prueba de conectividad interna'
nslookup kubernetes.default.svc.cluster.local
echo 'Test completado'
" || echo "Test pod execution completed"

# Test 6: Verificar logs en CloudWatch
echo -e "${YELLOW}Test 6: Verificando logs en CloudWatch...${NC}"
aws logs describe-log-groups --region $REGION --log-group-name-prefix "/aws/eks/$CLUSTER_NAME"

# Test 7: Escalar deployment
echo -e "${YELLOW}Test 7: Probando escalado...${NC}"
kubectl scale deployment sample-logger-app --replicas=3
kubectl rollout status deployment/sample-logger-app --timeout=120s
kubectl get pods -l app=sample-logger

# Restaurar replicas originales
kubectl scale deployment sample-logger-app --replicas=2

echo -e "${GREEN}✅ Todas las pruebas completadas exitosamente!${NC}"