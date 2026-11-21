# QA Automation Lab

Laboratório de Engenharia de Qualidade com requisitos, análise de riscos, estratégia de testes e automação. Primeiro case: **checkout fictício da Loja Aurora**.

## Status

**Primeiro incremento local implementado.** Checkout didático em Node.js, interface web e 16 testes de unidade/integração executados com sucesso. Automação de navegador com Playwright e pipeline ainda não foram implementados. Os requisitos são autorais e fictícios.

## Objetivo

Demonstrar o raciocínio de qualidade por trás da automação: requisito → risco → cenário → teste → evidência. A primeira entrega será construída com Playwright; outras ferramentas serão introduzidas conforme o objetivo do estudo.

## Documentação

- [Requisitos do checkout](docs/requisitos.md)
- [Estratégia e riscos](docs/estrategia-de-testes.md)
- [Cenários iniciais](docs/cenarios.md)
- [Contrato HTTP e decisões do simulador](docs/contrato-api.md)
- [Verificação do primeiro incremento](docs/verificacao-incremento-1.md)

## Executar localmente

### Versão com login e banco na nuvem

A implementação Supabase/Vercel está em preparação para publicação. Banco e regras de acesso já foram provisionados e verificados; login real, redirecionamentos e execução da interface publicada ainda precisam de validação.

Veja [arquitetura, configuração e limites do e-mail](docs/supabase-vercel.md). Essa versão usa `npm ci` e `npm run build`; a configuração pública é exemplificada em `.env.example`.

### Simulador Node original

Requer Node.js 22.13 ou superior. Este incremento usa apenas módulos nativos do Node; não precisa instalar dependências.

```powershell
npm test
npm start
```

Abra http://127.0.0.1:4173. Para parar o servidor, use Ctrl+C no terminal. Para executar testes enquanto a aplicação está aberta, utilize outro terminal; os testes iniciam seu próprio servidor isolado em uma porta livre.

Adicione a Mochila Aurora, aplique AURORA10 e confira total de R$100,00. Experimente aprovação, recusa e timeout. Depois de confirmar, repetir a confirmação sem alterar os dados reutiliza a mesma chave. Para resolver um timeout, use o controle explícito do simulador.

## Estrutura

```text
sut/
  checkout.mjs        # cálculo e estados do simulador
  server.mjs          # API HTTP e servidor local
  index.html          # interface do checkout
tests/
  unit/               # regras e estados isolados
  integration/        # requisições HTTP ao alvo real
docs/                 # requisitos, riscos, cenários e contrato
```

O alvo liga apenas em loopback. Não foi projetado para exposição pública ou uso em produção. Dados ficam em memória; idempotência não sobrevive a reinícios nem coordena múltiplos processos. A interface ainda precisa de validação em navegador e revisão manual de acessibilidade.

## Primeira entrega planejada

- Sistema local controlado com carrinho, cupom, frete e confirmação de pedido.
- Validação de regras de cálculo e de fluxos negativos.
- Testes de API e interface com dados sintéticos e isolamento entre cenários.
- Execução reproduzível e pipeline no GitHub Actions.
- Relatórios de execução com limitações e rastreabilidade documentadas.

Não há gateway financeiro real, API de IA ou serviço pago no escopo desta primeira entrega.

## Próximas etapas

1. Revisar o primeiro incremento e explorar a interface local.
2. Adicionar testes de API e fluxos essenciais de interface com Playwright.
3. Executar e investigar resultados em navegador; preservar evidências reais.
4. Integrar a execução ao CI e documentar as decisões.

