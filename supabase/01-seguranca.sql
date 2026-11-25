-- ============================================================
-- Rotina Carol · Passo 1: proteger os dados com login de verdade
-- Rode no Supabase: SQL Editor > New query > cole tudo > Run
-- ANTES: crie seu usuário em Authentication > Users > Add user
--        (marque "Auto Confirm User") e troque o e-mail abaixo.
-- ============================================================

-- 1) Coluna "dono" em cada linha de dados
alter table public.rotina_state
  add column if not exists owner uuid references auth.users(id) default auth.uid();

-- 2) Sua linha atual passa a ser sua (TROQUE O E-MAIL)
update public.rotina_state
   set owner = (select id from auth.users where email = 'SEU-EMAIL-AQUI@exemplo.com')
 where key = 'carol-zapizi';

-- Confere: precisa aparecer 1 linha com owner preenchido
select key, owner, updated_at from public.rotina_state;

-- 3) Liga a proteção por linha e apaga regras antigas (que deixavam qualquer um ler/gravar)
alter table public.rotina_state enable row level security;

do $$
declare p record;
begin
  for p in select policyname from pg_policies
           where schemaname = 'public' and tablename = 'rotina_state'
  loop
    execute format('drop policy %I on public.rotina_state', p.policyname);
  end loop;
end $$;

-- 4) Só a dona (usuária logada) lê, cria e altera a própria linha
create policy "dona le"     on public.rotina_state for select to authenticated using (owner = auth.uid());
create policy "dona cria"   on public.rotina_state for insert to authenticated with check (owner = auth.uid());
create policy "dona altera" on public.rotina_state for update to authenticated using (owner = auth.uid()) with check (owner = auth.uid());

-- 5) Visitantes sem login não têm acesso nenhum
revoke all on public.rotina_state from anon;
