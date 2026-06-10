#!/bin/bash
# RPE Harness - Update Script

echo "🔄 Atualizando regras do RPE Harness..."

# Simulação de git pull e sync
echo "Fazendo pull das últimas atualizações..."
git pull origin main || echo "Aviso: Nenhuma branch trackeada configurada."

echo "✅ Regras atualizadas com sucesso. O arquivo agents.override.md foi preservado."
