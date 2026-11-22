Language: pt

*** Settings ***
Documentation       Validar cupom, valores e limpeza do carrinho na interface pública da Loja Aurora.
Resource            resources/loja.resource
Suite Setup         Abrir navegador da suíte
Suite Teardown      Encerrar navegador da suíte
Test Setup          Abrir navegador de teste
Test Teardown       Encerrar navegador de teste

*** Test Cases ***
CT-01 - Calcular total da compra com cupom
    [Documentation]    R$ 100,00 - R$ 10,00 de desconto + R$ 10,00 de frete = R$ 100,00.
    [Tags]    checkout    cupom    smoke    CT-01
    Dado que estou na Loja Aurora
    Quando adiciono uma Mochila Aurora ao carrinho
    E aplico o cupom AURORA10
    Então o subtotal deve ser R$ 100,00
    E o desconto deve ser R$ 10,00
    E o frete deve ser R$ 10,00
    E o total deve ser R$ 100,00

CT-15 - Limpar carrinho com produto e cupom aplicado
    [Documentation]    Remover todos os itens e o cupom, zerar valores e impedir a finalização vazia.
    [Tags]    checkout    carrinho    smoke    CT-15
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    E aplico o cupom AURORA10
    Quando limpo o carrinho
    Então o carrinho deve ficar vazio
    E o cupom deve ser removido
    E todos os valores da compra devem ficar zerados
    E a finalização do pedido deve ficar indisponível

CT-16 - Digitar cupom inválido
    [Documentation]    Rejeitar cupom desconhecido, avisar o usuário e manter o total sem desconto.
    [Tags]    checkout    cupom    negativo    CT-16
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    Quando tento aplicar o cupom    INVALIDO
    Então devo ver o aviso    Cupom não reconhecido.
    E nenhum cupom deve estar aplicado
    E os valores da compra devem ser    100,00    0,00    10,00    110,00

CT-03 - Arredondar desconto de meio centavo para cima
    [Tags]    cupom    arredondamento    CT-03
    Dado que estou na Loja Aurora
    Quando adiciono o produto ao carrinho    Kit Aurora
    E aplico o cupom AURORA10
    Então os valores da compra devem ser    100,05    10,01    10,00    100,04

CT-04 - Frete grátis usa o subtotal antes do desconto
    [Tags]    frete    fronteira    CT-04
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    Quando altero a quantidade da mochila para    2
    E aplico o cupom AURORA10
    Então os valores da compra devem ser    200,00    20,00    0,00    180,00

CT-04 - Cobrar frete um centavo abaixo do mínimo
    [Tags]    frete    fronteira    CT-04
    Dado que estou na Loja Aurora
    Quando monto um carrinho de R$ 199,99
    E aplico o cupom AURORA10
    Então os valores da compra devem ser    199,99    20,00    10,00    189,99

CT-02 - Rejeitar cupom um centavo abaixo do mínimo
    [Tags]    cupom    fronteira    negativo    CT-02
    Dado que estou na Loja Aurora
    Quando monto um carrinho de R$ 99,99
    E tento aplicar o cupom    AURORA10
    Então devo ver o aviso    O cupom exige subtotal de pelo menos R$100,00.
    E nenhum cupom deve estar aplicado
    E os valores da compra devem ser    99,99    0,00    10,00    109,99

CT-05 - Normalizar espaços e letras do cupom
    [Tags]    cupom    normalizacao    CT-05
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    Quando tento aplicar o cupom    ${SPACE}aurora10${SPACE}
    Então o cupom válido deve estar aplicado
    E os valores da compra devem ser    100,00    10,00    10,00    100,00

CT-05 - Preservar desconto válido ao rejeitar outro cupom
    [Tags]    cupom    negativo    preservacao    CT-05
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    E aplico o cupom AURORA10
    Quando tento aplicar o cupom    INVALIDO
    Então devo ver o aviso    Cupom não reconhecido.
    E o cupom válido deve estar aplicado
    E os valores da compra devem ser    100,00    10,00    10,00    100,00

CT-06 - Aceitar quantidade máxima de cinco unidades
    [Tags]    quantidade    fronteira    CT-06
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    Quando altero a quantidade da mochila para    5
    Então os valores da compra devem ser    500,00    0,00    0,00    500,00
    E a finalização do pedido deve estar disponível

CT-06 - Rejeitar quantidade zero
    [Tags]    quantidade    negativo    CT-06
    [Template]    Rejeitar quantidade inválida
    0

CT-06 - Rejeitar quantidade negativa
    [Tags]    quantidade    negativo    CT-06
    [Template]    Rejeitar quantidade inválida
    -1

CT-06 - Rejeitar quantidade acima do máximo
    [Tags]    quantidade    negativo    CT-06
    [Template]    Rejeitar quantidade inválida
    6

CT-06 - Rejeitar quantidade fracionária
    [Tags]    quantidade    negativo    CT-06
    [Template]    Rejeitar quantidade inválida
    1.5

CT-06 - Rejeitar campo de quantidade vazio
    [Tags]    quantidade    negativo    CT-06
    [Template]    Rejeitar quantidade inválida
    ${EMPTY}

CT-06 - Recuperar checkout após corrigir quantidade inválida
    [Tags]    quantidade    recuperacao    CT-06
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    E altero a quantidade da mochila para    6
    E devo ver o aviso    A quantidade deve ser inteira, de 1 a 5.
    E a finalização do pedido deve ficar indisponível
    Quando altero a quantidade da mochila para    1
    Então os valores da compra devem ser    100,00    0,00    10,00    110,00
    E a finalização do pedido deve estar disponível

CT-07 - Impedir finalização do carrinho inicialmente vazio
    [Tags]    carrinho    negativo    CT-07
    Dado que estou na Loja Aurora
    Quando abro o carrinho
    Então o carrinho deve ficar vazio
    E a finalização do pedido deve ficar indisponível

CT-07 - Remover o último produto do carrinho
    [Tags]    carrinho    remocao    CT-07
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    Quando removo a mochila do carrinho
    Então o carrinho deve ficar vazio
    E todos os valores da compra devem ficar zerados
    E a finalização do pedido deve ficar indisponível

CT-05 - Remover cupom mantendo os produtos
    [Tags]    cupom    remocao    CT-05
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    E aplico o cupom AURORA10
    Quando removo o cupom aplicado
    Então nenhum cupom deve estar aplicado
    E os valores da compra devem ser    100,00    0,00    10,00    110,00
    E a finalização do pedido deve estar disponível

CT-14 - Aplicar cupom usando teclado
    [Documentation]    Verificação parcial de teclado; não comprova conformidade integral de acessibilidade.
    [Tags]    teclado    acessibilidade-parcial    CT-14
    Dado que estou na Loja Aurora
    Quando adiciono a mochila e aplico o cupom pelo teclado
    Então os valores da compra devem ser    100,00    10,00    10,00    100,00
