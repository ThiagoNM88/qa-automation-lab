# QA Automation Lab

Laboratório de Engenharia de Qualidade com requisitos, análise de riscos, estratégia de testes e automação. Primeiro case: **checkout fictício da Loja Aurora**.

## Status

**Planejamento inicial.** Os documentos são propostas autorais para estudo. Sistema sob teste, testes automatizados e pipeline ainda não foram implementados ou executados. Não há resultados de execução nesta etapa.

## Objetivo

Demonstrar o raciocínio de qualidade por trás da automação: requisito → risco → cenário → teste → evidência. A primeira entrega será construída com Playwright; outras ferramentas serão introduzidas conforme o objetivo do estudo.

## Documentação

- [Requisitos do checkout](docs/requisitos.md)
- [Estratégia e riscos](docs/estrategia-de-testes.md)
- [Cenários iniciais](docs/cenarios.md)

## Primeira entrega planejada

- Sistema local controlado com carrinho, cupom, frete e confirmação de pedido.
- Validação de regras de cálculo e de fluxos negativos.
- Testes de API e interface com dados sintéticos e isolamento entre cenários.
- Execução reproduzível e pipeline no GitHub Actions.
- Relatórios de execução com limitações e rastreabilidade documentadas.

Não há gateway financeiro real, API de IA ou serviço pago no escopo desta primeira entrega.

## Próximas etapas

1. Revisar as regras propostas e os cenários.
2. Implementar o sistema local e seus testes de cálculo.
3. Adicionar testes de API e fluxos essenciais de interface com Playwright.
4. Executar e investigar resultados; preservar evidências reais.
5. Integrar a execução ao CI e documentar as decisões.

Os comandos de instalação e execução serão adicionados quando houver implementação verificável.

