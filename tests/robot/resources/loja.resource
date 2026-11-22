*** Settings ***
Library    Browser

*** Variables ***
${BASE_URL}    https://qa-automation-lab-thiagonicoleti56-3030.vercel.app/
${HEADLESS}    ${False}
${SLOW_MO}     400ms

*** Keywords ***
Abrir navegador de teste
    New Browser    chromium    channel=chrome    headless=${HEADLESS}    slowMo=${SLOW_MO}
    New Context    locale=pt-BR    viewport={'width': 1366, 'height': 900}
    Set Browser Timeout    15s
    New Page    ${BASE_URL}

Encerrar navegador de teste
    # A captura acontece antes de fechar o navegador, inclusive quando o teste falha.
    Run Keyword And Ignore Error    Take Screenshot    filename=checkout-{index}
    Close Browser

que estou na Loja Aurora
    Get Title    ==    Loja Aurora — Essenciais do dia a dia
    Get Element Count    css=#catalog .product    ==    4

adiciono uma Mochila Aurora ao carrinho
    Click    role=button[name="Adicionar Mochila Aurora"]
    Get Text    css=#cart-count    ==    1
    Click    css=#open-cart
    Get Element States    css=#cart-dialog    contains    visible
    Get Text    css=#cart    contains    Mochila Aurora
    Wait Until Keyword Succeeds    15s    200ms    Conferir valor monetário    total    110,00

aplico o cupom AURORA10
    Fill Text    css=#coupon    AURORA10
    Click    css=#coupon-form button
    Get Text    css=#applied    ==    Cupom aplicado: AURORA10

o subtotal deve ser R$ 100,00
    Wait Until Keyword Succeeds    15s    200ms    Conferir valor monetário    subtotal    100,00

o desconto deve ser R$ 10,00
    Wait Until Keyword Succeeds    15s    200ms    Conferir valor monetário    discount    10,00

o frete deve ser R$ 10,00
    Wait Until Keyword Succeeds    15s    200ms    Conferir valor monetário    shipping    10,00

o total deve ser R$ 100,00
    Wait Until Keyword Succeeds    15s    200ms    Conferir valor monetário    total    100,00

limpo o carrinho
    Click    css=#clear-cart

o carrinho deve ficar vazio
    Get Element Count    css=#cart .cart-item    ==    0
    Get Text    css=#cart-count    ==    0
    Get Element States    css=#empty    contains    visible
    Get Element States    css=#clear-cart    contains    disabled

o cupom deve ser removido
    Get Property    css=#coupon    value    ==    ${EMPTY}
    Get Text    css=#applied    ==    Nenhum cupom aplicado.
    Get Element States    css=#remove-coupon    contains    hidden

todos os valores da compra devem ficar zerados
    FOR    ${campo}    IN    subtotal    discount    shipping    total
        Wait Until Keyword Succeeds    15s    200ms    Conferir valor monetário    ${campo}    0,00
    END

a finalização do pedido deve ficar indisponível
    Get Element States    css=#checkout    contains    disabled

Conferir valor monetário
    [Arguments]    ${campo}    ${esperado}
    ${texto}=    Get Text    css=#${campo}
    # BRL usa espaço não separável em alguns navegadores. Ignoramos apenas espaços.
    ${normalizado}=    Evaluate    ''.join($texto.split())
    Should Be Equal As Strings    ${normalizado}    R$${esperado}
