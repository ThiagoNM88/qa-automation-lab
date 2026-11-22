# Cenários coesos e demonstração de pipeline reprovada

## Revisão dos comportamentos

A suíte regular passou de 25 para 28 casos (20 de checkout e 8 de pagamentos). O objetivo foi separar ações independentes, preservando as verificações relacionadas ao mesmo resultado.

| Antes | Agora |
| --- | --- |
| Normalizar cupom e depois rejeitar outro código no mesmo teste | Um cenário de normalização; outro de preservação do desconto válido |
| Rejeitar e corrigir cada uma das cinco quantidades inválidas | Cinco casos de rejeição; um cenário específico de recuperação após correção |
| Consultar e reenviar timeout no mesmo cenário | Um cenário de consulta; outro de reenvio sem duplicar a tentativa |

O CT-01 foi renomeado para deixar explícito seu objetivo: calcular o total da compra com cupom. Subtotal, desconto, frete e total continuam sendo verificados porque explicam a composição do valor final. Limpar carrinho também mantém as verificações de itens, cupom, contador, valores e finalização: são consequências da mesma ação.

Ter um comportamento por cenário não significa ter apenas uma asserção. A revisão busca coesão, isolamento e facilidade de diagnóstico.

## Duas falhas controladas

Arquivo: `examples/falhas-controladas.robot`. Os exemplos não são carregados pelo comando normal. Eles entram somente quando usamos `--demo-falhas`.

1. **DEMO-01:** o frete correto é R$0,00 para subtotal de R$200,00. O teste exige propositalmente R$10,00. A falha deve mostrar a divergência entre encontrado e esperado. É uma expectativa errada do exercício, não um defeito da loja.
2. **DEMO-02:** o teste tenta clicar em `#botao-inexistente-demonstracao`. A falha deve mostrar o timeout de procura do elemento. A validação funcional nem chega a acontecer.

Na branch `test/cenarios-coesos`, o workflow foi configurado intencionalmente com `--demo-falhas`. Portanto, a primeira etapa de unidade/API deve passar; o job Robot e o workflow devem reprovar. O upload usa `if: always()` e deve preservar relatórios e capturas mesmo assim. Não há `continue-on-error` para transformar a falha em aprovação.

Essa configuração não foi incorporada à main. A branch principal mantém a configuração aprovada anterior.

## Comandos e resultados esperados

Suíte regular, sem as falhas controladas:

```powershell
npm run test:robot -- --headless --local
```

Esperado: **28 casos aprovados, nenhuma falha**.

Exercício de falhas, igual ao workflow desta branch:

```powershell
npm run test:robot -- --headless --local --demo-falhas
```

Esperado: **30 casos, 28 aprovados e 2 falhas intencionais**. O comando termina com código diferente de zero. Isso deve reprovar a etapa na pipeline, sem impedir a tentativa de upload das evidências.

No GitHub, abra o job Robot, localize os dois DEMO nos logs e baixe o artefato `robot-...`. Extraia o ZIP e abra `log.html`. Compare a mensagem da asserção de valor com a mensagem do seletor inexistente. Expanda o teardown para ver a captura correspondente a cada cenário.

## Depois do exercício

Para voltar a uma pipeline verde, remova apenas `--demo-falhas` da linha de execução em `.github/workflows/qa.yml` e envie o novo commit. Os exemplos podem permanecer no repositório para execução manual; o comando normal não os inclui. Antes de integrar esta revisão à main, desative a demonstração e confirme a execução verde.
