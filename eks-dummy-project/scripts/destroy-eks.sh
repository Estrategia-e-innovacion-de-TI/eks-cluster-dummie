#!/bin/bash

set -e

# Configura estos valores según tu entorno
CLUSTER_NAME="eks-dummy-test"
REGION="us-east-1"  # Cambia esto si tu cluster está en otra región

# 0. Verifica si el cluster EKS existe
if ! aws eks --region "$REGION" describe-cluster --name "$CLUSTER_NAME" >/dev/null 2>&1; then
  echo "❌ El cluster EKS '$CLUSTER_NAME' no existe en la región '$REGION'."
  echo "No hay nada que destruir. Saliendo."
  exit 0
fi

# 1. Actualiza el kubeconfig para el cluster EKS
aws eks --region "$REGION" update-kubeconfig --name "$CLUSTER_NAME"

# 2. Elimina todos los namespaces personalizados (excepto los de sistema)
for ns in $(kubectl get ns --no-headers | awk '{print $1}' | grep -vE 'kube-system|kube-public|kube-node-lease|default'); do
  echo "Eliminando namespace: $ns"
  kubectl delete ns $ns --wait
  echo "Namespace $ns eliminado."
done

# 3. (Opcional) Elimina recursos en el namespace default
kubectl delete all --all -n default || true
kubectl delete configmap --all -n default || true
kubectl delete secret --all -n default || true

# 4. Destruye la infraestructura con Terraform
cd "$(dirname "$0")/../terraform"
terraform destroy -auto-approve

# 5. (Opcional) Limpia archivos de estado
read -p "¿Deseas eliminar los archivos de estado de Terraform localmente? (s/n): " RESP
if [[ "$RESP" =~ ^[sS]$ ]]; then
    rm -f terraform.tfstate*
    echo "🧹 Archivos de estado eliminados."
fi

cd ..
echo "✅ Cluster EKS '$CLUSTER_NAME' y todos los recursos han sido destruidos correctamente." 