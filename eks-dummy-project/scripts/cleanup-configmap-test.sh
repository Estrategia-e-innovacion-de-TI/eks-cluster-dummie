#!/bin/bash

# Script de limpieza para el escenario de prueba de ConfigMap

NAMESPACE="configmap-test"

echo "🧹 Limpiando escenario de prueba de ConfigMap..."
echo "=============================================="

echo "🗑️ Eliminando namespace $NAMESPACE..."
kubectl delete namespace $NAMESPACE --ignore-not-found=true

echo "⏳ Esperando eliminación completa..."
kubectl wait --for=delete namespace/$NAMESPACE --timeout=60s || echo "Namespace ya eliminado"

echo "✅ Limpieza completada"
echo ""
echo "📋 Recursos eliminados:"
echo "- Namespace: $NAMESPACE"
echo "- ConfigMap: app-config"
echo "- Deployment: config-dependent-app"
echo "- Todos los pods asociados" 