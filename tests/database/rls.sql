-- Synthetic, transactional fixtures. Everything is rolled back, including users.
begin;
insert into auth.users(id,email) values
 ('10000000-0000-4000-8000-000000000001','aurora-a@example.invalid'),
 ('10000000-0000-4000-8000-000000000002','aurora-b@example.invalid');
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated","is_anonymous":false}',true);
do $$
declare q jsonb; first_order jsonb; repeated jsonb;
begin
 q:=public.checkout_quote('[{"sku":"AUR-004","quantity":1}]',' aurora10 ');
 if (q->>'discount')::integer<>1001 or (q->>'total')::integer<>10004 then raise exception 'FAIL: rounding'; end if;
 first_order:=public.checkout_place('[{"sku":"AUR-003","quantity":1}]','AURORA10','timeout','fixture-key-0001');
 repeated:=public.checkout_place('[{"sku":"AUR-003","quantity":1}]','AURORA10','timeout','fixture-key-0001');
 if first_order->>'id'<>repeated->>'id' or repeated->>'payment_attempts'<>'1' then raise exception 'FAIL: idempotency'; end if;
 if first_order->>'status'<>'pending' then raise exception 'FAIL: pending'; end if;
 begin
  perform public.checkout_place('[{"sku":"AUR-003","quantity":2}]','AURORA10','timeout','fixture-key-0001');
  raise exception 'FAIL: conflict accepted';
 exception when unique_violation then null; end;
 repeated:=public.checkout_resolve('fixture-key-0001');
 if repeated->>'status'<>'confirmed' or repeated->>'payment_attempts'<>'1' then raise exception 'FAIL: resolution'; end if;
 if (select count(*) from public.orders)<>1 then raise exception 'FAIL: own read'; end if;
 begin
  insert into public.orders(user_id,key,fingerprint,items,subtotal,discount,shipping,total,coupon,status) values(auth.uid(),'forged-key-0001','{}','[]',1,0,0,1,'','confirmed');
  raise exception 'FAIL: direct insert accepted';
 exception when insufficient_privilege then null; end;
 begin
  update public.orders set total=1;
  raise exception 'FAIL: direct update accepted';
 exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000002","role":"authenticated","is_anonymous":false}',true);
do $$
declare second_order jsonb;
begin
 if (select count(*) from public.orders)<>0 then raise exception 'FAIL: cross-user visibility'; end if;
 begin
  perform public.checkout_resolve('fixture-key-0001');
  raise exception 'FAIL: cross-user resolution';
 exception when raise_exception then if sqlerrm not like 'NOT_FOUND:%' then raise; end if; end;
 second_order:=public.checkout_place('[{"sku":"AUR-003","quantity":1}]','','declined','fixture-key-0001');
 if second_order->>'user_id'<>auth.uid()::text or second_order->>'status'<>'declined' then raise exception 'FAIL: user ownership'; end if;
 if (select count(*) from public.orders)<>1 then raise exception 'FAIL: B own read'; end if;
end $$;
set local role anon;
select set_config('request.jwt.claims','{"role":"anon"}',true);
do $$
begin
 if (select count(*) from public.products)<>4 then raise exception 'FAIL: anonymous catalog'; end if;
 begin
  perform * from public.orders;
  raise exception 'FAIL: anonymous orders';
 exception when insufficient_privilege then null; end;
 begin
  perform public.checkout_place('[{"sku":"AUR-003","quantity":1}]','','approved','fixture-key-0001');
  raise exception 'FAIL: anonymous placement';
 exception when insufficient_privilege then null; end;
end $$;
reset role;
select 'PASS: rounding, idempotency, conflict, timeout, RLS A/B, immutable orders, anonymous denial' as result;
rollback;
