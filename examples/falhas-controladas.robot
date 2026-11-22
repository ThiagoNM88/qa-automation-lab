Language: pt

*** Settings ***
Documentation       EXERCÍCIO: duas falhas intencionais. Não representam defeitos reais da loja.
Resource            ../tests/robot/resources/loja.resource
Suite Setup         Abrir navegador da suíte
Suite Teardown      Encerrar navegador da suíte
Test Setup          Abrir navegador de teste
Test Teardown       Encerrar navegador de teste
Test Tags           demonstracao-falha

*** Test Cases ***
DEMO-01 - Expectativa de frete propositalmente incorreta
    [Documentation]    A regra correta dá frete grátis em R$200; aqui exigimos R$10 para observar uma asserção falhar.
    Dado que estou na Loja Aurora
    E adiciono uma Mochila Aurora ao carrinho
    Quando altero a quantidade da mochila para    2
    Então verifico uma expectativa de frete intencionalmente errada

DEMO-02 - Seletor de botão propositalmente inexistente
    [Documentation]    O botão não existe. O erro deve mostrar a espera pelo seletor, antes de qualquer validação funcional.
    Dado que estou na Loja Aurora
    Quando tento clicar em um botão inexistente na demonstração

*** Keywords ***
verifico uma expectativa de frete intencionalmente errada
    # Primeiro garante que o cálculo real terminou e está correto.
    os valores da compra devem ser    200,00    0,00    0,00    200,00
    # Falha controlada: o valor correto é 0,00. Não é um defeito da aplicação.
    Conferir valor monetário    shipping    10,00

tento clicar em um botão inexistente na demonstração
    Set Browser Timeout    3s
    Click    css=#botao-inexistente-demonstracao
