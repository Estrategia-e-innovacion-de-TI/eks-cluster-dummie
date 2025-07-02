# EKS Dummy Test Project - Guía Completa de Escenarios

Este proyecto crea un cluster EKS de prueba con logging en CloudWatch para realizar pruebas de conectividad, escalado, y operaciones básicas. Incluye múltiples escenarios de troubleshooting para aprender a diagnosticar y resolver problemas comunes en Kubernetes.

## 📋 Tabla de Contenidos

- [EKS Dummy Test Project - Guía Completa de Escenarios](#eks-dummy-test-project---guía-completa-de-escenarios)
  - [📋 Tabla de Contenidos](#-tabla-de-contenidos)
  - [Prerequisitos](#prerequisitos)
  - [Configuración de Variables de Entorno](#configuración-de-variables-de-entorno)
    - [1. **Configurar Variables de Entorno:**](#1-configurar-variables-de-entorno)
    - [2. **Variables Principales a Configurar:**](#2-variables-principales-a-configurar)
    - [3. **Validar Configuración:**](#3-validar-configuración)
    - [4. **Beneficios de usar .env:**](#4-beneficios-de-usar-env)
    - [5. **Variables Disponibles:**](#5-variables-disponibles)
  - [Estructura del Proyecto](#estructura-del-proyecto)
  - [Uso Rápido](#uso-rápido)
    - [1. **Clonar y entrar al directorio:**](#1-clonar-y-entrar-al-directorio)
    - [2. **Hacer scripts ejecutables:**](#2-hacer-scripts-ejecutables)
    - [3. **Desplegar cluster EKS:**](#3-desplegar-cluster-eks)
    - [4. **Ejecutar pruebas básicas:**](#4-ejecutar-pruebas-básicas)
    - [5. **Monitorear:**](#5-monitorear)
    - [6. **Limpiar recursos:**](#6-limpiar-recursos)
  - [Escenarios de Prueba](#escenarios-de-prueba)
    - [🔧 Escenario 1: Error de ConfigMap](#-escenario-1-error-de-configmap)
    - [🔍 Escenario 2: Error de Readiness Probe](#-escenario-2-error-de-readiness-probe)
    - [⚡ Escenario 3: Error de Límites de Recursos](#-escenario-3-error-de-límites-de-recursos)
    - [🔥 Escenario 4: Saturación de Recursos en Operación](#-escenario-4-saturación-de-recursos-en-operación)
    - [💥 Escenario 5: OOMKilled (Out of Memory)](#-escenario-5-oomkilled-out-of-memory)
  - [Configuración MCP Server](#configuración-mcp-server)
    - [Instalación Rápida:](#instalación-rápida)
    - [Configuración Manual:](#configuración-manual)
    - [Uso del MCP Server:](#uso-del-mcp-server)
  - [Monitoreo y Alertas](#monitoreo-y-alertas)
    - [Métricas Clave a Monitorear:](#métricas-clave-a-monitorear)
    - [CloudWatch Logs Queries:](#cloudwatch-logs-queries)
  - [Herramientas de Diagnóstico](#herramientas-de-diagnóstico)
    - [Kubernetes Nativas:](#kubernetes-nativas)
    - [CloudWatch:](#cloudwatch)
    - [Herramientas Adicionales:](#herramientas-adicionales)
  - [Limpieza](#limpieza)
    - [Limpieza por Escenario:](#limpieza-por-escenario)
    - [Destruir Cluster EKS:](#destruir-cluster-eks)
  - [📚 Lecciones Aprendidas](#-lecciones-aprendidas)
    - [Mejores Prácticas:](#mejores-prácticas)
    - [Prevención de Errores:](#prevención-de-errores)
  - [📝 Notas Importantes](#-notas-importantes)
  - [Recursos Creados](#recursos-creados)

## Prerequisitos

- AWS CLI configurado con credenciales válidas
- Terraform >= 1.0
- kubectl
- Permisos AWS para crear recursos EKS, VPC, IAM
- Docker y containerd (para escenarios locales)

## Configuración de Variables de Entorno

El proyecto utiliza un archivo `.env` para gestionar todas las variables de configuración de manera segura y flexible.

### 1. **Configurar Variables de Entorno:**

```bash
# Copiar el archivo de ejemplo
cp env.example .env

# Editar con tus valores
nano .env
```

### 2. **Variables Principales a Configurar:**

```bash
# AWS Configuration (Requeridas)
AWS_PROFILE=default
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=tu_access_key_aqui
AWS_SECRET_ACCESS_KEY=tu_secret_key_aqui
AWS_SESSION_TOKEN=tu_session_token_aqui

# EKS Cluster Configuration
CLUSTER_NAME=eks-dummy-test
CLUSTER_REGION=us-east-1

# Scripts Configuration (Opcionales)
DEBUG_MODE=false
DRY_RUN=false
TIMEOUT_SECONDS=300
```

### 3. **Validar Configuración:**

```bash
# Verificar que las variables se cargan correctamente
./scripts/load-env.sh
```

### 4. **Beneficios de usar .env:**

- ✅ **Seguridad:** Credenciales no hardcodeadas en scripts
- ✅ **Flexibilidad:** Fácil cambio entre entornos
- ✅ **Colaboración:** Cada desarrollador tiene su configuración
- ✅ **CI/CD:** Integración fácil con pipelines
- ✅ **Debugging:** Modo debug y dry-run disponibles

### 5. **Variables Disponibles:**

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `AWS_PROFILE` | Perfil de AWS CLI | `default` |
| `AWS_REGION` | Región de AWS | `us-east-1` |
| `CLUSTER_NAME` | Nombre del cluster EKS | `eks-dummy-test` |
| `DEBUG_MODE` | Habilitar logs de debug | `false` |
| `DRY_RUN` | Ejecutar sin cambios reales | `false` |
| `TIMEOUT_SECONDS` | Timeout para operaciones | `300` |

## Estructura del Proyecto

```
eks-dummy-project/
├── terraform/                    # Configuración de infraestructura
│   ├── main.tf                   # Recursos principales
│   ├── variables.tf              # Variables de configuración
│   ├── outputs.tf                # Salidas de Terraform
│   ├── versions.tf               # Versiones de providers
│   └── terraform.tfstate         # Estado de Terraform
├── kubernetes/                   # Configuración de aplicaciones
│   ├── configmap-scenario.yaml   # ConfigMap correcto
│   ├── configmap-broken.yaml     # ConfigMap con error
│   ├── readiness-probe-scenario.yaml  # Readiness probe con error
│   ├── resource-limit-error.yaml      # Pod con recursos excesivos
│   ├── resource-saturation-test.yaml  # Saturación de recursos
│   ├── oomkilled-scenario.yaml        # OOMKilled scenario
│   ├── nginx-deployment.yaml          # Aplicación nginx
│   └── sample-app.yaml               # Aplicación de muestra
├── scripts/                      # Scripts de automatización
│   ├── load-env.sh               # Carga de variables de entorno
│   ├── deploy.sh                 # Despliegue completo
│   ├── test-eks.sh               # Pruebas básicas
│   ├── configmap-error-test.sh   # Escenario ConfigMap
│   ├── readiness-probe-test.sh   # Escenario Readiness Probe
│   ├── resource-limit-error-test.sh  # Escenario Recursos
│   ├── resource-saturation-test.sh   # Escenario Saturación
│   ├── oomkilled-scenario-test.sh    # Escenario OOMKilled
│   ├── cleanup-configmap-test.sh     # Limpieza ConfigMap
│   ├── cleanup-readiness-probe.sh    # Limpieza Readiness Probe
│   ├── cleanup-saturation-test.sh    # Limpieza Saturación
│   ├── cleanup-oomkilled-test.sh     # Limpieza OOMKilled
│   ├── cleanup.sh                # Limpieza general
│   ├── destroy-eks.sh            # Destruir cluster
│   ├── monitoring.sh             # Monitoreo
│   ├── monitor-cloudwatch.sh     # Monitoreo CloudWatch
│   └── install-aws-mcp.sh        # Instalación MCP Server
├── README.md                     # Esta guía
└── env.example                   # Variables de entorno de ejemplo
```

## Uso Rápido

### 1. **Clonar y entrar al directorio:**
```bash
git clone <repo>
cd eks-dummy-project
```

### 2. **Hacer scripts ejecutables:**
```bash
chmod +x scripts/*.sh
```

### 3. **Desplegar cluster EKS:**
```bash
./scripts/deploy.sh
```

### 4. **Ejecutar pruebas básicas:**
```bash
./scripts/test-eks.sh
```

### 5. **Monitorear:**
```bash
./scripts/monitoring.sh watch
```

### 6. **Limpiar recursos:**
```bash
./scripts/cleanup.sh
```

## Escenarios de Prueba

### 🔧 Escenario 1: Error de ConfigMap

**Descripción:** Simula un error donde un ConfigMap se modifica eliminando una clave crítica, causando que los pods fallen con `CrashLoopBackOff`.

**Objetivos de Aprendizaje:**
- Entender cómo los ConfigMaps afectan el funcionamiento de las aplicaciones
- Aprender a diagnosticar problemas de configuración en Kubernetes
- Practicar el uso de logs y eventos para troubleshooting
- Simular monitoreo con CloudWatch Logs

**Componentes:**
- **Namespace:** `configmap-test`
- **ConfigMap:** `app-config` (con/sin API_KEY)
- **Deployment:** `config-dependent-app` (2 réplicas)
- **Imagen:** `busybox:1.35`

**Ejecutar escenario:**
```bash
# Ejecutar prueba completa
./scripts/configmap-error-test.sh

# Monitorear con CloudWatch (simulado)
./scripts/monitor-cloudwatch.sh

# Limpiar recursos
./scripts/cleanup-configmap-test.sh
```

**Diagnóstico:**
```bash
# Verificar estado de pods
kubectl get pods -n configmap-test

# Ver logs de pods fallando
kubectl logs <pod-name> -n configmap-test

# Ver eventos del namespace
kubectl get events -n configmap-test --sort-by='.lastTimestamp'

# Verificar ConfigMap actual
kubectl get configmap app-config -n configmap-test -o yaml
```

**Síntomas esperados:**
- Pods en estado `CrashLoopBackOff`
- Logs: `ERROR: API_KEY is not set!`
- Aumento en la tasa de reinicio de pods

---

### 🔍 Escenario 2: Error de Readiness Probe

**Descripción:** Simula un error donde un readiness probe está mal configurado, causando que los pods se mantengan en estado "Running" pero nunca se vuelvan "Ready".

**Objetivos de Aprendizaje:**
- Entender la diferencia entre **Running** y **Ready** en Kubernetes
- Aprender cómo funcionan los readiness probes y su importancia
- Diagnosticar problemas de health checks en Kubernetes
- Entender cómo los servicios seleccionan endpoints

**Componentes:**
- **Namespace:** `readiness-probe-test`
- **Deployment:** `readiness-probe-app` (nginx:1.25)
- **Service:** `readiness-probe-service`
- **Problema:** Readiness probe en puerto incorrecto (8080 vs 80)

**Ejecutar escenario:**
```bash
# Ejecutar prueba completa
./scripts/readiness-probe-test.sh

# Limpiar recursos
./scripts/cleanup-readiness-probe.sh
```

**Diagnóstico:**
```bash
# Verificar estado de pods
kubectl get pods -n readiness-probe-test

# Ver endpoints del servicio
kubectl get endpoints -n readiness-probe-test

# Ver eventos del namespace
kubectl get events -n readiness-probe-test --sort-by='.lastTimestamp'

# Describir pods para ver detalles de readiness probe
kubectl describe pods -n readiness-probe-test -l app=readiness-probe-app
```

**Síntomas esperados:**
- Pods en estado `Running` pero con `0/1` en READY
- Servicio sin endpoints disponibles
- Eventos de readiness probe fallando

---

### ⚡ Escenario 3: Error de Límites de Recursos

**Descripción:** Simula un error de scheduling donde un pod solicita más recursos de los disponibles en los nodos del cluster.

**Objetivos de Aprendizaje:**
- Entender cómo el scheduler de Kubernetes asigna recursos
- Aprender a diagnosticar problemas de scheduling
- Practicar la gestión de recursos en Kubernetes
- Entender los límites de capacidad del cluster

**Componentes:**
- **Namespace:** `resource-limit-error`
- **Deployment:** `resource-limit-error`
- **Problema:** Pod solicita recursos excesivos (CPU/Memoria)

**Ejecutar escenario:**
```bash
# Ejecutar prueba completa
./scripts/resource-limit-error-test.sh
```

**Diagnóstico:**
```bash
# Verificar estado del pod
kubectl get pods -n resource-limit-error -o wide

# Ver descripción del pod (motivo del Pending)
kubectl describe pod -n resource-limit-error -l app=resource-limit-error

# Ver eventos del namespace
kubectl get events -n resource-limit-error --sort-by='.lastTimestamp'
```

**Síntomas esperados:**
- Pod en estado `Pending`
- Eventos: `0/1 nodes are available: 1 Insufficient cpu, 1 Insufficient memory`

---

### 🔥 Escenario 4: Saturación de Recursos en Operación

**Descripción:** Simula un escenario real donde un cluster EKS que funciona correctamente se satura gradualmente debido a una aplicación mal configurada que consume recursos progresivamente.

**Objetivos de Aprendizaje:**
- Observar el comportamiento del cluster bajo carga real
- Diagnosticar problemas de saturación de recursos en operación
- Entender cómo Kubernetes maneja la escasez de recursos
- Practicar monitoreo de recursos en tiempo real

**Componentes:**
- **Deployment:** `nginx-saturation-test` (5 réplicas)
- **Contenedores:** nginx + resource-hog
- **Problemas:** Readiness probe mal configurado + consumo progresivo de recursos

**Ejecutar escenario:**
```bash
# Ejecutar prueba completa con monitoreo
./scripts/resource-saturation-test.sh

# Limpiar recursos
./scripts/cleanup-saturation-test.sh
```

**Diagnóstico:**
```bash
# Ver estado de pods
kubectl get pods -l app=nginx-saturation-test

# Ver uso de recursos
kubectl top nodes
kubectl top pods -l app=nginx-saturation-test

# Ver eventos de scheduling
kubectl get events --sort-by='.lastTimestamp' | grep -E "(Scheduled|FailedScheduling|Insufficient)"

# Ver logs del resource-hog
kubectl logs <pod-name> -c resource-hog
```

**Síntomas esperados:**
- Pods en estado `Running` pero no `Ready` (readiness probe fallando)
- Posibles pods en `Pending` por recursos insuficientes
- Consumo progresivo de CPU y memoria
- Eventos de scheduling con `Insufficient cpu/memory`
- Degradación gradual del rendimiento del cluster

**Características del escenario:**
- **Readiness probe mal configurado:** `/noexiste` siempre falla
- **Resource-hog:** Consume CPU y memoria progresivamente
- **Solicitudes altas:** 800m CPU, 512Mi memoria por pod
- **Múltiples réplicas:** 5 pods para saturar el cluster
- **Monitoreo en tiempo real:** Opción de monitoreo continuo

---

### 💥 Escenario 5: OOMKilled (Out of Memory)

**Descripción:** Simula un escenario donde un pod consume más memoria de la asignada, causando que Kubernetes termine el contenedor con `OOMKilled`.

**Objetivos de Aprendizaje:**
- Entender cómo Kubernetes maneja el límite de memoria
- Aprender a diagnosticar problemas de memoria en contenedores
- Practicar el monitoreo de uso de recursos
- Entender el comportamiento de OOMKilled

**Componentes:**
- **Namespace:** `oomkilled-test`
- **Deployment:** `memory-hog-app` (1 réplica)
- **Problema:** Contenedor que consume memoria progresivamente hasta exceder el límite

**Ejecutar escenario:**
```bash
# Ejecutar prueba completa
./scripts/oomkilled-scenario-test.sh

# Limpiar recursos
./scripts/cleanup-oomkilled-test.sh
```

**Diagnóstico:**
```bash
# Ver estado de pods
kubectl get pods -n oomkilled-test

# Ver eventos del namespace
kubectl get events -n oomkilled-test --sort-by='.lastTimestamp'

# Ver logs del pod
kubectl logs <pod-name> -n oomkilled-test

# Ver uso de recursos
kubectl top pods -n oomkilled-test
```

**Síntomas esperados:**
- Pod en estado `CrashLoopBackOff` después de OOMKilled
- Eventos: `Killed` con razón `OOMKilled`
- Reinicio automático del pod
- Logs que muestran consumo progresivo de memoria

**Características del escenario:**
- **Límite de memoria:** 128Mi
- **Consumo progresivo:** Aumenta 10MB cada 2 segundos
- **Reinicio automático:** Kubernetes reinicia el pod automáticamente
- **Monitoreo:** Opción de monitoreo en tiempo real

---

## Configuración MCP Server

El proyecto incluye configuración para el servidor MCP (Model Context Protocol) de AWS Labs, que permite interactuar con el cluster EKS directamente desde Cursor.

### Instalación Rápida:
```bash
# Instalar servidor MCP
./scripts/install-aws-mcp.sh

# Reiniciar Cursor
```

### Configuración Manual:
El archivo `~/.cursor/mcp.json` debe contener:
```json
{
  "mcpServers": {
    "awslabs.eks-mcp-server": {
      "command": "/home/USERNAME/.local/bin/uvx",
      "args": [
        "awslabs.eks-mcp-server@latest",
        "--allow-write",
        "--allow-sensitive-data-access"
      ],
      "env": {
        "AWS_PROFILE": "default",
        "AWS_REGION": "us-east-1",
        "AWS_SESSION_TOKEN": "TU_SESSION_TOKEN"
      }
    }
  }
}
```

### Uso del MCP Server:
Una vez configurado, puedes usar comandos como:
- "Muestra los pods en el namespace configmap-test"
- "Describe el servicio nginx"
- "Obtén los logs del pod app-config-xxxx"

## Monitoreo y Alertas

### Métricas Clave a Monitorear:

**Para ConfigMap Errors:**
- Tasa de reinicio de pods: > 5/minuto = alerta
- Error rate: > 50% = alerta crítica
- Estado de pods: CrashLoopBackOff = alerta inmediata

**Para Readiness Probe Errors:**
- Pods no Ready: > 0 = alerta
- Readiness probe failures: > 5/minuto = alerta
- Endpoints disponibles: 0 = alerta crítica

**Para Resource Limit Errors:**
- Pods en Pending: > 0 = alerta
- CPU/Memoria utilizada: > 80% = alerta
- Eventos de scheduling fallidos: > 10/minuto = alerta

**Para OOMKilled Errors:**
- Pods OOMKilled: > 0 = alerta inmediata
- Reinicios de pods: > 5/minuto = alerta
- Uso de memoria: > 90% = alerta crítica

### CloudWatch Logs Queries:

```sql
-- ConfigMap Errors
fields @timestamp, @message
| filter @message like /ERROR.*not set/
| sort @timestamp desc

-- Readiness Probe Failures
fields @timestamp, @message
| filter @message like /Readiness probe failed/
| sort @timestamp desc

-- Scheduling Errors
fields @timestamp, @message
| filter @message like /Insufficient.*cpu|memory/
| sort @timestamp desc

-- OOMKilled Errors
fields @timestamp, @message
| filter @message like /OOMKilled|Killed/
| sort @timestamp desc
```

## Herramientas de Diagnóstico

### Kubernetes Nativas:
- `kubectl logs`: Ver logs de pods
- `kubectl describe`: Información detallada de recursos
- `kubectl get events`: Eventos del cluster
- `kubectl exec`: Ejecutar comandos en pods
- `kubectl get endpoints`: Ver endpoints de servicios

### CloudWatch:
- **Log Insights**: Consultas avanzadas de logs
- **Metrics**: Métricas de rendimiento
- **Alarms**: Alertas automáticas
- **Dashboards**: Visualización de métricas

### Herramientas Adicionales:
- **k9s**: Interface TUI para Kubernetes
- **Lens**: IDE para Kubernetes
- **Prometheus + Grafana**: Monitoreo avanzado

## Limpieza

### Limpieza por Escenario:
```bash
# Limpiar ConfigMap test
./scripts/cleanup-configmap-test.sh

# Limpiar Readiness Probe test
./scripts/cleanup-readiness-probe.sh

# Limpiar Saturación de Recursos test
./scripts/cleanup-saturation-test.sh

# Limpiar OOMKilled test
./scripts/cleanup-oomkilled-test.sh

# Limpieza general
./scripts/cleanup.sh
```

### Destruir Cluster EKS:
```bash
./scripts/destroy-eks.sh
```

## 📚 Lecciones Aprendidas

### Mejores Prácticas:
1. **Validación de Configuración**: Siempre validar ConfigMaps antes de aplicarlos
2. **Monitoreo Proactivo**: Configurar alertas para cambios críticos
3. **Testing**: Probar cambios en entornos de desarrollo
4. **Documentation**: Documentar todas las configuraciones requeridas
5. **Rollback Strategy**: Mantener versiones anteriores de configuraciones

### Prevención de Errores:
- Implementar validación de esquemas para ConfigMaps
- Usar herramientas como Helm para gestionar configuración
- Implementar GitOps para cambios de configuración
- Configurar revisiones obligatorias para cambios críticos
- Monitorear continuamente la salud del cluster

## 📝 Notas Importantes

- Este proyecto es educativo y simula errores reales
- En producción, siempre use namespaces separados para pruebas
- Los logs mostrados son simulados para demostración
- CloudWatch requiere configuración adicional en EKS real
- Siempre tenga un plan de rollback para cambios críticos
- Las credenciales de AWS deben estar actualizadas para que funcione el MCP Server

## Recursos Creados

- VPC con subnets públicas y privadas
- EKS Cluster con Node Group
- CloudWatch Log Groups
- Security Groups e IAM Roles
- Aplicaciones de prueba (logger y nginx)
- Namespaces de prueba para cada escenario