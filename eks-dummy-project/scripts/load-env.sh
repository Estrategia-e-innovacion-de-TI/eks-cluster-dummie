#!/bin/bash

# ========================================
# Script para cargar variables de entorno
# ========================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para cargar variables de entorno
load_env() {
    local env_file="${1:-.env}"
    
    # Si no se especifica ruta completa, buscar en la raíz del proyecto
    if [[ "$env_file" == ".env" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
        env_file="$PROJECT_ROOT/.env"
    fi
    
    if [ ! -f "$env_file" ]; then
        echo -e "${YELLOW}⚠️  Archivo $env_file no encontrado.${NC}"
        echo -e "${BLUE}💡 Crea el archivo copiando: cp env.example .env${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📋 Cargando variables de entorno desde $env_file...${NC}"
    
    # Cargar variables de entorno
    while IFS= read -r line; do
        # Ignorar comentarios y líneas vacías
        if [[ $line =~ ^[[:space:]]*# ]] || [[ -z $line ]]; then
            continue
        fi
        
        # Exportar variable si no está vacía
        if [[ $line =~ ^[A-Z_][A-Z0-9_]*= ]]; then
            export "$line"
        fi
    done < "$env_file"
    
    echo -e "${GREEN}✅ Variables de entorno cargadas${NC}"
}

# Función para validar variables requeridas
validate_required_vars() {
    local required_vars=("$@")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo -e "${RED}❌ Variables requeridas faltantes:${NC}"
        printf '%s\n' "${missing_vars[@]}"
        echo -e "${BLUE}💡 Asegúrate de configurar estas variables en tu archivo .env${NC}"
        return 1
    fi
    
    return 0
}

# Función para mostrar configuración actual
show_config() {
    echo -e "${BLUE}🔧 Configuración actual:${NC}"
    echo "  AWS_PROFILE: ${AWS_PROFILE:-'no configurado'}"
    echo "  AWS_REGION: ${AWS_REGION:-'no configurado'}"
    echo "  CLUSTER_NAME: ${CLUSTER_NAME:-'no configurado'}"
    echo "  CLUSTER_REGION: ${CLUSTER_REGION:-'no configurado'}"
    echo "  DEBUG_MODE: ${DEBUG_MODE:-'false'}"
    echo ""
}

# Función para validar credenciales AWS
validate_aws_credentials() {
    echo -e "${BLUE}🔐 Validando credenciales AWS...${NC}"
    
    # Verificar que las variables de entorno están configuradas
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo -e "${RED}❌ Variables AWS_ACCESS_KEY_ID o AWS_SECRET_ACCESS_KEY no configuradas en .env${NC}"
        echo -e "${YELLOW}💡 Configura estas variables en tu archivo .env${NC}"
        return 1
    fi
    
    # Si hay session token, verificar que también esté configurado
    if [ -n "$AWS_SESSION_TOKEN" ]; then
        echo -e "${BLUE}📋 Usando credenciales temporales con session token${NC}"
    else
        echo -e "${BLUE}📋 Usando credenciales permanentes${NC}"
    fi
    
    # Configurar variables de entorno para AWS CLI
    export AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY
    if [ -n "$AWS_SESSION_TOKEN" ]; then
        export AWS_SESSION_TOKEN
    fi
    export AWS_DEFAULT_REGION="${AWS_REGION:-us-east-1}"
    
    # Probar las credenciales
    if ! aws sts get-caller-identity --region "${AWS_REGION:-us-east-1}" >/dev/null 2>&1; then
        echo -e "${RED}❌ Credenciales AWS inválidas${NC}"
        echo -e "${YELLOW}💡 Verifica AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY y AWS_SESSION_TOKEN en .env${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Credenciales AWS válidas${NC}"
    return 0
}

# Función para obtener valor de variable con fallback
get_env_var() {
    local var_name="$1"
    local default_value="$2"
    
    if [ -n "${!var_name}" ]; then
        echo "${!var_name}"
    else
        echo "$default_value"
    fi
}

# Función para debug (solo si DEBUG_MODE=true)
debug_log() {
    if [ "${DEBUG_MODE:-false}" = "true" ]; then
        echo -e "${YELLOW}[DEBUG] $1${NC}"
    fi
}

# Función para dry run
dry_run_check() {
    if [ "${DRY_RUN:-false}" = "true" ]; then
        echo -e "${YELLOW}🔍 [DRY RUN] $1${NC}"
        return 0
    fi
    return 1
}

# Cargar variables automáticamente si se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    load_env
    show_config
    
    # Validar variables requeridas
    if validate_required_vars "AWS_REGION" "CLUSTER_NAME"; then
        validate_aws_credentials
    fi
fi 