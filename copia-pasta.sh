#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ORIGEM="$SCRIPT_DIR"
DESTINO="/opt/scripts"
NOME_PASTA=$(basename "$ORIGEM")

# Cria diretório de destino se não existir
mkdir -p "$DESTINO"

# Copia apenas se a pasta ainda não existir dentro do destino
if [ ! -d "$DESTINO/$NOME_PASTA" ]; then
    cp -a "$ORIGEM" "$DESTINO"
    echo "Pasta copiada com sucesso."
else
    echo "A pasta já existe no destino."
fi
