Language: pt

*** Settings ***
Documentation       CT-01: validar cupom, frete e total na interface pública da Loja Aurora.
Resource            resources/loja.resource
Test Setup          Abrir navegador de teste
Test Teardown       Encerrar navegador de teste

*** Test Cases ***
CT-01 - Aplicar desconto na compra de uma mochila
    [Documentation]    R$ 100,00 - R$ 10,00 de desconto + R$ 10,00 de frete = R$ 100,00.
    [Tags]    checkout    cupom    smoke    CT-01
    Dado que estou na Loja Aurora
    Quando adiciono uma Mochila Aurora ao carrinho
    E aplico o cupom AURORA10
    Então o subtotal deve ser R$ 100,00
    E o desconto deve ser R$ 10,00
    E o frete deve ser R$ 10,00
    E o total deve ser R$ 100,00
