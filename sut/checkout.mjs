export const catalog = Object.freeze([
  Object.freeze({sku:'AUR-001',name:'Caderno Aurora',price:4999}),
  Object.freeze({sku:'AUR-002',name:'Garrafa Aurora',price:5000}),
  Object.freeze({sku:'AUR-003',name:'Mochila Aurora',price:10000}),
  Object.freeze({sku:'AUR-004',name:'Kit Aurora',price:10005}),
]);

export class CheckoutError extends Error {
  constructor(code,message,field,status=422){super(message);this.code=code;this.field=field;this.status=status;}
}

export function totals(subtotal,coupon=''){
  if(!Number.isSafeInteger(subtotal)||subtotal<0)throw new CheckoutError('INVALID_SUBTOTAL','Subtotal inválido.','items');
  if(typeof coupon!=='string')throw new CheckoutError('INVALID_COUPON','Informe um cupom em texto.','coupon');
  const normalized=coupon.trim().toUpperCase();
  if(normalized&&normalized!=='AURORA10')throw new CheckoutError('INVALID_COUPON','Cupom não reconhecido.','coupon');
  if(normalized&&subtotal<10000)throw new CheckoutError('COUPON_MINIMUM','O cupom exige subtotal de pelo menos R$100,00.','coupon');
  const discount=normalized?Math.floor((subtotal+5)/10):0;
  const shipping=subtotal>=20000?0:1000;
  return {subtotal,discount,shipping,total:subtotal-discount+shipping,coupon:normalized};
}

export function quote(input){
  if(!input||!Array.isArray(input.items)||!input.items.length)throw new CheckoutError('EMPTY_CART','Adicione pelo menos um produto.','items');
  if(input.items.length>catalog.length)throw new CheckoutError('INVALID_ITEMS','Há itens demais no carrinho.','items');
  const seen=new Set();
  const items=input.items.map(item=>{
    const product=catalog.find(p=>p.sku===item?.sku);
    if(!product||seen.has(item.sku))throw new CheckoutError('INVALID_PRODUCT','Produto desconhecido ou repetido.','items');
    seen.add(item.sku);
    if(!Number.isInteger(item.quantity)||item.quantity<1||item.quantity>5)throw new CheckoutError('INVALID_QUANTITY','A quantidade deve ser inteira, de 1 a 5.','quantity-'+item.sku);
    return {sku:product.sku,name:product.name,price:product.price,quantity:item.quantity};
  }).sort((a,b)=>a.sku.localeCompare(b.sku));
  const subtotal=items.reduce((sum,item)=>sum+item.price*item.quantity,0);
  return {items,...totals(subtotal,input.coupon??'')};
}

// Local teaching simulator: state is isolated per store and lost on restart.
// No asynchronous work occurs between checking and reserving a key in this process.
export function createOrderStore(){
  const attempts=new Map();
  function get(key){const value=attempts.get(key);if(!value)throw new CheckoutError('NOT_FOUND','Tentativa não encontrada.','key',404);return structuredClone(value.order);}
  return {
    submit(key,input){
      if(typeof key!=='string'||!/^[a-zA-Z0-9_-]{8,100}$/.test(key))throw new CheckoutError('INVALID_KEY','Use uma chave de 8 a 100 letras, números, hífen ou sublinhado.','key');
      const calculated=quote(input);
      const mode=input.paymentMode;
      if(!['approved','declined','timeout'].includes(mode))throw new CheckoutError('INVALID_PAYMENT_MODE','Selecione um modo de pagamento simulado.','paymentMode');
      const fingerprint=JSON.stringify({items:calculated.items.map(({sku,quantity})=>({sku,quantity})),coupon:calculated.coupon,mode});
      const previous=attempts.get(key);
      if(previous){
        if(previous.fingerprint!==fingerprint)throw new CheckoutError('IDEMPOTENCY_CONFLICT','A chave já foi usada com outro conteúdo.','key',409);
        return {created:false,order:get(key)};
      }
      const order={id:crypto.randomUUID(),key,...calculated,status:mode==='approved'?'confirmed':mode==='declined'?'declined':'pending',paymentAttempts:1};
      attempts.set(key,{fingerprint,order});
      return {created:true,order:get(key)};
    },
    get,
    resolve(key){
      get(key);
      const record=attempts.get(key);
      if(record.order.status==='pending')record.order.status='confirmed';
      return get(key);
    },
  };
}
