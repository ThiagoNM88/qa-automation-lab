# Primeiros testes de interface com Robot Framework

## Executar no seu computador

No terminal do VS Code, na raiz `qa-automation-lab`, execute:

```powershell
npm run test:robot
```

O ambiente Python deste computador já foi configurado. Esse comando abre uma janela independente do Chrome, executa os cenários e fecha o navegador ao terminar. Não precisa iniciar um servidor local manualmente nem fazer login na loja. O teste de pagamentos inicia seu próprio simulador.

A suíte de checkout usa a **versão publicada** da Loja Aurora; a suíte de pagamentos usa o simulador Node local. Alterar um arquivo local não muda automaticamente a página testada. É necessário acesso à internet; a disponibilidade da Vercel e do Supabase pode afetar o resultado.

Resultado esperado:

```text
28 tests, 28 passed, 0 failed
```

Depois, abra `results/robot/report.html` no navegador para ver o resumo. `results/robot/log.html` mostra cada passo, seus argumentos e a captura de tela. Esses arquivos são gerados, ficam fora do Git e são substituídos a cada execução.

Para executar sem mostrar a janela:

```powershell
npm run test:robot -- --headless
```

Para reproduzir o alvo usado pelo GitHub Actions, sem depender da loja publicada:

```powershell
npm run test:robot -- --headless --local
```

Esse modo inicia os servidores necessários automaticamente e valida a interface do código local. Não valida Supabase Auth nem a integração na nuvem.

## O que esses testes comprovam

Uma Mochila Aurora custa R$ 100,00. O cupom AURORA10 concede R$ 10,00 de desconto; o frete custa R$ 10,00. O total esperado é R$ 100,00. Antes do cupom, o teste também verifica o total de R$ 110,00.

Os cenários estão em `tests/robot/checkout.robot`, escrito com Dado, Quando e Então. Os passos executáveis estão em `tests/robot/resources/loja.resource`: abrir a página, clicar, preencher o cupom e conferir os valores. Não há pausas fixas para aguardar respostas: as verificações aguardam o resultado esperado até um limite de tempo. A execução com janela usa movimentos mais lentos apenas para facilitar acompanhar os cliques.

A suíte foi revisada para 28 casos regulares, incluindo negativos, fronteiras, limpeza, teclado e pagamentos locais simulados. Cada caso começa em um contexto independente e não usa sua sessão pessoal do Chrome. Login e finalização autenticada no Supabase continuam fora da cobertura. Consulte [a matriz de cenários, alvos e limites](cobertura-robot.md) antes de interpretar os resultados.

Os 16 testes Node continuam separados, executados por `npm test`. O Robot não substitui essa cobertura.

## Por que .robot e não .feature?

Robot Framework aceita cenários em estilo BDD com prefixos Dado/Quando/Então e palavras-chave reutilizáveis. Esse arquivo usa a sintaxe nativa do Robot; não é um arquivo Gherkin executado por Cucumber. O comportamento do negócio está no cenário e os detalhes de interação ficam no resource.

## Instalar em outro computador Windows

Requisitos: Python 3.12, Node.js compatível com a Browser Library e Google Chrome instalado. Na raiz do repositório:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-robot.txt
.\.venv\Scripts\python.exe -m Browser.entry init --skip-browsers
npm run test:robot
```

Usamos a instalação com Node existente e o canal `chrome`. Não é necessário o pacote opcional BrowserBatteries nem baixar outro navegador. As versões diretas de Robot e Browser estão fixadas em `requirements-robot.txt`. Ambiente virtual, dependências e resultados não devem ser enviados ao GitHub.

Neste computador, uma tentativa anterior com BrowserBatteries esbarrou no limite de caminhos do Windows. A instalação incompleta foi guardada com o nome `_BrowserBatteries_incomplete` dentro de `.venv` e não é utilizada. Não houve alteração de configurações do Windows. Uma instalação nova seguindo os comandos acima não inclui esse pacote.

Se uma versão recente do npm informar que scripts de instalação foram bloqueados, consulte a orientação oficial e revise o pacote indicado antes de aprová-lo. Não desative as verificações globalmente.

Referências: [instalação da Browser Library](https://robotframework-browser.org/docs/start/installation/) e [Robot Framework](https://robotframework.org/).
