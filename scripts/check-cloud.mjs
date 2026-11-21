import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const local=await readFile(new URL('../.env.local',import.meta.url),'utf8').catch(()=>'');
const settings=Object.fromEntries(local.split(/\r?\n/).filter(line=>/^[A-Z_]+=/.test(line)).map(line=>{const i=line.indexOf('=');return [line.slice(0,i),line.slice(i+1).trim()];}));
const url=process.env.VITE_SUPABASE_URL||settings.VITE_SUPABASE_URL;
const key=process.env.VITE_SUPABASE_PUBLISHABLE_KEY||settings.VITE_SUPABASE_PUBLISHABLE_KEY;
assert.ok(url?.startsWith('https://'));assert.ok(key?.startsWith('sb_publishable_'));
const headers={apikey:key,'Content-Type':'application/json'};
async function request(path,body){return fetch(url+'/rest/v1/'+path,{method:body?'POST':'GET',headers,body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(20000)});}
const catalog=await request('products?select=sku,price');assert.equal(catalog.status,200);assert.equal((await catalog.json()).length,4);
const quote=await request('rpc/checkout_quote',{p_items:[{sku:'AUR-004',quantity:1,price:1}],p_coupon:' aurora10 '});assert.equal(quote.status,200);const value=await quote.json();assert.equal(value.discount,1001);assert.equal(value.total,10004);
const denied=await request('orders?select=id');assert.ok([401,403].includes(denied.status));
const placement=await request('rpc/checkout_place',{p_items:[{sku:'AUR-003',quantity:1}],p_coupon:'',p_mode:'approved',p_key:'anonymous-check-001'});assert.ok([401,403].includes(placement.status));
console.log('PASS: catálogo público, cálculo remoto, adulteração ignorada, leitura e confirmação anônimas negadas. Nenhum pedido criado.');
