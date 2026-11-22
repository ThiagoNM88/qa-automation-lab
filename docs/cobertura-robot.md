# Cobertura e limites da suíte Robot

A suíte cobre os cenários funcionais do planejamento nas camadas indicadas abaixo. Isso não significa que todos os comportamentos possíveis da aplicação foram testados. Os requisitos são fictícios; não há cobrança real.

Nesta branch há também um [exercício de falhas controladas](cenarios-coesos-e-falhas.md): os 28 casos regulares são complementados por dois exemplos opcionais. A pipeline desta branch ativa os exemplos e deve terminar reprovada com apenas as duas falhas intencionais. A configuração da main permanece inalterada.

## Como executar

```powershell
npm test
npm run test:robot
```

O primeiro comando executa 16 testes Node (unidade/componentes e integração HTTP). O segundo executa as suítes Robot com Chrome visível. Para executar Robot sem janela, acrescente `-- --headless`.

São 20 casos de interface pública em `tests/robot/checkout.robot` e 8 casos de pagamento no simulador local em `tests/robot/pagamentos.robot`. Há mais casos que IDs porque um cenário do planejamento pode precisar de várias variações de dados.

## Alvos e isolamento

- **Checkout público (comando padrão):** acessa a Vercel e o cálculo do Supabase. Não faz login e não cria pedidos na nuvem. Com `--local`, usado no CI, essa suíte acessa o simulador Node da versão testada; não verifica o adaptador Supabase.
- **Pagamentos:** usa a mesma interface HTML no simulador Node local, com servidor descartável em uma porta livre. O Robot inicia e encerra esse servidor automaticamente; não é preciso rodar `npm start`. O armazenamento é em memória.
- **Unidade/API Node:** verifica regras diretamente e chamadas HTTP ao simulador local. Inclui concorrência, payload adulterado e conflito de chave que não podem ser provocados pelos controles normais da tela.

Cada suíte Robot abre um navegador, e cada teste cria um contexto novo, sem cookies, carrinho ou sessão do teste anterior. Os testes de pagamentos usam chaves novas geradas pela interface; não dependem da ordem de execução. Não usamos credenciais pessoais, perfil pessoal do Chrome ou chave de administrador.

## Rastreabilidade

| ID | Cobertura Robot | Complemento Node / limite |
| --- | --- | --- |
| CT-01 | Mochila com cupom; quatro valores da compra | Cálculo independente em unidade e API |
| CT-02 | Cupom abaixo do mínimo (R$99,99) e no mínimo (R$100,00) | Unidade também verifica R$100,01, que não é uma combinação disponível no catálogo |
| CT-03 | Kit de R$100,05: desconto R$10,01; total R$100,04 | Arredondamento em unidade |
| CT-04 | Frete a R$199,99 e R$200,00; desconto não remove frete nem muda a regra de gratuidade | Unidade também verifica R$200,01 |
| CT-05 | Normalização de espaços e caixa; código desconhecido preserva cupom válido; remoção de cupom | Normalização e rejeição em unidade |
| CT-06 | Quantidades 1 e 5; rejeitar 0, -1, 6, 1.5 e vazio; corrigir e recuperar o checkout | Unidade também rejeita texto e null; input number não permite digitar qualquer texto |
| CT-07 | Carrinho inicial vazio e remoção do último item desabilitam finalização | API rejeita envio vazio sem criar pedido |
| CT-08 | Não há tentativa de adulteração pela tela normal | Unidade/API enviam preços e total falsos e verificam recálculo pelo servidor local |
| CT-09 | Aprovação, recusa e recuperação com nova tentativa no simulador local | Não verifica gateway real nem finalização autenticada no Supabase |
| CT-10 | Consultar/repetir timeout, resolver e preservar identificador e uma tentativa | API também verifica os códigos HTTP e estados persistidos em memória |
| CT-11 | Reconfirmar pedido retorna o mesmo resultado e uma tentativa | Unidade/API verificam idempotência local |
| CT-12 | Concorrência é verificada pela integração HTTP Node | Não é um teste de concorrência distribuída do banco na nuvem |
| CT-13 | Conflito de chave é verificado pela unidade/API Node | UI troca a chave ao alterar carrinho; o payload conflitante exige chamada direta |
| CT-14 | Compra por teclado no simulador; cupom, foco no botão Aplicar, Escape e reabertura do carrinho na nuvem | Cobertura funcional parcial; não é auditoria completa de acessibilidade |
| CT-15 | Limpar itens e cupom, zerar contador/valores e desabilitar finalização | Não verifica limpar durante confirmação nem histórico autenticado |
| CT-16 | Cupom INVALIDO exibe aviso, não aplica desconto e mantém subtotal, frete e total | Cenário iniciado pelo autor do portfólio e completado na suíte |

## Organização dos arquivos

```text
tests/robot/
  checkout.robot          # cenários públicos, em estilo BDD
  pagamentos.robot        # pagamentos fictícios e idempotência pela interface local
  resources/loja.resource # configuração e palavras-chave reutilizáveis
  libraries/LojaLocal.py  # ciclo de vida do servidor descartável
scripts/robot-local-target.mjs  # inicia a API Node numa porta livre
```

`Suite Setup` abre o navegador uma vez. `Test Setup` cria o contexto e abre a página. `Test Teardown` captura a tela e fecha o contexto. `Suite Teardown` fecha o navegador e, na suíte de pagamentos, encerra o processo Node criado para ela.

Os passos permanecem nos resources. A biblioteca Python cuida apenas do servidor de teste; ela não substitui os cliques nem as validações no navegador.

## Evidências

Depois de `npm run test:robot`, os resultados ficam em `results/robot/`: `report.html` (resumo), `log.html` (passos e capturas) e `output.xml` (resultado estruturado). Há captura ao final de cada teste, inclusive quando falha. Esses dados são locais, não são enviados ao GitHub e são substituídos nas próximas execuções. No GitHub Actions, a pipeline executa os 28 casos regulares com `--headless --local`, contra o código do commit, e guarda relatórios e capturas como artefatos por três dias. Consulte [a explicação da esteira](ci-github-actions.md).

Executar pelo botão do RobotCode pode testar apenas o cenário selecionado e usar outra pasta de saída. Para executar a suíte inteira com a configuração descrita aqui, use o comando npm.

## Fora desta entrega

Login automatizado, cadastro/confirmação de e-mail, isolamento entre contas pela interface, pedidos autenticados no Supabase, carga, segurança completa, acessibilidade completa e compatibilidade com Firefox/WebKit. Os testes SQL de RLS e o check anônimo do Supabase são verificações separadas; não fazem parte dos dois comandos acima.
