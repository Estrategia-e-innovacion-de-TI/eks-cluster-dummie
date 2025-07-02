#!/bin/bash

# Script para simular error de Readiness Probe en EKS
# Escenario: Readiness probe mal configurado - pod Running pero no Ready

set -e

NAMESPACE="readiness-probe-test"
DEPLOYMENT="readiness-probe-app"
SERVICE="readiness-probe-service"
CLUSTER_NAME="eks-dummy-test"
REGION="us-east-1"  # Cambia esto si tu cluster está en otra región

# 0. Verifica si el cluster EKS existe
if ! aws eks --region "$REGION" describe-cluster --name "$CLUSTER_NAME" >/dev/null 2>&1; then
  echo "❌ El cluster EKS '$CLUSTER_NAME' no existe en la región '$REGION'."
  echo "No se puede ejecutar el escenario de Readiness Probe. Saliendo."
  exit 0
fi

# 1. Actualiza el kubeconfig para el cluster EKS
aws eks --region "$REGION" update-kubeconfig --name "$CLUSTER_NAME"

echo "🚀 Iniciando escenario de prueba: Error de Readiness Probe"
echo "========================================================="

# Función para mostrar estado de los pods
show_pod_status() {
    echo "📊 Estado actual de los pods:"
    kubectl get pods -n $NAMESPACE -o wide
    echo ""
}

# Función para mostrar estado del servicio
show_service_status() {
    echo "🔗 Estado del servicio:"
    kubectl get svc -n $NAMESPACE
    echo ""
    echo "📋 Endpoints del servicio:"
    kubectl get endpoints -n $NAMESPACE
    echo ""
}

# Función para mostrar eventos del namespace
show_events() {
    echo "📅 Eventos del namespace $NAMESPACE:"
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10
    echo ""
}

# Función para mostrar logs de readiness probe
show_readiness_logs() {
    local pod_name=$1
    echo "🔍 Logs de readiness probe del pod $pod_name:"
    kubectl logs $pod_name -n $NAMESPACE --tail=10 || echo "No se pudieron obtener logs"
    echo ""
}

# Paso 1: Crear namespace y deployment con readiness probe mal configurado
echo "1️⃣ Creando namespace y deployment con readiness probe mal configurado..."
kubectl apply -f ../kubernetes/readiness-probe-scenario.yaml

echo "⏳ Esperando que los pods se inicien..."
sleep 30

echo "✅ Deployment desplegado con readiness probe mal configurado"
show_pod_status

# Paso 2: Observar el problema - pods Running pero no Ready
echo "2️⃣ 🔍 OBSERVANDO EL PROBLEMA: Pods Running pero no Ready..."
echo "Los pods deberían aparecer como Running pero con 0/1 en READY"
show_pod_status

echo "📋 Estado del servicio (no debería tener endpoints):"
show_service_status

# Paso 3: Analizar eventos y logs
echo "3️⃣ 📊 ANALIZANDO EVENTOS Y LOGS..."
show_events

echo "📋 Logs de readiness probe fallando:"
for pod in $(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o jsonpath='{.items[*].metadata.name}'); do
    echo "--- Pod: $pod ---"
    show_readiness_logs $pod
done

# Paso 4: Diagnóstico detallado
echo "4️⃣ 🔍 DIAGNÓSTICO DETALLADO"
echo "============================"

echo "📊 Descripción detallada de los pods:"
kubectl describe pods -n $NAMESPACE -l app=$DEPLOYMENT

echo ""
echo "🔧 Configuración actual del deployment:"
kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o yaml | grep -A 20 "readinessProbe:"

echo ""
echo "📈 Métricas de readiness probe:"
kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o jsonpath='{range .items[*]}{.metadata.name}{": Ready="}{.status.containerStatuses[0].ready}{" Restarts="}{.status.containerStatuses[0].restartCount}{"\n"}{end}'

# Paso 5: Simular acceso al servicio (debería fallar)
# echo ""
# echo "5️⃣ 🌐 SIMULANDO ACCESO AL SERVICIO..."
# echo "Intentando acceder al servicio (debería fallar porque no hay endpoints):"
# kubectl run test-access --image=busybox --rm -it --restart=Never -n $NAMESPACE -- wget -qO- http://$SERVICE.$NAMESPACE.svc.cluster.local || echo "❌ Acceso falló - no hay endpoints disponibles"

# Paso 6: Solución - aplicar configuración corregida
# echo ""
# echo "6️⃣ 🔧 SOLUCIONANDO EL PROBLEMA: Aplicando readiness probe corregido..."
# kubectl apply -f ../kubernetes/readiness-probe-fixed.yaml

# echo "⏳ Esperando que los pods se vuelvan Ready..."
# sleep 30

# echo "✅ Estado después de la corrección:"
# show_pod_status

# echo "📋 Estado del servicio después de la corrección:"
# show_service_status

# Paso 7: Verificar que el servicio funciona
# echo ""
# echo "7️⃣ ✅ VERIFICANDO QUE EL SERVICIO FUNCIONA..."
# echo "Intentando acceder al servicio (debería funcionar ahora):"
# kubectl run test-access-fixed --image=busybox --rm -it --restart=Never -n $NAMESPACE -- wget -qO- http://$SERVICE.$NAMESPACE.svc.cluster.local || echo "❌ Acceso aún falla"

echo ""
echo "🎯 RESUMEN DEL ESCENARIO:"
echo "========================="
echo "✅ Se creó un deployment con readiness probe mal configurado"
echo "✅ Los pods se mantuvieron Running pero no Ready (0/1)"
echo "✅ El servicio no tiene endpoints disponibles"
echo "✅ Se diagnosticó el problema mediante eventos y logs"
echo "⚠️  EL PROBLEMA PERMANECE ACTIVO - Revisa tu cuenta AWS para ver el estado"
echo ""
echo "📚 LECCIONES APRENDIDAS:"
echo "- Los readiness probes son críticos para la disponibilidad del servicio"
echo "- Un pod puede estar Running pero no Ready si falla el readiness probe"
echo "- Los servicios solo envían tráfico a pods Ready"
echo "- Los eventos de Kubernetes son esenciales para diagnosticar problemas de health checks"
echo "- CloudWatch puede monitorear métricas de readiness y liveness probes"
echo ""
echo "🔍 Para ver el estado en AWS:"
echo "   - Revisa CloudWatch Logs: /aws/eks/$CLUSTER_NAME/application/readiness-probe-test"
echo "   - Verifica métricas de EKS en CloudWatch"
echo "   - Revisa eventos del cluster en la consola de EKS" 