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

## Revalidação em 22/11/2026

Um conflito de salvamento no editor removeu `Suite Setup` e `Suite Teardown` do arquivo de checkout. Sem o lançamento explícito com `channel=chrome`, a criação do contexto tentou abrir um Chromium não instalado. As duas configurações foram restauradas, preservando o restante da edição.

Na execução seguinte, 24 casos passaram e o CT-01 falhou porque contou os produtos antes do carregamento assíncrono do catálogo. A contagem agora aguarda até 20 segundos pela condição esperada, sem pausa fixa. Foi reexecutado somente o caso que falhou: 1 teste, 1 aprovado, 0 falhas. Não foi feita uma nova rodada completa após essa correção.

O relatório original foi preservado em `results/robot-antes-correcao-20261122-49dc7e4a/`; a revalidação está em `results/robot-revalidacao/`. Esses artefatos locais permanecem fora do Git. O relatório de `results/robot/` ainda representa a rodada com 24 aprovados e 1 falha, até a próxima execução completa.

## Execução completa e CI em 22/11/2026

Posteriormente, os 25 casos Robot foram executados com `--headless --local` e passaram, validando o modo usado no CI. O comando `npm run test:ci` também passou com 16 testes e gerou JUnit.

A [primeira execução no GitHub Actions](https://github.com/ThiagoNM88/qa-automation-lab/actions/runs/45027018018) confirmou os mesmos resultados no Ubuntu 24.04: 16 testes Node e 25 Robot aprovados, com upload de ambos os artefatos. Isso valida o workflow no runner remoto, além da execução local. O modo CI usa o simulador do commit e não valida a integração Supabase nem a versão publicada na Vercel.
