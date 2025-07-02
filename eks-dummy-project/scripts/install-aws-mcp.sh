#!/bin/bash

# Script para instalar y configurar el servidor MCP de AWS para Cursor
# Basado en: https://github.com/aws/mcp-aws-server

set -e

echo "🚀 Instalando servidor MCP de AWS para Cursor..."

# Verificar si Go está instalado
if ! command -v go &> /dev/null; then
    echo "❌ Go no está instalado. Instalando..."
    sudo apt-get update
    sudo apt-get install -y golang-go
fi

# Crear directorio para el servidor MCP
MCP_DIR="$HOME/.cursor/mcp-servers"
mkdir -p "$MCP_DIR"

# Clonar el repositorio del servidor MCP de AWS
if [ ! -d "$MCP_DIR/mcp-aws-server" ]; then
    echo "📥 Clonando repositorio MCP AWS..."
    git clone https://github.com/aws/mcp-aws-server.git "$MCP_DIR/mcp-aws-server"
fi

cd "$MCP_DIR/mcp-aws-server"

# Compilar el servidor
echo "🔨 Compilando servidor MCP..."
go build -o mcp-aws-server .

# Crear archivo de configuración para Cursor
CONFIG_DIR="$HOME/.cursor"
mkdir -p "$CONFIG_DIR"

# Crear configuración MCP para Cursor
cat > "$CONFIG_DIR/mcp_servers.json" << EOF
{
  "mcpServers": {
    "aws": {
      "command": "$MCP_DIR/mcp-aws-server/mcp-aws-server",
      "args": [],
      "env": {
        "AWS_PROFILE": "default"
      }
    }
  }
}
EOF

echo "✅ Servidor MCP de AWS instalado correctamente!"
echo "📁 Ubicación: $MCP_DIR/mcp-aws-server/mcp-aws-server"
echo "⚙️  Configuración: $CONFIG_DIR/mcp_servers.json"
echo ""
echo "🔄 Reinicia Cursor para que los cambios surtan efecto."
echo ""
echo "📋 Para verificar la instalación:"
echo "   $MCP_DIR/mcp-aws-server/mcp-aws-server --help" 