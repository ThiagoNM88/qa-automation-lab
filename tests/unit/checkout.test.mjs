import {test} from 'node:test';
import assert from 'node:assert/strict';
import {totals,quote,createOrderStore} from '../../sut/checkout.mjs';

test('CT-01: desconto e frete compõem total independente',()=>{
 const result=quote({items:[{sku:'AUR-003',quantity:1}],coupon:'AURORA10'});
 assert.deepEqual([result.subtotal,result.discount,result.shipping,result.total],[10000,1000,1000,10000]);
});
test('CT-02: limite mínimo de cupom',()=>{
 assert.throws(()=>totals(9999,'AURORA10'),{code:'COUPON_MINIMUM'});
 assert.equal(totals(10000,'AURORA10').discount,1000);
 assert.equal(totals(10001,'AURORA10').discount,1000);
});
test('CT-03: meio centavo arredonda para cima',()=>{
 const result=quote({items:[{sku:'AUR-004',quantity:1}],coupon:'AURORA10'});
 assert.equal(result.discount,1001);assert.equal(result.total,10004);
});
test('CT-04: frete usa subtotal antes do desconto',()=>{
 assert.deepEqual([19999,20000,20001].map(n=>totals(n,'AURORA10').shipping),[1000,0,0]);
 assert.equal(totals(20000,'AURORA10').total,18000);
});
test('CT-05: normalização e rejeição de cupom',()=>{
 assert.equal(totals(10000,' aurora10 ').coupon,'AURORA10');
 assert.throws(()=>totals(10000,'OUTRO'),{code:'INVALID_COUPON'});
});
test('CT-06: quantidade estrita, inclusive limites',()=>{
 for(const quantity of [0,-1,6,1.5,'1',null])assert.throws(()=>quote({items:[{sku:'AUR-001',quantity}]}),{code:'INVALID_QUANTITY'});
 for(const quantity of [1,5])assert.equal(quote({items:[{sku:'AUR-001',quantity}]}).items[0].quantity,quantity);
});
test('CT-07: carrinho vazio e produto repetido não são aceitos',()=>{
 assert.throws(()=>quote({items:[]}),{code:'EMPTY_CART'});
 assert.throws(()=>quote({items:[{sku:'AUR-001',quantity:3},{sku:'AUR-001',quantity:3}]}),{code:'INVALID_PRODUCT'});
});
test('CT-08: preço e total enviados pelo cliente não comandam cálculo',()=>{
 const result=quote({items:[{sku:'AUR-003',quantity:1,price:1}],total:1});
 assert.equal(result.total,11000);assert.equal(result.items[0].price,10000);
});
test('CT-09 a CT-13: tentativa isolada, idempotência e resolução sem nova cobrança',()=>{
 const store=createOrderStore(),input={items:[{sku:'AUR-003',quantity:1}],paymentMode:'timeout'};
 const first=store.submit('test-key-0001',input);
 assert.equal(first.order.status,'pending');
 assert.deepEqual(store.submit('test-key-0001',input),{created:false,order:first.order});
 assert.throws(()=>store.submit('test-key-0001',{...input,items:[{sku:'AUR-003',quantity:2}]}),{code:'IDEMPOTENCY_CONFLICT'});
 const resolved=store.resolve('test-key-0001');assert.equal(resolved.status,'confirmed');assert.equal(resolved.paymentAttempts,1);assert.equal(resolved.id,first.order.id);
 assert.equal(store.submit('test-key-0001',input).order.status,'confirmed');
 assert.equal(store.submit('test-key-0002',{...input,paymentMode:'declined'}).order.status,'declined');
 assert.throws(()=>createOrderStore().get('test-key-0001'),{code:'NOT_FOUND'});
});
