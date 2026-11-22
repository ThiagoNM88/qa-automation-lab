Language: pt

*** Settings ***
Documentation       Validar cupom, valores e limpeza do carrinho na interface pública da Loja Aurora.
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
