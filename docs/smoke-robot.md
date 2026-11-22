# Seleção smoke do Robot

O QA escolhe os comportamentos essenciais com base em risco e marca os cenários com a tag `smoke`. O executor filtra essa tag; não duplica os testes.

| Cenário | Motivo |
| --- | --- |
| CT-01 — Calcular total da compra com cupom | Verifica a composição dos valores da compra. |
| CT-15 — Limpar carrinho com produto e cupom aplicado | Verifica a recuperação para um carrinho vazio. |
| CT-09 — Confirmar pedido com aprovação simulada | Verifica que a compra simulada é confirmada com uma única tentativa de pagamento. |

CT-01 e CT-15 já tinham a tag. CT-09 foi incluído pela importância da confirmação do pedido. Esta é uma seleção inicial do laboratório, sujeita à revisão conforme os riscos evoluem. O pagamento é simulado e não cobre uma operadora real.

## Executar localmente

```powershell
npm run test:robot -- --headless --local --smoke
```

Esperado: três casos aprovados. `--smoke` é convertido em `--include smoke` no comando do Robot. Retire `--headless` para acompanhar o Chrome visível. `--smoke` e `--demo-falhas` são seleções alternativas e não podem ser combinadas.

A regressão regular continua disponível:

```powershell
npm run test:robot -- --headless --local
```

Esperado: 28 casos. Os três smoke fazem parte desses 28, pois usam os mesmos cenários.

## Seleção automática na CI

| Evento | Seleção Robot |
| --- | --- |
| Push em branch de trabalho | Smoke: 3 cenários |
| Pull Request para main | Smoke: 3 cenários |
| Push na main, inclusive após merge | Regressão regular: 28 cenários |
| Execução manual pelo Actions | Regressão regular: 28 cenários |

Os 16 testes de unidade/API e os 3 testes do gerador de relatórios continuam sendo executados em todos esses eventos. Os nomes dos jobs obrigatórios permanecem `1 - Unidade e API` e `2 - Robot Framework`, compatíveis com a proteção da main. Os relatórios e as capturas correspondem à seleção executada.

Esta estratégia reduz a cobertura de navegador antes do merge: um PR verde confirma os três smoke, não os 28 cenários. Uma falha exclusiva da regressão pode aparecer após o merge na main e precisa ser investigada. Para mudanças de maior risco, execute também a regressão local antes de enviar o PR. A seleção deve evoluir com os riscos do projeto; não representa uma regra universal para todas as equipes.

## Responsabilidades

- QA: define a seleção, modifica os testes, valida localmente e envia por branch/PR.
- Pipeline: executa os comandos configurados automaticamente.
- Administrador: configura as regras que exigem os checks antes do merge.

Adicionar uma tag, isoladamente, não altera os gatilhos: a seleção acima é aplicada pela variável `ROBOT_SUITE` e pelo comando condicional em `.github/workflows/qa.yml`. As falhas didáticas continuam restritas ao comando local com `--demo-falhas`.
