# Estratégia de testes — proposta inicial

## Contexto e abordagem

Projeto individual de portfólio, sem equipe Scrum, velocidade conhecida ou cadência acordada. O planejamento será por **incrementos e marcos verificáveis**, sem inventar sprints. Essa escolha pode mudar se houver um contexto real de equipe e fluxo.

| Marco | Atividades e saída esperada |
| --- | --- |
| Regras revisadas | Refinar exemplos, lacunas e contrato. Saída: critérios verificáveis e dúvidas explicitadas. |
| Sistema local | Implementar cálculo, simulação e isolamento dos dados. Saída: alvo executável e testes de cálculo passando. |
| Automação | Implementar verificações de API e fluxos UI prioritários. Saída: testes relacionados aos requisitos e resultados de execução reais. |
| Integração contínua | Executar em ambiente limpo e publicar relatórios. Saída: pipeline reproduzível, falhas investigadas e limitações documentadas. |

## Riscos priorizados

Classificação qualitativa proposta por impacto. Não existem dados reais de probabilidade ou incidentes.

| Risco | Prioridade proposta | Requisitos | Abordagem |
| --- | --- | --- | --- |
| Cobrança/tentativa duplicada no reenvio | Alta | R-08, R-09 | API com repetição e concorrência; verificar o estado persistido e a contagem de tentativas. |
| Total incorreto por limites ou arredondamento | Alta | R-02 a R-06 | Testes de cálculo com valores esperados independentes e limites; integração para validar a resposta da API. |
| Pedido confirmado após recusa ou timeout | Alta | R-08 | Simular respostas e verificar transições de estado e feedback na UI. |
| Pedido com carrinho inválido ou total adulterado | Alta | R-01, R-02, R-07 | API com entradas inválidas e adulteração; verificar ausência de efeitos indevidos. |
| Comprador impedido de concluir pelo teclado | Média | R-10 | Exploração manual por teclado e verificações automatizadas complementares. |

## Distribuição das verificações

- Unidade: regras de quantidade, cálculo em centavos, desconto, frete e arredondamento.
- API: validação no servidor, estados, idempotência e efeitos persistidos. Implementação atual com `node:test` e HTTP real ao simulador local.
- Interface: Robot Framework com Browser Library, locators por papel e ID, asserções com espera por condição e contextos independentes. A configuração com janela usa `slowMo` para demonstração, sem pausas fixas para sincronizar respostas.
- Exploratórios: mensagens, recuperação e navegação por teclado. Registrar sessão e observações reais quando executada.

Cada teste cria seus dados e deve funcionar sem depender da ordem de execução. Os pagamentos são simulados em uma instância Node descartável; checkout e cupons também são testados na loja publicada, sem login. Contrato: [contrato-api.md](contrato-api.md). Alvos, cobertura e lacunas: [cobertura-robot.md](cobertura-robot.md).

## Critérios

Entrada: regras do cenário definidas, contrato aplicável documentado, alvo disponível e dados isolados.

Saída do incremento: cenários prioritários executados; desvios críticos corrigidos e retestados; falhas de teste/ambiente investigadas; resultados relacionados à versão; lacunas e riscos residuais registrados. Não há garantia de ausência de defeitos.

## DevOps e evidências

CI planejado para mudanças e pull requests. Guardar relatórios e traces em falhas, sem credenciais. Registrar versão, cenário, dados, esperado, obtido e classificação da falha. Retentativas não devem ocultar instabilidade.

Observabilidade inicial planejada: logs estruturados com correlation ID, chave de tentativa e transição de estado, sem dados pessoais. Os testes poderão usar esses sinais na investigação; asserções devem continuar verificando o comportamento e os efeitos relevantes.

## Processos e melhoria

Revisão didática inspirada em PQA: amostrar requisito, cenário, resultado e decisão; identificar elos ausentes e registrar ação de melhoria. Não é avaliação formal CMMI nem atribuição de maturidade.

