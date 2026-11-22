Language: pt

*** Settings ***
Documentation       Pagamentos simulados na loja Node local descartável. Não valida Auth nem pagamentos do Supabase.
Resource            resources/loja.resource
Library             libraries/LojaLocal.py
Suite Setup         Preparar loja descartável
Suite Teardown      Encerrar ambiente local
Test Setup          Abrir loja local de teste
Test Teardown       Encerrar navegador de teste

*** Test Cases ***
CT-09 - Confirmar pedido com aprovação simulada
    [Tags]    pagamento    local    aprovado    CT-09
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    Quando confirmo o pedido com pagamento    approved
    Então a tentativa deve ter o status    Confirmado
    E deve haver uma única tentativa de pagamento

CT-09 - Recusar pagamento sem confirmar o pedido
    [Tags]    pagamento    local    negativo    CT-09
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    Quando confirmo o pedido com pagamento    declined
    Então a tentativa deve ter o status    Recusado
    E deve haver uma única tentativa de pagamento
    E devo ver o resultado da compra    Pagamento recusado.

CT-10 - Consultar timeout preserva a tentativa pendente
    [Tags]    pagamento    local    timeout    consulta    CT-10
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    E confirmo o pedido com pagamento    timeout
    E a tentativa deve ter o status    Resultado desconhecido
    ${antes}=    Get Text    css=#order-result
    Quando consulto a tentativa
    Então o resultado completo deve continuar igual    ${antes}
    E deve haver uma única tentativa de pagamento

CT-10 - Reenviar timeout não cria segunda tentativa
    [Tags]    pagamento    local    timeout    idempotencia    CT-10
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    E confirmo o pedido com pagamento    timeout
    E a tentativa deve ter o status    Resultado desconhecido
    ${antes}=    Get Text    css=#order-result
    Quando confirmo novamente sem alterar o carrinho
    Então o resultado completo deve continuar igual    ${antes}
    E deve haver uma única tentativa de pagamento

CT-10 - Resolver timeout preservando o mesmo pedido
    [Tags]    pagamento    local    timeout    CT-10
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    E confirmo o pedido com pagamento    timeout
    ${pedido}=    Identificar pedido exibido
    Quando resolvo o timeout simulado
    Então a tentativa deve ter o status    Confirmado
    E o identificador do pedido deve ser    ${pedido}
    E deve haver uma única tentativa de pagamento
    E o controle de resolver timeout deve desaparecer

CT-11 - Repetir confirmação retorna o mesmo pedido aprovado
    [Tags]    pagamento    local    idempotencia    CT-11
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    E confirmo o pedido com pagamento    approved
    ${antes}=    Get Text    css=#order-result
    Quando confirmo novamente sem alterar o carrinho
    Então o resultado completo deve continuar igual    ${antes}
    E deve haver uma única tentativa de pagamento

CT-09 - Iniciar nova tentativa após recusa
    [Tags]    pagamento    local    recuperacao    CT-09
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    E confirmo o pedido com pagamento    declined
    ${anterior}=    Identificar pedido exibido
    Quando inicio uma nova tentativa aprovada
    Então a tentativa deve ter o status    Confirmado
    ${novo}=    Identificar pedido exibido
    Should Not Be Equal As Strings    ${anterior}    ${novo}
    E deve haver uma única tentativa de pagamento

CT-14 - Concluir compra simulada usando teclado
    [Documentation]    Percurso funcional por teclado; não é uma auditoria completa de acessibilidade.
    [Tags]    pagamento    local    teclado    CT-14
    Dado que estou na Loja Aurora
    Quando adiciono a mochila e aplico o cupom pelo teclado
    E confirmo a compra pelo teclado
    Então a tentativa deve ter o status    Confirmado
    E deve haver uma única tentativa de pagamento

*** Keywords ***
Preparar loja descartável
    ${url}=    Iniciar loja local
    Set Suite Variable    ${URL_LOCAL}    ${url}
    Abrir navegador da suíte

Encerrar ambiente local
    TRY
        Encerrar navegador da suíte
    FINALLY
        Encerrar loja local
    END

Abrir loja local de teste
    Abrir navegador de teste    ${URL_LOCAL}

confirmo o pedido com pagamento
    [Arguments]    ${modo}
    Click    css=#checkout-lab > summary
    Select Options By    css=#payment-mode    value    ${modo}
    Click    css=#checkout
    Get Element States    css=#checkout    contains    enabled
    Get Text    css=#order-result    contains    Pedido:

a tentativa deve ter o status
    [Arguments]    ${status}
    Get Text    css=#order-result    contains    Status: ${status}

deve haver uma única tentativa de pagamento
    Get Text    css=#order-result    contains    Tentativas de pagamento: 1

devo ver o resultado da compra
    [Arguments]    ${mensagem}
    Get Text    css=#purchase-status    contains    ${mensagem}

consulto a tentativa
    Click    css=#consult
    Get Element States    css=#consult    contains    enabled

confirmo novamente sem alterar o carrinho
    Click    css=#checkout
    Get Element States    css=#checkout    contains    enabled

o resultado completo deve continuar igual
    [Arguments]    ${anterior}
    Get Text    css=#order-result    ==    ${anterior}

Identificar pedido exibido
    ${texto}=    Get Text    css=#order-result
    ${pedido}=    Evaluate    $texto.splitlines()[0]
    RETURN    ${pedido}

resolvo o timeout simulado
    Click    css=#resolve
    a tentativa deve ter o status    Confirmado

o identificador do pedido deve ser
    [Arguments]    ${esperado}
    ${atual}=    Identificar pedido exibido
    Should Be Equal As Strings    ${atual}    ${esperado}

o controle de resolver timeout deve desaparecer
    Get Element States    css=#resolve    contains    hidden

inicio uma nova tentativa aprovada
    Click    css=#new-attempt
    Select Options By    css=#payment-mode    value    approved
    Click    css=#checkout
    Get Element States    css=#checkout    contains    enabled

confirmo a compra pelo teclado
    Press Keys    css=#checkout    Enter
    Get Element States    css=#checkout    contains    enabled
    Click    css=#checkout-lab > summary
    a tentativa deve ter o status    Confirmado
