#!/bin/bash
set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CLUSTER_NAME="eks-dummy-test"
REGION="us-west-2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${YELLOW} Iniciando limpieza del entorno EKS...${NC}"

# Eliminar aplicaciones
echo -e "${YELLOW} Eliminando aplicaciones...${NC}"
kubectl delete -f "$PROJECT_ROOT/kubernetes/sample-app.yaml" --ignore-not-found=true
kubectl delete -f "$PROJECT_ROOT/kubernetes/nginx-deployment.yaml" --ignore-not-found=true

# Esperar a que se eliminen los LoadBalancers
echo -e "${YELLOW} Esperando eliminación de LoadBalancers...${NC}"
sleep 60

# Cambiar al directorio de Terraform
cd "$PROJECT_ROOT/terraform"

# Destruir infraestructura
echo -e "${YELLOW} Destruyendo infraestructura...${NC}"
terraform destroy -var="cluster_name=$CLUSTER_NAME" -var="aws_region=$REGION" -auto-approve

# Limpiar archivos temporales
echo -e "${YELLOW} Limpiando archivos temporales...${NC}"
rm -f kubeconfig-$CLUSTER_NAME
rm -f terraform.tfstate*
rm -rf .terraform/

echo -e "${GREEN} Limpieza completada!${NC}"