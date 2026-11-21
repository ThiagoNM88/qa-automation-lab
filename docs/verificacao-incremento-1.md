# Verificação do primeiro incremento

Data: 21/11/2026. Execução local no Windows, Node.js v26.7.0.

Comando: `npm test`.

Resultado observado: **16 testes, 16 aprovados, 0 falhas**. São 9 testes de unidade/estado e 7 de integração HTTP usando servidor real em porta dinâmica. Isso não equivale à execução dos 14 cenários completos em todos os níveis.

## Evidência por tema

| Tema | Verificação executada |
| --- | --- |
| CT-01 a CT-04 | Cálculo, arredondamento e limites de cupom/frete em unidade; cálculo também consultado via HTTP. |
| CT-05 | Normalização e rejeição de cupom em unidade. Preservação visual do cupom anterior ainda pendente. |
| CT-06/07 | Quantidades e carrinho inválidos; requisição inválida não reserva chave. |
| CT-08 | Adulteração de preço/total ignorada pelo cálculo; orçamento HTTP usa valor do catálogo. |
| CT-09 | Estado recusado verificado em unidade. Feedback visual ainda pendente. |
| CT-10/11 | Timeout, consulta, resolução e reenvio sem nova tentativa, em unidade e HTTP. |
| CT-12/13 | Chamadas HTTP concorrentes com mesma chave e conflito por conteúdo diferente, verificando estado final. |
| Protocolo | JSON malformado, tipo de conteúdo e origem divergente. |

Primeira tentativa dos testes HTTP foi bloqueada pelo sandbox (`EACCES` ao conectar em loopback). A execução autorizada com conexão local permitida passou. Não foi um defeito observado nas regras do checkout.

## Não verificado nesta etapa

- Execução e layout em navegador; fluxos de interface com Playwright.
- CT-14: teclado, foco e tecnologias assistivas.
- CI no GitHub Actions.
- Recuperação após queda, execução distribuída e gateway real, fora do escopo.

Para repetir a evidência, executar `npm test` no checkout atual. Novas alterações exigem execução novamente antes de declarar o resultado da nova versão.
