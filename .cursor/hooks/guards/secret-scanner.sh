#!/bin/bash

# Varre arquivos em stage (staged files) por padrões de credenciais
echo "Scanning for secrets in staged files..."

# Regex patterns (AWS keys, tokens JWT, passwords hardcoded, etc)
PATTERN="(password|secret|api[_-]?key|token|AKIA[A-Z0-9]{16})\s*[:=]\s*['\"][^'\"]+['\"]"

# Usar git diff para arquivos no stage e ignorar case (-i)
MATCHES=$(git diff --cached -i -E | grep -E "$PATTERN")

if [ ! -z "$MATCHES" ]; then
  echo "❌ ERROR: Potential secrets exposed in staged files!"
  echo "$MATCHES"
  exit 1
fi

echo "✅ No secrets found."
exit 0
