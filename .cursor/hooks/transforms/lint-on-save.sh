#!/bin/bash

# Executa ESLint + Prettier nos arquivos modificados
FILE=$1

if [ -z "$FILE" ]; then
  # Se nenhum arquivo específico for passado, rola no projeto
  echo "Running lint and format on project..."
  npx eslint . --fix
  npx prettier --write .
else
  # Roda no arquivo específico modificado
  echo "Running lint and format on $FILE..."
  npx eslint "$FILE" --fix
  npx prettier --write "$FILE"
fi

# Se houver erros restantes, eles causarão exit code diferente de 0, 
# o que alertará o agente sobre problemas.
exit $?
