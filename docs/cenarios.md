# Cenários iniciais — ainda não executados

Todos são propostas para revisão. Nenhum possui resultado observado ou evidência de execução nesta etapa. API/HTTP e detalhes de estado pendentes estão em requisitos.md.

| ID | Requisitos | Cenário e dados | Resultado esperado | Nível inicial |
| --- | --- | --- | --- | --- |
| CT-01 | R-02, R-03, R-05, R-06 | AUR-003 × 1, cupom AURORA10 | Subtotal 10000, desconto 1000, frete 1000, total 10000 centavos | Unidade + UI essencial |
| CT-02 | R-03 | Subtotal 9999, 10000 e 10001 centavos | Abaixo do mínimo: rejeitar cupom. Nos outros: descontos de 1000 centavos, conforme arredondamento | Unidade |
| CT-03 | R-03 | AUR-004 × 1 e cupom válido | Desconto 1001 e total 10004 centavos | Unidade |
| CT-04 | R-05 | Subtotal 19999, 20000 e 20001 centavos | Frete 1000, 0 e 0 centavos, independentemente do desconto aplicado | Unidade |
| CT-05 | R-04 | Cupom ` aurora10 ` e depois código desconhecido | Primeiro normalizado e aplicado se elegível; segundo rejeitado, mantendo o desconto válido anterior | Unidade + API |
| CT-06 | R-01, R-07 | Quantidades 0, 1, 5, 6, -1, 1.5 e texto | Aceitar apenas 1 e 5; rejeitar demais sem criar pedido | Unidade + API |
| CT-07 | R-07 | Confirmar carrinho vazio | Mensagem compreensível e nenhum pedido criado | API + UI |
| CT-08 | R-02, R-06 | Enviar total/preço adulterado para a API | Servidor usa catálogo e recalcula; valor adulterado não determina a cobrança simulada | API |
| CT-09 | R-08 | Pagamento simulado recusado | Pedido não confirmado e feedback de recusa; sem efeito de pagamento aprovado | API + UI |
| CT-10 | R-08, R-09 | Timeout, consulta e reenvio da mesma chave | Mostrar estado desconhecido até resolução; não iniciar segunda tentativa. Resultado final depende do contrato do simulador, pendente de refinamento | API + UI após refinamento |
| CT-11 | R-09 | Mesma chave e mesmo conteúdo enviados sequencialmente | Mesmo pedido e somente uma tentativa de pagamento | API |
| CT-12 | R-09 | Mesma chave e mesmo conteúdo em duas solicitações simultâneas | Um pedido e uma tentativa; verificar efeitos após as duas respostas | API após definir isolamento |
| CT-13 | R-09 | Reutilizar chave com carrinho diferente | Conflito, sem alterar pedido anterior ou iniciar nova tentativa | API |
| CT-14 | R-10 | Navegar e concluir o fluxo usando teclado | Controles operáveis, foco visível e mensagens relacionadas aos campos | Exploratório + UI complementar |

## Exemplo detalhado: CT-11

- Pré-condições: alvo disponível, dados limpos e simulador configurado para aprovação; chave inédita `aurora-ct11-001`.
- Dados: AUR-003 × 1, sem cupom. Total esperado R$110,00.
- Passos: confirmar o carrinho com a chave; guardar identificador e resposta; repetir o mesmo conteúdo e chave; consultar o pedido e as tentativas registradas.
- Esperado: ambas as respostas referem-se ao mesmo pedido; uma tentativa de pagamento; total de 11000 centavos; nenhum pedido adicional.
- Evidências futuras: versão do alvo, requisições/respostas sanitizadas, identificador de correlação e estado final.
- Status: planejado. Seletores, endpoints e asserções concretas serão definidos na implementação.

