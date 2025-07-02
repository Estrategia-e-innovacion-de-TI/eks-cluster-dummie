#!/bin/bash

# Script para simular error de scheduling por límite de recursos
# El pod solicita más recursos de los disponibles en el nodo

set -e

NAMESPACE="resource-limit-error"
DEPLOYMENT="resource-limit-error"
CLUSTER_NAME="eks-dummy-test"
REGION="us-east-1"

# 0. Verifica si el cluster EKS existe y actualiza el kubeconfig
echo "🔄 Verificando si el cluster '$CLUSTER_NAME' existe en la región '$REGION'..."
if ! aws eks --region "$REGION" describe-cluster --name "$CLUSTER_NAME" >/dev/null 2>&1; then
  echo "🟡 El cluster EKS '$CLUSTER_NAME' no existe. Desplegando ahora con 'deploy.sh'..."
  
  # Navegar al directorio de scripts y ejecutar deploy.sh
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$SCRIPT_DIR/deploy.sh" ]; then
    "$SCRIPT_DIR/deploy.sh"
  else
    echo "❌ No se encontró el script 'deploy.sh'. No se puede crear el cluster."
    exit 1
  fi
  
  echo "✅ Cluster desplegado. Continuando con el escenario..."
else
  echo "✅ El cluster ya existe. Actualizando kubeconfig..."
  aws eks --region "$REGION" update-kubeconfig --name "$CLUSTER_NAME"
  echo "✅ Kubeconfig actualizado para el cluster '$CLUSTER_NAME'."
fi

# Crear namespace
echo "🚀 Creando namespace $NAMESPACE..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Aplicar manifiesto
echo "📄 Aplicando manifiesto con recursos excesivos..."
kubectl apply -n $NAMESPACE -f ../kubernetes/resource-limit-error.yaml

echo "⏳ Esperando 20 segundos para que el scheduler intente programar el pod..."
sleep 20

# Mostrar estado del pod
echo "📊 Estado del pod:"
kubectl get pods -n $NAMESPACE -o wide

echo ""
echo "🔍 Descripción del pod (motivo del Pending):"
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD_NAME -n $NAMESPACE | grep -A 10 'Events:'

echo ""
echo "🎯 RESUMEN:"
echo "El pod queda en estado Pending porque solicita más recursos de los disponibles en los nodos del cluster."
echo "Puedes ver el motivo exacto en la sección de Events (por ejemplo: 0/1 nodes are available: ... Insufficient cpu/memory)." 