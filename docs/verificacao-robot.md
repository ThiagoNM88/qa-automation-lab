# Verificação das suítes Robot e Node

Execução em 21/11/2026, no Windows, com Python 3.12, Robot Framework 7.5.1, Browser Library 21.0.0 e Chrome instalado. Os testes Robot foram executados em modo headless.

| Comando | Resultado observado |
| --- | --- |
| `npm test` | 16 testes, 16 aprovados, 0 falhas |
| `npm run test:robot -- --headless` | 25 testes, 25 aprovados, 0 falhas |

Robot: 18 casos públicos de checkout e 7 casos no simulador local. Foram verificados cálculo, limites, erros, recuperação, limpeza, pagamentos simulados, repetição, timeout e jornada por teclado. O CT-16 iniciado pelo autor foi completado como cenário de cupom inválido.

Os relatórios completos e capturas da execução estão em `results/robot/`, fora do versionamento. O resumo acima não substitui os artefatos completos e não comprova aprovações em execuções futuras. O runner encerra o simulador local ao final da suíte.

Foram verificadas também a sintaxe do auxiliar Node e a compilação do auxiliar Python. Não foi necessário alterar o sistema sob teste para aprovar os novos cenários.

Os resultados não validam login automatizado nem pedidos autenticados no Supabase. Pagamentos e idempotência de interface foram verificados no simulador Node local. Concorrência e adulteração de dados foram verificadas na camada de unidade/API Node. Veja a [matriz detalhada de cobertura e lacunas](cobertura-robot.md).
