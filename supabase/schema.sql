-- Source of migration aurora_checkout_v1. Applied through Supabase MCP.
-- Database calculates totals; clients cannot insert/update orders directly.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create table public.products (
 sku text primary key, name text not null,
 price integer not null check(price>0)
);
alter table public.products enable row level security;
create policy catalog_read on public.products for select to anon, authenticated using(true);
revoke all on public.products from anon, authenticated;
grant select on public.products to anon, authenticated;
insert into public.products(sku,name,price) values
 ('AUR-001','Caderno Aurora',4999),('AUR-002','Garrafa Aurora',5000),
 ('AUR-003','Mochila Aurora',10000),('AUR-004','Kit Aurora',10005);

create table public.orders (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 key text not null check(key ~ '^[a-zA-Z0-9_-]{8,100}$'),
 fingerprint jsonb not null, items jsonb not null,
 subtotal integer not null check(subtotal>0),discount integer not null check(discount>=0),
 shipping integer not null check(shipping>=0), total integer not null check(total=subtotal-discount+shipping),
 coupon text not null, status text not null check(status in ('pending','confirmed','declined')),
 payment_attempts integer not null default 1 check(payment_attempts=1),
 created_at timestamptz not null default now(),
 unique(user_id,key)
);
alter table public.orders enable row level security;
create policy own_orders_read on public.orders for select to authenticated using((select auth.uid())=user_id);
revoke all on public.orders from anon, authenticated;
grant select on public.orders to authenticated;
-- The unique(user_id,key) index also supports the RLS ownership lookup.

create function private.calculate_checkout(p_items jsonb,p_coupon text)
returns jsonb language plpgsql security invoker set search_path='' as $$
declare item jsonb; product public.products%rowtype; quantity numeric;
 normalized text:=upper(trim(coalesce(p_coupon,''))); canonical jsonb:='[]';
 seen text[]:='{}'; subtotal integer:=0; discount integer:=0; shipping integer;
begin
 if p_items is null or jsonb_typeof(p_items)<>'array' then raise exception 'EMPTY_CART: Adicione pelo menos um produto.'; end if;
 if jsonb_array_length(p_items)=0 or jsonb_array_length(p_items)>4 then raise exception 'INVALID_ITEMS: Carrinho deve ter de 1 a 4 produtos distintos.'; end if;
 for item in select value from jsonb_array_elements(p_items) order by value->>'sku' loop
  if jsonb_typeof(item)<>'object' or jsonb_typeof(item->'sku') is distinct from 'string' then raise exception 'INVALID_PRODUCT: Produto inválido.'; end if;
  select * into product from public.products where sku=item->>'sku';
  if not found or product.sku=any(seen) then raise exception 'INVALID_PRODUCT: Produto desconhecido ou repetido.'; end if;
  seen:=array_append(seen,product.sku);
  if jsonb_typeof(item->'quantity') is distinct from 'number' then raise exception 'INVALID_QUANTITY: A quantidade deve ser inteira, de 1 a 5.'; end if;
  quantity:=(item->>'quantity')::numeric;
  if quantity<1 or quantity>5 or quantity<>trunc(quantity) then raise exception 'INVALID_QUANTITY: A quantidade deve ser inteira, de 1 a 5.'; end if;
  subtotal:=subtotal+product.price*quantity::integer;
  canonical:=canonical||jsonb_build_array(jsonb_build_object('sku',product.sku,'name',product.name,'price',product.price,'quantity',quantity::integer));
 end loop;
 if normalized<>'' and normalized<>'AURORA10' then raise exception 'INVALID_COUPON: Cupom não reconhecido.'; end if;
 if normalized<>'' and subtotal<10000 then raise exception 'COUPON_MINIMUM: O cupom exige subtotal de pelo menos R$100,00.'; end if;
 if normalized<>'' then discount:=(subtotal+5)/10; end if;
 shipping:=case when subtotal>=20000 then 0 else 1000 end;
 return jsonb_build_object('items',canonical,'subtotal',subtotal,'discount',discount,'shipping',shipping,'total',subtotal-discount+shipping,'coupon',normalized);
