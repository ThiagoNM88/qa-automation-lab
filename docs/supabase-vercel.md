# Loja Aurora na nuvem — Supabase e Vercel Hobby

## Arquitetura

Interface estática construída pelo Vite e preparada para Vercel Hobby. Supabase Auth identifica o usuário; Postgres calcula valores, guarda tentativas e aplica isolamento por usuário. Não utiliza API de IA, gateway financeiro ou servidor Node persistente na Vercel.

O alvo Node original permanece em `sut/` para testes locais independentes. `scripts/prepare-web.mjs` reaproveita esse template e substitui o adaptador HTTP pelo cliente Supabase. Os arquivos `web/index.html` e `web/generated-checkout.js` são gerados; alterar o template e os adaptadores, não os arquivos gerados.

## Banco já provisionado

- Organização: ThiagoNM, plano Free.
- Projeto: qa-automation-lab, região sa-east-1.
- Migração hospedada: aurora_checkout_v1; fonte em `supabase/schema.sql`.
- `products`: leitura de catálogo para anon/authenticated; sem escrita pelo navegador.
- `orders`: leitura apenas pelo dono com RLS. Inserção/atualização direta negadas.
- RPCs `checkout_quote`, `checkout_place`, `checkout_resolve`: cálculo e mutação com validação no banco.
- Rotinas de escrita privilegiadas ficam no schema não exposto `private`, com checagem explícita de `auth.uid()` e rejeição de usuários anônimos do Auth. Wrappers públicos são invoker e exigem o papel adequado.
- Unicidade por usuário/chave e bloqueio transacional por conflito impedem duplicação no banco. São permitidas até 100 tentativas por usuário neste laboratório.

Valores de preço/total do cliente não são usados no cálculo. Timeout só é resolvido por controle didático explícito. Pedidos sobrevivem a reinício do frontend.

## Instalação e build

Requer Node.js 22.13+; dependências fixadas e lockfile versionado.

```powershell
npm ci
Copy-Item .env.example .env.local
# Preencher somente URL do projeto e chave publishable no arquivo ignorado.
npm run build
```

As variáveis são públicas por definição do frontend. Nunca usar chave secret, service_role ou senha de banco nessas variáveis. A segurança depende das permissões do banco e RLS.

`npm start` abre o simulador Node antigo. `npm run dev` abre a versão integrada ao Supabase. O build exige configuração válida; não publica silenciosamente uma integração vazia.

## Publicação Vercel Hobby

1. Importar o repositório qa-automation-lab na conta pessoal Hobby.
2. Usar a branch que contém esta implementação; não publicar a main antiga que contém apenas documentação.
3. Build `npm run build`, diretório de saída `dist`, raiz do repositório.
4. Definir `VITE_SUPABASE_URL` e `VITE_SUPABASE_PUBLISHABLE_KEY` no ambiente do projeto.
5. Publicar e usar o domínio gratuito da Vercel.
6. Em Supabase Auth URL Configuration, configurar Site URL e redirecionamento permitido para a URL publicada. Evitar curingas amplos de domínios não controlados.

O arquivo vercel.json registra o build e cabeçalhos básicos. Não usa Functions da Vercel. Manter o Hobby para uso pessoal/não comercial e sem testes de carga ou segurança ofensiva na hospedagem compartilhada.

## Login e e-mail: configuração pendente

A aplicação contém login, cadastro, logout e histórico. A senha é enviada apenas ao Supabase Auth, não ao banco de pedidos. Confirmação de e-mail permanece sujeita à configuração do projeto; não foi desabilitada.

O SMTP padrão do Supabase só envia a endereços autorizados dos membros da organização e tem limites baixos. Não anunciar cadastro público irrestrito. Para permitir visitantes gerais, configurar um SMTP próprio com plano gratuito disponível, ou adicionar um provedor social mediante configuração e autorização separadas. Não armazenar chaves desse provedor no frontend.

O primeiro acesso real exige que o usuário crie sua conta, confirme o e-mail e faça login. A validação desse fluxo e dos redirecionamentos está pendente da publicação e da configuração do Auth.

## Verificações

- `npm test`: suíte original, 16 testes Node.
- `npm run build`: integração e bundle de produção.
- `node scripts/check-cloud.mjs`: leitura de catálogo, cálculo e negação anônima via API real, sem criar pedidos.
- `tests/database/rls.sql`: fixtures A/B em transação com rollback; valida leitura por dono, bloqueio de escrita direta, reenvio, conflito e timeout. Executar somente em ambiente autorizado de estudo. Não deixar fixtures persistidas.
- Advisors de segurança do projeto após a migração: sem alertas observados nesta etapa.

Ainda pendentes: login real, dois usuários reais pela API Auth, navegação/teclado e fluxos Playwright na URL publicada; pipeline GitHub Actions. Testes SQL de identidade não substituem validação de sessão/JWT no navegador.
