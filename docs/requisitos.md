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

## Dados de referência

Catálogo e carrinho abaixo são fixtures propostas; o servidor ainda será implementado.

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

## Refinamentos pendentes

- Definir contrato HTTP e esquema de erros antes dos testes de API.
- Definir o prazo de retenção das chaves de idempotência; a primeira implementação local deverá explicitar seu comportamento após reinício.
- Definir o mecanismo de isolamento de tentativas simultâneas na implementação.
- Descrever como o simulador resolve uma tentativa com timeout e como a consulta informa esse estado.

