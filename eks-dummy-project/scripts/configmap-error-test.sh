#!/bin/bash

# Script para simular error de ConfigMap en EKS
# Escenario: ConfigMap se modifica eliminando una clave crítica

set -e

NAMESPACE="configmap-test"
DEPLOYMENT="config-dependent-app"
CONFIGMAP="app-config"
CLUSTER_NAME="eks-dummy-test"
REGION="us-east-1"  

# 0. Verifica si el cluster EKS existe
if ! aws eks --region "$REGION" describe-cluster --name "$CLUSTER_NAME" >/dev/null 2>&1; then
  echo "❌ El cluster EKS '$CLUSTER_NAME' no existe en la región '$REGION'."
  echo "No se puede ejecutar el escenario de ConfigMap. Saliendo."
  exit 0
fi

# 1. Actualiza el kubeconfig para el cluster EKS
aws eks --region "$REGION" update-kubeconfig --name "$CLUSTER_NAME"

echo "🚀 Iniciando escenario de prueba: Error de ConfigMap"
echo "=================================================="

# Función para mostrar estado de los pods
show_pod_status() {
    echo "📊 Estado actual de los pods:"
    kubectl get pods -n $NAMESPACE -o wide
    echo ""
}

# Función para mostrar logs de un pod
show_pod_logs() {
    local pod_name=$1
    echo "📋 Logs del pod $pod_name:"
    kubectl logs $pod_name -n $NAMESPACE --tail=20 || echo "No se pudieron obtener logs"
    echo ""
}

# Función para mostrar eventos del namespace
show_events() {
    echo "📅 Eventos del namespace $NAMESPACE:"
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10
    echo ""
}

# Paso 1: Crear namespace y ConfigMap inicial
echo "1️⃣ Creando namespace y ConfigMap inicial..."
kubectl apply -f ../kubernetes/configmap-scenario.yaml

echo "⏳ Esperando que los pods estén listos..."
kubectl wait --for=condition=ready pod -l app=$DEPLOYMENT -n $NAMESPACE --timeout=120s

echo "✅ Configuración inicial desplegada exitosamente"
show_pod_status

# Paso 2: Verificar que la aplicación funciona correctamente
echo "2️⃣ Verificando funcionamiento normal..."
sleep 10
show_pod_logs $(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o jsonpath='{.items[0].metadata.name}')

# Paso 3: Simular el error - aplicar ConfigMap corrupto
echo "3️⃣ 🚨 SIMULANDO ERROR: Aplicando ConfigMap con clave faltante..."
kubectl apply -f ../kubernetes/configmap-broken.yaml

echo "⏳ Esperando que los pods detecten el cambio..."
sleep 15

# Paso 4: Observar el impacto del error
echo "4️⃣ Observando impacto del error..."
show_pod_status
show_events

echo "📋 Logs de pods fallando:"
for pod in $(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o jsonpath='{.items[*].metadata.name}'); do
    echo "--- Pod: $pod ---"
    show_pod_logs $pod
done

# Paso 5: Diagnóstico
echo "5️⃣ 🔍 DIAGNÓSTICO DEL PROBLEMA"
echo "=================================="

echo "📊 Estado detallado de los pods:"
kubectl describe pods -n $NAMESPACE -l app=$DEPLOYMENT

echo ""
echo "🔧 ConfigMap actual:"
kubectl get configmap $CONFIGMAP -n $NAMESPACE -o yaml

echo ""
echo "📈 Métricas de reinicio de pods:"
kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o jsonpath='{range .items[*]}{.metadata.name}{": "}{.status.containerStatuses[0].restartCount}{" reinicios\n"}{end}'

# Paso 6: Solución - restaurar ConfigMap correcto
echo ""
echo "6️⃣ 🔧 SOLUCIONANDO EL PROBLEMA: Restaurando ConfigMap correcto..."
kubectl apply -f ../kubernetes/configmap-scenario.yaml

echo "⏳ Esperando recuperación..."
sleep 20

echo "✅ Estado final después de la corrección:"
show_pod_status

echo ""
echo "🎯 RESUMEN DEL ESCENARIO:"
echo "========================="
echo "✅ Se creó un namespace con ConfigMap y deployment"
echo "✅ Se simuló un error eliminando la clave API_KEY del ConfigMap"
echo "✅ Los pods entraron en CrashLoopBackOff debido a la configuración faltante"
echo "✅ Se diagnosticó el problema mediante logs y eventos"
echo "✅ Se restauró la configuración correcta"
echo ""
echo "📚 LECCIONES APRENDIDAS:"
echo "- Los ConfigMaps son críticos para el funcionamiento de las aplicaciones"
echo "- Los pods fallan inmediatamente si faltan variables de entorno requeridas"
echo "- Los logs de Kubernetes son esenciales para diagnosticar problemas"
echo "- CloudWatch Logs capturaría estos errores en un entorno de producción" 