#!/bin/bash

# Guard hook: write-existing-file-guard
# Lista de arquivos protegidos
PROTECTED_FILES=(".env" "package-lock.json" "yarn.lock" "docker-compose.yml" "Dockerfile" ".github/workflows")

FILE_TO_EDIT=$1

if [ -z "$FILE_TO_EDIT" ]; then
  exit 0
fi

for protected in "${PROTECTED_FILES[@]}"; do
  if [[ "$FILE_TO_EDIT" == *"$protected"* ]]; then
    echo "⚠️ WARNING: Modificação detectada em arquivo protegido: $FILE_TO_EDIT"
    echo "Por favor, confirme se essa alteração é intencional e segura."
    
    # Log de todas as modificações em arquivos sensíveis
    mkdir -p .cursor/hooks/guards/logs
    echo "$(date): Attempted to modify $FILE_TO_EDIT" >> .cursor/hooks/guards/logs/modifications.log
    
    # Bloqueia ou alerta dependendo da configuração. Para este hook, vamos emitir exit 1 
    # para forçar a verificação.
    exit 1
  fi
done

exit 0
