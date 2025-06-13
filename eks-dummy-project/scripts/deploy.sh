#!/bin/bash
set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
CLUSTER_NAME="eks-dummy-test"
REGION="us-west-2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${GREEN} Iniciando despliegue de EKS dummy...${NC}"

# Verificar prerequisitos
echo -e "${YELLOW} Verificando prerequisitos...${NC}"
if ! command -v terraform &> /dev/null; then
    echo -e "${RED} Terraform no está instalado${NC}"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo -e "${RED} AWS CLI no está instalado${NC}"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED} kubectl no está instalado${NC}"
    exit 1
fi

# Verificar credenciales AWS
echo -e "${YELLOW} Verificando credenciales AWS...${NC}"
aws sts get-caller-identity || { echo -e "${RED} Credenciales AWS no configuradas${NC}"; exit 1; }

# Cambiar al directorio de Terraform
cd "$PROJECT_ROOT/terraform"

# Desplegar infraestructura
echo -e "${YELLOW} Desplegando infraestructura con Terraform...${NC}"
terraform init
terraform plan -var="cluster_name=$CLUSTER_NAME" -var="aws_region=$REGION"
terraform apply -var="cluster_name=$CLUSTER_NAME" -var="aws_region=$REGION" -auto-approve

# Configurar kubectl
echo -e "${YELLOW} Configurando kubectl...${NC}"
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Verificar conexión al cluster
echo -e "${YELLOW} Verificando conexión al cluster...${NC}"
kubectl get nodes

# Desplegar aplicaciones de prueba
echo -e "${YELLOW} Desplegando aplicaciones de prueba...${NC}"
kubectl apply -f "$PROJECT_ROOT/kubernetes/sample-app.yaml"
kubectl apply -f "$PROJECT_ROOT/kubernetes/nginx-deployment.yaml"

# Esperar a que los pods estén listos
echo -e "${YELLOW} Esperando a que los pods estén listos...${NC}"
kubectl wait --for=condition=ready pod -l app=sample-logger --timeout=300s || echo "Sample logger pods may still be starting..."
kubectl wait --for=condition=ready pod -l app=nginx-test --timeout=300s || echo "Nginx pods may still be starting..."

echo -e "${GREEN} ¡Despliegue completado exitosamente!${NC}"
echo ""
echo -e "${GREEN} Información del cluster:${NC}"
echo "Nombre: $CLUSTER_NAME"
echo "Región: $REGION"
echo "Endpoint: $(terraform output -raw cluster_endpoint)"
echo ""
echo -e "${GREEN}🔍 Comandos útiles:${NC}"
echo "kubectl get pods"
echo "kubectl get services"
echo "kubectl logs -l app=sample-logger"
echo "aws logs describe-log-groups --log-group-name-prefix '/aws/eks'"