import {test,before,after} from 'node:test';
import assert from 'node:assert/strict';
import {once} from 'node:events';
import {createApp} from '../../sut/server.mjs';
let app,base;
before(async()=>{app=createApp();app.listen(0,'127.0.0.1');await once(app,'listening');base=`http://127.0.0.1:${app.address().port}`;});
after(async()=>{app.closeAllConnections();await new Promise(resolve=>app.close(resolve));});
const cart={items:[{sku:'AUR-003',quantity:1}],coupon:'AURORA10',paymentMode:'approved'};
const post=(path,data=cart,key=crypto.randomUUID())=>fetch(base+path,{method:'POST',headers:{'Content-Type':'application/json','Idempotency-Key':key},body:JSON.stringify(data)});

test('alvo e catálogo disponíveis',async()=>{
 assert.equal((await fetch(base+'/health')).status,200);
 assert.match(await(await fetch(base+'/')).text(),/Loja Aurora/);
 assert.equal((await(await fetch(base+'/api/catalog')).json()).length,4);
});
test('CT-01/08: API recalcula valores sem confiar no cliente',async()=>{
 const response=await post('/api/quote',{...cart,total:1});assert.equal(response.status,200);
 assert.equal((await response.json()).total,10000);assert.ok(response.headers.get('x-correlation-id'));
});
test('CT-12: solicitações concorrentes não repetem tentativa',async()=>{
 const key=crypto.randomUUID();const responses=await Promise.all([post('/api/orders',cart,key),post('/api/orders',cart,key)]);
 assert.deepEqual(responses.map(r=>r.status).sort(),[200,201]);
 const orders=await Promise.all(responses.map(r=>r.json()));assert.equal(orders[0].id,orders[1].id);
 const observed=await(await fetch(base+'/api/attempts/'+key)).json();assert.equal(observed.paymentAttempts,1);
});
test('CT-13: mudança de conteúdo com a mesma chave dá conflito',async()=>{
 const key=crypto.randomUUID();await post('/api/orders',cart,key);
 const response=await post('/api/orders',{...cart,items:[{sku:'AUR-003',quantity:2}]},key);
 assert.equal(response.status,409);assert.equal((await response.json()).error.code,'IDEMPOTENCY_CONFLICT');
 assert.equal((await(await fetch(base+'/api/attempts/'+key)).json()).total,10000);
});
test('CT-10: timeout, consulta e resolução explícita',async()=>{
 const key=crypto.randomUUID(),input={...cart,paymentMode:'timeout'};
 const first=await post('/api/orders',input,key);assert.equal(first.status,202);const order=await first.json();
 assert.equal((await(await fetch(base+'/api/attempts/'+key)).json()).status,'pending');
 const resolved=await(await fetch(base+'/api/attempts/'+key+'/resolve',{method:'POST'})).json();
 assert.equal(resolved.id,order.id);assert.equal(resolved.status,'confirmed');assert.equal(resolved.paymentAttempts,1);
 assert.equal((await(await post('/api/orders',input,key)).json()).id,order.id);
});
test('CT-06/07: requisição inválida não reserva a chave',async()=>{
 const key=crypto.randomUUID();assert.equal((await post('/api/orders',{...cart,items:[]},key)).status,422);
 assert.equal((await fetch(base+'/api/attempts/'+key)).status,404);
 assert.equal((await post('/api/orders',cart,key)).status,201);
});
test('erros de protocolo e origem',async()=>{
 const invalid=await fetch(base+'/api/quote',{method:'POST',headers:{'Content-Type':'application/json'},body:'{'});
 assert.equal(invalid.status,400);assert.equal((await invalid.json()).error.code,'INVALID_JSON');
 assert.equal((await fetch(base+'/api/quote',{method:'POST',body:'text'})).status,415);
 assert.equal((await fetch(base+'/api/orders',{method:'POST',headers:{Origin:'https://example.com','Content-Type':'application/json'},body:JSON.stringify(cart)})).status,403);
});
