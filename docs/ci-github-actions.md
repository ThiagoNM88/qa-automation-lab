# Entendendo a esteira de Integração Contínua

## O que acontece quando enviamos código

```text
git push ou Pull Request para main
  → GitHub cria uma máquina temporária
  → baixa o código daquele envio
  → instala os programas e dependências
  → executa 16 testes de unidade/API
  → se passarem, executa Robot: 3 smoke em branches/PRs ou 28 na main/manual
  → disponibiliza os resultados e as capturas
```

O arquivo que descreve essa receita é `.github/workflows/qa.yml`. O computador pessoal não precisa permanecer ligado depois do envio. Esta esteira é CI: verifica código e produz evidências. Ela não faz deploy, não promove versões na Vercel e não migra o Supabase.

## Primeira execução real validada

Em 22/11/2026, a [execução 45027018018](https://github.com/ThiagoNM88/qa-automation-lab/actions/runs/45027018018), referente ao commit `031b8b8e2ea746aa0e63ba3f27b00655f690cd0e`, terminou com sucesso no Ubuntu do GitHub: 16 testes Node e 25 casos Robot aprovados. Os logs confirmam os dois comandos, e os uploads foram concluídos.

Foram gerados os artefatos `node-45027018018-1` (JUnit) e `robot-45027018018-1` (29 arquivos, aproximadamente 4 MB, incluindo relatórios e capturas). A expiração registrada foi 25/11/2026. O link da execução permanece como referência; os arquivos deixam de estar disponíveis após a retenção configurada.

## Como ler o arquivo YAML

| Bloco | Significado no projeto |
| --- | --- |
| `name` | Nome exibido na aba Actions: QA Automation CI |
| `on` | Eventos: push em branches, Pull Request para main e execução manual |
| `jobs` | Grupos de trabalho: unidade/API e Robot |
| `runs-on` | Máquina do GitHub que executará o trabalho: Ubuntu 24.04 padrão |
| `steps` | Passos executados na ordem escrita |
| `uses` | Ação reutilizável, como instalar Node ou guardar arquivos |
| `run` | Comando de terminal executado na máquina do GitHub |
| `needs: unidade-api` | Robot só começa quando a etapa de unidade/API passa |
| `if: always()` | Tenta guardar evidências mesmo quando uma etapa anterior falha |
| `retention-days: 3` | Arquivos de evidência ficam disponíveis por três dias |
| `permissions` | O token da execução só precisa ler o código |
| `concurrency` | Um envio mais recente cancela a execução antiga daquela branch |

As ações oficiais estão fixadas por SHA de commit. Os comentários de versão indicam a versão consultada; o SHA evita que uma mudança futura da tag altere silenciosamente a ação usada. O HTML sem ZIP usa upload-artifact v7.

## Quais comandos são executados

Unidade/API:

```powershell
npm run test:ci
```

Executa os mesmos 16 testes de `npm test` e grava `results/node/junit.xml`, além do resultado legível no terminal.

Robot no CI para branches de trabalho e Pull Requests:

```powershell
npm run test:robot -- --headless --local --smoke
```

Robot no CI na main e em execuções manuais:

```powershell
npm run test:robot -- --headless --local
```

`--headless` executa o Chrome sem janela. `--local` inicia uma loja Node descartável a partir do código daquela versão, numa porta livre. O servidor é encerrado ao terminar. A suíte de pagamentos também gerencia sua própria instância local. Não precisamos iniciar servidores manualmente nem configurar senhas na pipeline.

Isso permite testar mudanças do próprio commit. Sem `--local`, os cenários públicos acessam a loja publicada, que pode corresponder a outra versão. Essa execução continua útil para explorar o ambiente publicado, mas não substitui a verificação de uma mudança antes do merge.

O CI local não valida o adaptador Supabase, Auth ou pedidos reais na nuvem. Esses limites continuam explícitos na [matriz de cobertura](cobertura-robot.md).

## Onde acompanhar e baixar evidências

1. Abra o repositório no GitHub e entre em **Actions**.
2. Selecione a execução **QA Automation CI**.
3. Abra o job **1 - Unidade e API** ou **2 - Robot Framework**.
4. Clique no passo desejado para ler os comandos e suas saídas.
5. Na página **Summary**, consulte os totais e o link **Abrir cenários e capturas no navegador**. O HTML incorpora as imagens e abre sem extrair ZIP.
6. Para os arquivos originais, procure **Artifacts**, baixe o pacote `robot-...`, extraia o ZIP e abra `report.html` ou `log.html`.

O pacote Robot inclui relatórios, XML, capturas e arquivos auxiliares que existirem na pasta daquela execução. O pacote `node-...` inclui o JUnit. Os nomes contêm o ID e a tentativa da execução para distinguir evidências. Esses pacotes são gerados pelo GitHub; não é necessário versionar imagens e relatórios no código.

Se a preparação falhar antes de criar resultados, o passo de upload avisa que não encontrou arquivos. Nesse caso, os logs do passo de preparação são a evidência disponível.

A execução manual (`Run workflow`) está disponível porque o workflow já existe na branch padrão. A seleção manual executa a regressão completa, inclusive quando o usuário escolhe uma branch de trabalho.

## Como decidir a estratégia de testes

Comece com quatro perguntas:

1. **Risco:** qual o prejuízo se a mudança estiver errada?
2. **Impacto:** quais áreas usam o código alterado, inclusive indiretamente?
3. **Tempo:** quanto demora executar e investigar os testes?
4. **Ambiente:** o teste precisa de código local, banco de teste, aplicação publicada ou integração externa?

Exemplos:

| Mudança | Verificações prioritárias |
| --- | --- |
| Texto ou posição de botão | Tela, navegação e teclado; verificar também o comportamento do botão |
| Cupom ou frete | Cálculos, limites, arredondamento, API e jornada de compra |
| Função compartilhada do checkout | Regressão das compras e variações de pagamento |
| Login ou permissões | Acesso permitido, acesso negado, sessão e isolamento entre contas |

Em uma aplicação grande, costuma ser útil combinar testes rápidos em cada Pull Request, regressão mais ampla em horários programados e smoke após deploy. Seleção por impacto precisa considerar dependências; um arquivo aparentemente pequeno pode afetar várias funcionalidades.

Aqui a estratégia didática evoluiu para 16 testes Node em todos os eventos, 3 smoke Robot em branches/PRs e 28 casos regulares na main ou manualmente. Os 3 testes do gerador de relatórios também rodam no job Robot. Não configuramos uma execução noturna nem um disparo após deploy nesta entrega. Veja a [seleção smoke e seus limites](smoke-robot.md): um PR verde verifica os smoke, enquanto defeitos fora dessa seleção podem aparecer na regressão após o merge.

Uma execução vermelha reprova a esteira. A main possui uma regra ativa, configurada pelo administrador, que exige PR, branch atualizada e aprovação dos checks `1 - Unidade e API` e `2 - Robot Framework`. A configuração de proteção é separada do YAML e seus nomes de checks foram preservados nesta seleção.

## Ambiente e custos

O repositório é público e usa runners padrão, sem máquinas maiores ou serviços pagos adicionados. Os testes não precisam de chave de administrador nem de credenciais pessoais. A retenção dos artefatos foi limitada a três dias; baixe evidências importantes antes da expiração. Armazenamento e outros limites da conta continuam sujeitos às regras do GitHub.

Referências oficiais: [eventos de workflows](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow), [runners e cobrança](https://docs.github.com/en/actions/concepts/billing-and-usage) e [imagem Ubuntu 24.04](https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md).