end $$;
revoke all on function private.calculate_checkout(jsonb,text) from public,anon,authenticated;
-- Quote wrapper runs as caller and only needs catalog reads.
grant usage on schema private to anon;
grant execute on function private.calculate_checkout(jsonb,text) to anon,authenticated;
create function public.checkout_quote(p_items jsonb,p_coupon text default '')
returns jsonb language sql security invoker set search_path='' as $$
 select private.calculate_checkout(p_items,p_coupon);
$$;
revoke all on function public.checkout_quote(jsonb,text) from public;
grant execute on function public.checkout_quote(jsonb,text) to anon,authenticated;

-- Mutation implementation remains in an unexposed schema. Caller identity is
-- checked here because this deliberately privileged routine bypasses RLS.
create function private.place_order(p_items jsonb,p_coupon text,p_mode text,p_key text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); calculation jsonb; identity_payload jsonb; result public.orders%rowtype;
begin
 if uid is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then raise exception 'AUTH_REQUIRED: Entre na conta para confirmar.' using errcode='42501'; end if;
 if p_key is null or p_key!~'^[a-zA-Z0-9_-]{8,100}$' then raise exception 'INVALID_KEY: Chave inválida.'; end if;
 if p_mode is null or p_mode not in ('approved','declined','timeout') then raise exception 'INVALID_PAYMENT_MODE: Modo inválido.'; end if;
 calculation:=private.calculate_checkout(p_items,p_coupon);
 identity_payload:=jsonb_build_object('items',calculation->'items','coupon',calculation->>'coupon','mode',p_mode);
 -- Serialize only this user's submissions; cross-instance coordination is in Postgres.
 perform pg_advisory_xact_lock(hashtextextended(uid::text,0));
 select * into result from public.orders where user_id=uid and key=p_key;
 if found then
  if result.fingerprint<>identity_payload then raise exception 'IDEMPOTENCY_CONFLICT: A chave já foi usada com outro conteúdo.' using errcode='23505'; end if;
 else
  if (select count(*) from public.orders where user_id=uid)>=100 then raise exception 'LAB_LIMIT: Limite de 100 tentativas por usuário neste laboratório.'; end if;
  insert into public.orders(user_id,key,fingerprint,items,subtotal,discount,shipping,total,coupon,status)
  values(uid,p_key,identity_payload,calculation->'items',(calculation->>'subtotal')::integer,(calculation->>'discount')::integer,(calculation->>'shipping')::integer,(calculation->>'total')::integer,calculation->>'coupon',case p_mode when 'approved' then 'confirmed' when 'declined' then 'declined' else 'pending' end)
  returning * into result;
 end if;
 return to_jsonb(result)-'fingerprint';
end $$;
revoke all on function private.place_order(jsonb,text,text,text) from public,anon,authenticated;
grant execute on function private.place_order(jsonb,text,text,text) to authenticated;
create function public.checkout_place(p_items jsonb,p_coupon text,p_mode text,p_key text)
returns jsonb language sql security invoker set search_path='' as $$ select private.place_order(p_items,p_coupon,p_mode,p_key); $$;
revoke all on function public.checkout_place(jsonb,text,text,text) from public,anon;
grant execute on function public.checkout_place(jsonb,text,text,text) to authenticated;

create function private.resolve_attempt(p_key text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); result public.orders%rowtype;
begin
 if uid is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then raise exception 'AUTH_REQUIRED: Entre na conta.' using errcode='42501'; end if;
 select * into result from public.orders where user_id=uid and key=p_key for update;
 if not found then raise exception 'NOT_FOUND: Tentativa não encontrada.'; end if;
 if result.status='pending' then update public.orders set status='confirmed' where id=result.id and user_id=uid returning * into result; end if;
 return to_jsonb(result)-'fingerprint';
end $$;
revoke all on function private.resolve_attempt(text) from public,anon,authenticated;
grant execute on function private.resolve_attempt(text) to authenticated;
create function public.checkout_resolve(p_key text)
returns jsonb language sql security invoker set search_path='' as $$ select private.resolve_attempt(p_key); $$;
revoke all on function public.checkout_resolve(text) from public,anon;
grant execute on function public.checkout_resolve(text) to authenticated;
