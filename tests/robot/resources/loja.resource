*** Settings ***
Library    Browser

*** Variables ***
${BASE_URL}    https://qa-automation-lab-thiagonicoleti56-3030.vercel.app/
${HEADLESS}    ${False}
${SLOW_MO}     400ms

*** Keywords ***
Abrir navegador da suíte
    New Browser    chromium    channel=chrome    headless=${HEADLESS}    slowMo=${SLOW_MO}

Encerrar navegador da suíte
    Close Browser

Abrir navegador de teste
    [Arguments]    ${url}=${BASE_URL}
    New Context    locale=pt-BR    viewport={'width': 1366, 'height': 900}
    Set Browser Timeout    15s
    New Page    ${url}

Encerrar navegador de teste
    # A captura acontece antes de fechar o navegador, inclusive quando o teste falha.
    Run Keyword And Ignore Error    Take Screenshot    filename=checkout-{index}
    Close Context

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

abro o carrinho
    Click    css=#open-cart
    Get Element States    css=#cart-dialog    contains    visible

adiciono o produto ao carrinho
    [Arguments]    ${produto}
    Click    role=button[name="Adicionar ${produto}"]
    abro o carrinho
    Get Text    css=#cart    contains    ${produto}

monto um carrinho de R$ 199,99
    Click    role=button[name="Adicionar Caderno Aurora"]
    Click    role=button[name="Adicionar Garrafa Aurora"]
    Click    role=button[name="Adicionar Mochila Aurora"]
    abro o carrinho
    Wait Until Keyword Succeeds    15s    200ms    Conferir valor monetário    subtotal    199,99

monto um carrinho de R$ 99,99
    Click    role=button[name="Adicionar Caderno Aurora"]
    Click    role=button[name="Adicionar Garrafa Aurora"]
    abro o carrinho
    Wait Until Keyword Succeeds    15s    200ms    Conferir valor monetário    subtotal    99,99

tento aplicar o cupom
    [Arguments]    ${codigo}
    Fill Text    css=#coupon    ${codigo}
    Click    css=#coupon-form button

devo ver o aviso
    [Arguments]    ${mensagem}
    Get Text    css=#error    contains    ${mensagem}

nenhum cupom deve estar aplicado
    Get Text    css=#applied    ==    Nenhum cupom aplicado.
    Get Element States    css=#remove-coupon    contains    hidden

o cupom válido deve estar aplicado
    Get Text    css=#applied    ==    Cupom aplicado: AURORA10

os valores da compra devem ser
    [Arguments]    ${subtotal}    ${desconto}    ${frete}    ${total}
    # Aguarda o recálculo terminar antes de comparar valores que podem estar antigos.
    Get Element States    css=#checkout    contains    enabled
    Wait Until Keyword Succeeds    15s    200ms    Conferir valor monetário    subtotal    ${subtotal}
    Wait Until Keyword Succeeds    15s    200ms    Conferir valor monetário    discount    ${desconto}
    Wait Until Keyword Succeeds    15s    200ms    Conferir valor monetário    shipping    ${frete}
    Wait Until Keyword Succeeds    15s    200ms    Conferir valor monetário    total    ${total}

altero a quantidade da mochila para
    [Arguments]    ${quantidade}
    Fill Text    css=#quantity-AUR-003    ${quantidade}
    Press Keys    css=#quantity-AUR-003    Tab

a finalização do pedido deve estar disponível
    Get Element States    css=#checkout    contains    enabled

Rejeitar quantidade e permitir correção
    [Arguments]    ${quantidade}
    que estou na Loja Aurora
    adiciono uma Mochila Aurora ao carrinho
    altero a quantidade da mochila para    ${quantidade}
    devo ver o aviso    A quantidade deve ser inteira, de 1 a 5.
    a finalização do pedido deve ficar indisponível
    altero a quantidade da mochila para    1
    os valores da compra devem ser    100,00    0,00    10,00    110,00
    a finalização do pedido deve estar disponível

removo a mochila do carrinho
    Click    role=button[name="Remover Mochila Aurora"]

removo o cupom aplicado
    Click    css=#remove-coupon

adiciono a mochila e aplico o cupom pelo teclado
    Press Keys    role=button[name="Adicionar Mochila Aurora"]    Enter
    Get Text    css=#cart-count    ==    1
    Press Keys    css=#open-cart    Enter
    Get Element States    css=#cart-dialog    contains    visible
    Type Text    css=#coupon    AURORA10
    Press Keys    css=#coupon    Tab
    Get Property    css=:focus    textContent    ==    Aplicar
    Press Keys    css=:focus    Enter
    o cupom válido deve estar aplicado
    Press Keys    css=#coupon    Escape
    Get Element States    css=#cart-dialog    contains    hidden
    Press Keys    css=#open-cart    Enter
    Get Element States    css=#cart-dialog    contains    visible

Conferir valor monetário
    [Arguments]    ${campo}    ${esperado}
    ${texto}=    Get Text    css=#${campo}
    # BRL usa espaço não separável em alguns navegadores. Ignoramos apenas espaços.
    ${normalizado}=    Evaluate    ''.join($texto.split())
    Should Be Equal As Strings    ${normalizado}    R$${esperado}
