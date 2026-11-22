# Loja Aurora — requisitos propostos

Contexto inteiramente fictício, criado para estudo e portfólio. As regras abaixo são decisões do exercício, não requisitos de um cliente real. Versão proposta: 0.1.

## Escopo

Comprador consulta seu carrinho, aplica um cupom e confirma um pedido com pagamento simulado. A API é responsável por validar e recalcular os valores; não deve confiar no total enviado pela interface.

| ID | Regra e critério de aceitação |
| --- | --- |
| R-01 | Cada item deve ter quantidade inteira entre 1 e 5, inclusive. Rejeitar zero, negativos, frações, valores não numéricos e quantidade acima de 5. |
| R-02 | Preços vêm do catálogo do servidor e são representados em centavos inteiros. Subtotal é a soma de preço unitário × quantidade. |
| R-03 | O cupom AURORA10 concede 10% de desconto no subtotal a partir de R$100,00, inclusive. Arredondar o desconto para o centavo mais próximo; meio centavo arredonda para cima. |
| R-04 | Apenas um cupom pode estar aplicado. Remover espaços externos e ignorar maiúsculas/minúsculas. Outro código deve ser rejeitado com mensagem compreensível e sem alterar valores válidos do carrinho. |
| R-05 | Frete fixo de R$10,00; grátis quando o subtotal antes do desconto atingir R$200,00. O frete não recebe desconto do cupom. |
| R-06 | Total = subtotal − desconto + frete. A interface deve mostrar os quatro valores e refletir a resposta calculada pelo servidor. |
| R-07 | Carrinho vazio ou inválido não pode gerar pedido. Erros devem identificar o problema sem criar registros parciais de pedido. |
| R-08 | Pagamento usa somente respostas simuladas: aprovado, recusado e timeout. Recusa não confirma pedido; timeout mostra resultado ainda desconhecido e permite consultar a tentativa pela chave. Não registrar dados financeiros reais. |
| R-09 | Confirmação exige chave de idempotência. Repetir a mesma chave e conteúdo deve retornar o mesmo pedido e não repetir a tentativa de pagamento. Mesma chave com conteúdo diferente deve retornar conflito sem alterar o pedido anterior. |
| R-10 | A interface deve permitir operar carrinho, cupom e confirmação por teclado, com foco visível, rótulos nos campos e mensagens de erro associadas aos campos relevantes. |

## Limpeza de carrinho (incremento de interface)

**R-11:** Limpar o carrinho remove todos os itens e o cupom aplicado, esvazia o campo de cupom, zera subtotal, desconto, frete, total e contador, mostra o estado vazio e desabilita a finalização. Não exclui pedidos já registrados. Durante uma confirmação em andamento, a limpeza fica indisponível.

## Dados de referência

Catálogo abaixo implementado no alvo local. Os valores são fictícios e representados em centavos inteiros no servidor.

| SKU | Preço unitário |
| --- | --- |
| AUR-001 | R$49,99 |
| AUR-002 | R$50,00 |
| AUR-003 | R$100,00 |
| AUR-004 | R$100,05 |

Exemplos calculados independentemente:

- AUR-003 × 1 + AURORA10: subtotal R$100,00; desconto R$10,00; frete R$10,00; total R$100,00.
- AUR-003 × 2 + AURORA10: subtotal R$200,00; desconto R$20,00; frete grátis; total R$180,00.
- AUR-004 × 1 + AURORA10: subtotal R$100,05; desconto R$10,01; frete R$10,00; total R$100,04.
- AUR-001 × 2: subtotal R$99,98; cupom não elegível; frete R$10,00; total sem desconto R$109,98.

## Fora do primeiro incremento

Autenticação, reserva de estoque, estorno, gateway real, cálculo de frete por CEP, regras fiscais, testes de carga e comprovação de conformidade integral de acessibilidade. Isso delimita cobertura e riscos residuais; não representa validação desses temas.

## Decisões do primeiro incremento

- Contrato HTTP e erros: [contrato-api.md](contrato-api.md).
- Chaves retidas em memória durante a vida do processo, sem expiração automática. Reiniciar limpa o histórico. Não há garantia de idempotência após reinício.
- Verificação e reserva da chave ocorrem de forma síncrona no mesmo processo Node. Não há coordenação distribuída; isso não é uma implementação de gateway financeiro.
- Timeout permanece `pending` até resolução explícita no endpoint didático. Resolver simula aprovação tardia e não inicia outra tentativa. Nenhum temporizador decide o resultado.
- SKU repetido em linhas diferentes é rejeitado; atualizar quantidade da linha existente. Valores de preço e total enviados pelo cliente são ignorados.
- A API de orçamento é sem estado: erro de cupom não modifica carrinho. A interface mantém o cupom anterior ao rejeitar substituição inválida; a validação desse comportamento em navegador ainda está pendente.

