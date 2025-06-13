# EKS Dummy Test Project

Este proyecto crea un cluster EKS de prueba con logging en CloudWatch para realizar pruebas de conectividad, escalado, y operaciones básicas.

## Prerequisitos

- AWS CLI configurado
- Terraform >= 1.0
- kubectl
- Permisos AWS para crear recursos EKS, VPC, IAM

## Estructura del Proyecto
eks-dummy-project/
├── terraform/          # Configuración de infraestructura
├── kubernetes/         # Configuración de aplicaciones de prueba
├── scripts/            # Scripts de automatización
├── README.md
└── .gitignore

## Uso Rápido

1. **Clonar y entrar al directorio:**
```bash
git clone <repo>
cd eks-dummy-project
```

2. **Hacer scripts ejecutables:**
```
chmod +x scripts/*.sh
```

3. **Desplegar:**
```
./scripts/deploy.sh
```

4. **Testear:**
```
./scripts/test-eks.sh
```

5. **Monitorear:**
```
./scripts/monitoring.sh watch
```

6. **Limpiar:**
```
./scripts/cleanup.sh
```

## Recursos creados
- VPC con subnets públicas y privadas
- EKS Cluster con Node Group
- CloudWatch Log Groups
- Security Groups e IAM Roles
- Aplicaciones de prueba (logger y nginx)