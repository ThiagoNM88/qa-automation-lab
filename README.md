# QA Automation Lab

Laboratório de Engenharia de Qualidade com requisitos, análise de riscos, estratégia de testes e automação. Primeiro case: **checkout fictício da Loja Aurora**.

## Status

**Loja publicada e suítes Robot implementadas.** A Loja Aurora tem catálogo, carrinho, cupom e acesso à conta no cabeçalho. A versão na nuvem usa Supabase Auth e banco com controle de acesso por usuário. Existem 16 testes Node de unidade/componentes e integração HTTP no simulador local, além de 25 casos Robot (18 na interface pública e 7 de pagamentos no simulador local). Pipeline e suítes independentes de Playwright, Cypress e Selenium ainda não foram implementadas. Os requisitos são autorais e fictícios.

[Abrir a Loja Aurora](https://qa-automation-lab-thiagonicoleti56-3030.vercel.app/)

## Objetivo

Demonstrar o raciocínio de qualidade por trás da automação: requisito → risco → cenário → teste → evidência. A primeira suíte de navegador usa Robot Framework com Browser Library, que utiliza Playwright internamente. Uma suíte própria com Playwright Test será uma entrega distinta.

## Documentação

- [Requisitos do checkout](docs/requisitos.md)
- [Estratégia e riscos](docs/estrategia-de-testes.md)
- [Cenários iniciais](docs/cenarios.md)
- [Contrato HTTP e decisões do simulador](docs/contrato-api.md)
- [Verificação do primeiro incremento](docs/verificacao-incremento-1.md)
- [Executar e entender o primeiro teste Robot](docs/robot-primeiro-teste.md)
- [Matriz de cobertura e limites da suíte](docs/cobertura-robot.md)
- [Resultado da verificação das suítes](docs/verificacao-robot.md)
- [Entender e acompanhar a pipeline no GitHub Actions](docs/ci-github-actions.md)

## Executar as suítes Robot

Neste computador, o ambiente já está preparado. No terminal da raiz do projeto:

```powershell
npm run test:robot
```

O Chrome executa as suítes de checkout público e pagamentos simulados locais. Cada cenário tem um contexto independente. O relatório fica em `results/robot/report.html`. Para instalar em outro computador, veja o [passo a passo](docs/robot-primeiro-teste.md). Os testes públicos acessam a loja publicada. Os de pagamento iniciam um simulador local automaticamente, sem contas nem pedidos na nuvem. Veja a [matriz de cobertura e limites](docs/cobertura-robot.md).

## Executar localmente

### Versão com login e banco na nuvem

A versão Supabase/Vercel está publicada. O cadastro e o login foram confirmados manualmente pelo responsável pelo projeto. O teste Robot verifica a jornada pública de carrinho e cupom; fluxos autenticados ainda não têm cobertura automatizada de navegador.

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
  integration/        # requisições HTTP ao simulador local
  robot/              # cenário BDD e palavras-chave da interface publicada
docs/                 # requisitos, riscos, cenários e contrato
```

O servidor Node local liga apenas em loopback e usa dados em memória; sua idempotência não sobrevive a reinícios nem coordena múltiplos processos. A loja publicada usa uma implementação separada com Supabase. Os 16 testes Node não comprovam o funcionamento do login ou do banco na nuvem. A revisão manual de acessibilidade continua pendente.

## Primeira entrega planejada

- Sistema local controlado com carrinho, cupom, frete e confirmação de pedido.
- Validação de regras de cálculo e de fluxos negativos.
- Testes de API e interface com dados sintéticos e isolamento entre cenários.
- Execução reproduzível e pipeline no GitHub Actions.
- Relatórios de execução com limitações e rastreabilidade documentadas.

Não há gateway financeiro real, API de IA ou serviço pago no escopo desta primeira entrega.

## Próximas etapas

1. Revisar o primeiro cenário Robot e acompanhar a execução com navegador visível.
2. Revisar cenários negativos, limites, teclado e pagamentos locais na [matriz de cobertura](docs/cobertura-robot.md).
3. Adicionar cobertura autenticada com contas exclusivas de teste.
4. Integrar a execução ao CI e documentar as decisões.

