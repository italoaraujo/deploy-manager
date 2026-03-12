#!/bin/bash
set -Eeuo pipefail

# Obtém o diretório onde o script está localizado
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Carrega o .env se ele existir
if [ -f "$SCRIPT_DIR/../.env" ]; then
    source "$SCRIPT_DIR/../.env"
else
    echo "Erro: Arquivo .env não encontrado em $SCRIPT_DIR"
    exit 1
fi

# Executa a migrate
docker exec "$CONTAINER_NAME" php godocs migrate:install admin
docker exec "$CONTAINER_NAME" php godocs migrate:install clientes

# Atualiza a imagens docker 
docker pull fabricainfo/godocs-manager:nginx-production
docker pull fabricainfo/godocs-manager:nginx-development


