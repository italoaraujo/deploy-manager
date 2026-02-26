#!/bin/bash
set -Eeuo pipefail

# Obtém o diretório onde o script está localizado
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Carrega o .env se ele existir
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "Erro: Arquivo .env não encontrado em $SCRIPT_DIR"
    exit 1
fi


# Configurações
PROJECT_PATH="${PROJECT_PATH:-/opt/godocs/godocs-manager}"
CONTAINER_NAME="${CONTAINER_NAME:-godocs-manager}"
BRANCH="${BRANCH:-master}"
REMOTE="${REMOTE:-origin}"
LOG_FILE="${LOG_FILE:-/var/log/godocs-deploy.log}"

LOCK_FILE="/tmp/godocs-deploy.lock"


# Exemplo de uso para teste
log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}


cd "$PROJECT_PATH"

echo "Iniciando deploy"

# Evitar execução concorrente
if [ -f "$LOCK_FILE" ]; then
    echo "[ERROR] Deploy já está em execução."
    exit 1
fi
trap 'rm -f "$LOCK_FILE"' EXIT
touch "$LOCK_FILE"


echo "Verificando atualizações na branch $BRANCH..."

git checkout "$BRANCH"

#if ! git diff --quiet || ! git diff --cached --quiet; then
#    echo "Repositório possui alterações locais. Abortando."
#    exit 1
#fi

git fetch "$REMOTE"
 
LOCAL=$(git rev-parse HEAD)
CANONICAL=$(git rev-parse $REMOTE/$BRANCH)
 
if [ "$LOCAL" != "$CANONICAL" ]; then
    log "Atualizando ambiente..."
 
    # Atualiza o projeto 
    git pull "$REMOTE" "$BRANCH"

    # Executa a migrate
    docker exec "$CONTAINER_NAME" php godocs migrate:install admin
    docker exec "$CONTAINER_NAME" php godocs migrate:install clientes
    
    # Atualiza a imagens docker 
    docker pull fabricainfo/godocs-manager:nginx-production
    docker pull fabricainfo/godocs-manager:nginx-development

    # Recria o container
    docker compose up -d --build
    docker image prune -f
 
    log "Deploy finalizado com sucesso"
else
    echo "Nenhuma ação necessária."
fi
