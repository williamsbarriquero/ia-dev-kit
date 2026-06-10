---
name: performance-testing
description: Testes de carga, estresse e definição de limites de performance com K6.
disable-model-invocation: true
---
# Testes de Performance e Carga

## Conceitos de Carga com k6
- **VUs (Virtual Users)**: Usuários virtuais que executam a rotina de testes simultaneamente.
- **SLA e Thresholds**: Defina limites automáticos de aceitação no k6 (ex: `http_req_duration: ['p(95)<500']` - 95% das requisições devem responder em menos de 500ms).

## Tipos de Testes
- **Load Test**: Testar comportamento sob carga normal/esperada.
- **Stress Test**: Aumentar carga gradativamente para encontrar o limite do sistema.
- **Spike Test**: Sobrecarga extrema repentina para testar resiliência e auto-scaling.
- **Soak Test**: Carga contínua de longa duração para identificar vazamento de memória e exaustão de recursos.
