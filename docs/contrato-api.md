# Contrato HTTP — alvo local 0.1

Base: `http://127.0.0.1:4173`. Campos monetários são inteiros em centavos. Sem autenticação: somente para laboratório local. Dados e chaves são perdidos ao reiniciar.

## Rotas

| Método e rota | Comportamento |
| --- | --- |
| GET /health | 200 com `status: ok`. |
| GET /api/catalog | 200 com lista de SKU, nome e preço do servidor. |
| POST /api/quote | JSON com items e coupon opcional; 200 com cálculo. Sem alteração de estado. |
| POST /api/orders | JSON com items, coupon e paymentMode; header Idempotency-Key obrigatório. Cria ou recupera tentativa. |
| GET /api/attempts/{key} | 200 com o estado conhecido, ou 404 se inexistente. Consulta não resolve timeout. |
| POST /api/attempts/{key}/resolve | Controle exclusivo do simulador: muda pending para confirmed, sem nova tentativa. Estados terminais permanecem iguais. |

Entrada exemplo para confirmar:

```json
{
  "items": [{"sku": "AUR-003", "quantity": 1}],
  "coupon": "AURORA10",
  "paymentMode": "approved"
}
```

Enviar `Content-Type: application/json` e `Idempotency-Key: aurora-exemplo-001`. A chave aceita de 8 a 100 letras ASCII, números, hífen e sublinhado.

## Respostas de confirmação

- `201`: primeira tentativa aprovada ou recusada. Status de negócio `confirmed` ou `declined`; 201 não significa que o pagamento foi aprovado.
- `202`: resultado pendente de tentativa com timeout, inclusive em reenvio ainda pendente.
- `200`: reenvio idêntico de tentativa em estado terminal, ou consulta/resolução.
- `409`: mesma chave com conteúdo de negócio diferente.

O objeto contém id, key, items, subtotal, discount, shipping, total, coupon, status e paymentAttempts. A contagem permanece 1 mesmo após consulta, reenvio ou resolução.

Identidade da tentativa: itens normalizados e ordenados por SKU, cupom normalizado e modo do simulador. Campos extras de preço/total não participam do cálculo ou da identidade. Requisição inválida não reserva chave.

## Erros e diagnóstico

```json
{
  "error": {
    "code": "COUPON_MINIMUM",
    "message": "O cupom exige subtotal de pelo menos R$100,00.",
    "field": "coupon"
  },
  "correlationId": "identificador-da-requisicao"
}
```

400 para JSON malformado; 413 para corpo acima de 16 KiB; 415 para formato não JSON nas rotas de cálculo/confirmação; 422 para regra inválida; 403 para Origin divergente nas mutações; 404 para rota/tentativa ausente. Toda resposta inclui X-Correlation-ID. Os logs do terminal incluem evento, correlação, identificador do pedido e estado, sem conteúdo completo da requisição.

## Limites

Sem banco, autenticação, limite de volume de tentativas, persistência, gateway real ou coordenação entre processos. O controle de resolução é uma facilidade do laboratório, não uma API de produção. Não há alegação de conformidade integral de segurança ou acessibilidade.
