# APEX COMBAT LEAGUE — publicação Vercel + Supabase

Este pacote mantém o sistema em HTML/CSS/JavaScript e adiciona uma base compartilhada no Supabase. Não precisa de React, Node ou comando de build: a Vercel serve o `index.html` diretamente.

## O que esta versão oferece

- Site público para consultar atletas, eventos, cards, rankings, cinturões e relatos completos das lutas.
- Inscrição pública de personagens; candidaturas ficam pendentes até a aprovação administrativa.
- Login administrativo via Supabase Auth, com whitelist `acl_admins`.
- Área administrativa para cadastrar/editar/excluir atletas, eventos e lutas; simular resultados; aprovar/recusar inscrições e exportar/importar backups.
- Dados oficiais da liga salvos na tabela `acl_state` e compartilhados entre navegadores.
- Proteção de banco via Row Level Security (RLS): a chave pública do site não autoriza operações administrativas.

> **Importante:** a temporada (elenco + eventos + resultados) está armazenada em um único documento JSONB para reaproveitar a lógica do sistema existente. Use uma sessão administrativa para editar a temporada de cada vez; duas pessoas editando ao mesmo tempo podem sobrescrever alterações concorrentes. Para uma equipe grande, o próximo passo seria normalizar atletas, eventos e lutas em tabelas separadas.

## Etapa 1 — criar o projeto Supabase

1. Acesse https://supabase.com/ e crie um projeto.
2. Abra **Project Settings → API Keys** (ou o diálogo **Connect**).
3. Copie a **Project URL** e a chave **Publishable** que começa com `sb_publishable_`.
4. Abra `config.js` e substitua os dois valores de exemplo:

```js
window.ACL_CONFIG = {
  supabaseUrl: "https://SEU-PROJETO.supabase.co",
  supabasePublishableKey: "sb_publishable_SUA_CHAVE"
};
```

A chave Publishable foi feita para uso no navegador; quem controla as permissões é o RLS. **Nunca use a chave Secret (`sb_secret_...`) nem a antiga `service_role` no `config.js`, no HTML ou em repositório público.**

## Etapa 2 — criar as tabelas e políticas

1. No painel Supabase, abra **SQL Editor → New query**.
2. Abra o arquivo `supabase-setup.sql` deste pacote, copie todo o conteúdo e cole na query.
3. Execute (`Run`).
4. Confira em **Table Editor** se existem `acl_state`, `acl_admins` e `acl_applications`.

O SQL cria as regras RLS. Não desative RLS para “fazer funcionar”; corrija URL, chave, grants ou policies caso algo falhe.

## Etapa 3 — criar sua conta administrativa

1. No Supabase, abra **Authentication → Users → Add user**.
2. Crie um usuário com o seu e-mail e uma senha forte. Não crie um formulário público para administradores.
3. Copie o **User UID** desse usuário.
4. No SQL Editor, execute a query abaixo, substituindo os dois valores:

```sql
insert into public.acl_admins (user_id, email)
values ('COLE-AQUI-O-USER-UID', 'seu-email@exemplo.com')
on conflict (user_id) do update set email = excluded.email;
```

A whitelist é o que distingue uma conta autenticada comum do administrador da liga. Fazer login sem estar nessa tabela não libera o painel.

## Etapa 4 — enviar ao GitHub

1. Extraia o pacote, se estiver usando o ZIP.
2. Crie um repositório no https://github.com/ (por exemplo, `apex-combat-league`).
3. Envie os arquivos desta pasta diretamente para a raiz do repositório: `index.html`, `config.js`, `config.example.js`, `supabase-setup.sql` e `README.md`.
4. `config.js` contém somente a URL e a chave **Publishable**, que são próprias para cliente. Nunca adicione uma chave Secret ao projeto.

## Etapa 5 — publicar na Vercel

1. Acesse https://vercel.com/ e escolha **Add New → Project**.
2. Importe o repositório GitHub da ACL.
3. Use estas opções:
   - **Framework Preset:** Other
   - **Build Command:** vazio
   - **Output Directory:** `.`
   - **Install Command:** vazio / padrão, sem dependências
4. Clique em **Deploy**.
5. Abra o domínio `.vercel.app` disponibilizado.

Após alterar `config.js` ou o código e enviar um commit ao GitHub, a Vercel publica uma nova implantação automaticamente.

## Etapa 6 — primeiro acesso e migração de dados

1. No endereço público, clique em **Entrar como administrador**.
2. Use o e-mail e a senha criados na Etapa 3.
3. No primeiro login, se `acl_state` ainda estiver vazio, o sistema inicializa a liga com o elenco base fictício.
4. Para importar a temporada que você já tinha no HTML antigo, abra **Dados & backup → Importar backup JSON** e selecione um backup exportado do site antigo. Faça isso somente depois de entrar como administrador.
5. Depois da importação, confira alguns atletas, um evento, os rankings e os relatos. Exporte um novo backup como ponto de recuperação.

## Checklist de teste antes de divulgar

- [ ] Abrir a página em uma janela anônima: deve mostrar apenas o site público, sem ferramentas administrativas.
- [ ] Enviar uma inscrição teste.
- [ ] Entrar como administrador e verificar se a ficha apareceu em **Inscrições**.
- [ ] Aprovar a ficha e confirmar que o atleta aparece no elenco.
- [ ] Criar uma Fight Night e conferir que o site bloqueia disputas de cinturão.
- [ ] Simular resultados, abrir o relato completo e confirmar o ranking.
- [ ] Excluir um evento de teste e confirmar que o ranking/cinturões são recalculados.
- [ ] Abrir o site em outro navegador: as mudanças oficiais devem aparecer após atualizar a página.
- [ ] Sair do painel e confirmar que os controles administrativos desaparecem.

## Observações operacionais

- A tabela `acl_state` contém os dados que você pretende publicar. Não coloque nela senhas, documentos pessoais ou informações privadas.
- A tabela `acl_applications` não permite que visitantes leiam a fila; só administradores autorizados podem consultar/modificar candidaturas.
- Este pacote não tem CAPTCHA; se o site receber muito tráfego público, adicione proteção antispam/rate limit antes de divulgar amplamente.
- A tela pública atualiza ao abrir ou recarregar. Um visitante pode clicar em **Atualizar** na lista de eventos para buscar a versão mais recente.
- O domínio público não tem como ser publicado pelo assistente dentro da sua conta. É necessário você criar/autorizar seus projetos GitHub, Supabase e Vercel com suas próprias credenciais.

## Referências oficiais

- Supabase API keys: https://supabase.com/docs/guides/getting-started/api-keys
- Supabase Row Level Security: https://supabase.com/docs/guides/database/postgres/row-level-security
- Vercel static sites: https://vercel.com/docs/builds
