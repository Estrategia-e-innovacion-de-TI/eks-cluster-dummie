#!/bin/bash

# Script de limpieza para el escenario de prueba de Readiness Probe

NAMESPACE="readiness-probe-test"

echo "🧹 Limpiando escenario de prueba de Readiness Probe..."
echo "====================================================="

echo "🗑️ Eliminando namespace $NAMESPACE..."
kubectl delete namespace $NAMESPACE --ignore-not-found=true

echo "⏳ Esperando eliminación completa..."
kubectl wait --for=delete namespace/$NAMESPACE --timeout=60s || echo "Namespace ya eliminado"

echo "✅ Limpieza completada"
echo ""
echo "📋 Recursos eliminados:"
echo "- Namespace: $NAMESPACE"
echo "- Deployment: readiness-probe-app"
echo "- Service: readiness-probe-service"
echo "- Todos los pods asociados" 