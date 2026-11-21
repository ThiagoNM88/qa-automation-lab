import {createClient} from '@supabase/supabase-js';
const url=import.meta.env.VITE_SUPABASE_URL,key=import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY;
const configured=Boolean(url?.startsWith('https://')&&key?.startsWith('sb_publishable_'));
const supabase=configured?createClient(url,key):null;
const $=id=>document.getElementById(id);
function openAccount(){if(!$('account-dialog').open)$('account-dialog').showModal();}
$('open-account').onclick=openAccount;
$('close-account').onclick=()=>$('account-dialog').close();
let currentUser=null,authBusy=false,historyVersion=0;
const errorMessage=error=>error?.message||'Não foi possível concluir a operação.';
function assertConfig(){if(!supabase)throw Error('Integração pendente: configure URL e chave pública do Supabase na hospedagem e gere um novo build.');}
function check(error){if(error)throw Error(errorMessage(error));}
function asOrder(data){return {...data,paymentAttempts:data.payment_attempts};}
async function requireUser(){assertConfig();const {data,error}=await supabase.auth.getUser();check(error);if(!data.user){openAccount();throw Error('Entre na sua conta para confirmar ou consultar pedidos.');}return data.user;}
export async function api(path,options={}){
 assertConfig();let data,error;
 if(path==='/api/catalog'){
  ({data,error}=await supabase.from('products').select('sku,name,price').order('sku'));check(error);return data;
 }
 const body=options.body?JSON.parse(options.body):{};
 if(path==='/api/quote'){
  ({data,error}=await supabase.rpc('checkout_quote',{p_items:body.items,p_coupon:body.coupon??''}));check(error);return data;
 }
 await requireUser();
 if(path==='/api/orders'){
  ({data,error}=await supabase.rpc('checkout_place',{p_items:body.items,p_coupon:body.coupon??'',p_mode:body.paymentMode,p_key:options.headers['Idempotency-Key']}));check(error);await refreshHistory();return asOrder(data);
 }
 const match=path.match(/^\/api\/attempts\/([a-zA-Z0-9_-]+)(\/resolve)?$/);
 if(match){
  if(match[2])({data,error}=await supabase.rpc('checkout_resolve',{p_key:match[1]}));
  else ({data,error}=await supabase.from('orders').select('id,key,items,subtotal,discount,shipping,total,coupon,status,payment_attempts,created_at').eq('key',match[1]).maybeSingle());
  check(error);if(!data)throw Error('Tentativa não encontrada para esta conta.');if(match[2])await refreshHistory();return asOrder(data);
 }
 throw Error('Operação não reconhecida.');
}
function renderSession(user){
 currentUser=user;historyVersion++;
 $('auth-form').hidden=Boolean(user);$('sign-out').hidden=!user;
 $('open-account').textContent=user?'Minha conta ✓':'Minha conta';
 $('account-status').textContent=user?'Conectado como '+user.email:'Entre para confirmar pedidos e consultar seu histórico.';
 $('auth-password').value='';$('order-history').replaceChildren();
 $('order-result').textContent='Nenhuma tentativa consultada nesta sessão.';
 $('resolve').hidden=true;$('consult').disabled=true;$('new-attempt').disabled=true;
 // IDs from a previous account must not be treated as the current account's state.
 $('auth-message').textContent='';refreshHistory();
}
async function refreshHistory(){
 const version=++historyVersion;$('order-history').replaceChildren();
 if(!currentUser){$('history-status').textContent='Entre na conta para consultar seus pedidos.';return;}
 $('history-status').textContent='Carregando…';
 const {data,error}=await supabase.from('orders').select('id,key,total,status,created_at,payment_attempts').order('created_at',{ascending:false}).limit(30);
 if(version!==historyVersion)return;
 if(error){$('history-status').textContent=errorMessage(error);return;}
 $('history-status').textContent=data.length?`${data.length} pedido(s) mais recentes desta conta.`:'Você ainda não tem pedidos.';
 for(const order of data){const li=document.createElement('li');li.style.padding='10px 0';li.style.overflowWrap='anywhere';li.textContent=`${new Date(order.created_at).toLocaleString('pt-BR')} · ${order.status} · ${new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'}).format(order.total/100)} · ${order.id} · ${order.payment_attempts} tentativa(s)`;$('order-history').append(li);}
}
async function authAction(action){
 if(authBusy)return;authBusy=true;for(const id of ['sign-in','sign-up','sign-out'])$(id).disabled=true;
 $('auth-message').textContent='Aguarde…';
 try{assertConfig();await action();}catch(error){$('auth-message').textContent=errorMessage(error);}finally{authBusy=false;for(const id of ['sign-in','sign-up','sign-out'])$(id).disabled=false;}
}
$('auth-form').onsubmit=event=>{event.preventDefault();authAction(async()=>{const {data,error}=await supabase.auth.signInWithPassword({email:$('auth-email').value.trim(),password:$('auth-password').value});check(error);renderSession(data.user);});};
$('sign-up').onclick=()=>{if(!$('auth-form').reportValidity())return;authAction(async()=>{const {data,error}=await supabase.auth.signUp({email:$('auth-email').value.trim(),password:$('auth-password').value,options:{emailRedirectTo:location.origin}});check(error);$('auth-password').value='';if(data.session)renderSession(data.user);else $('auth-message').textContent='Solicitação de cadastro recebida. Se elegível, confirme seu e-mail e depois entre na conta. Verifique também as restrições de destinatários do ambiente de estudo.';});};
$('sign-out').onclick=()=>authAction(async()=>{const {error}=await supabase.auth.signOut({scope:'local'});check(error);location.reload();});
$('refresh-orders').onclick=()=>refreshHistory();
if(supabase){
 supabase.auth.onAuthStateChange((event,session)=>{
  // Queue outside Auth callback so DB requests cannot deadlock token refresh.
  if(['SIGNED_OUT','SIGNED_IN','INITIAL_SESSION'].includes(event))setTimeout(()=>renderSession(session?.user??null),0);
 });
 supabase.auth.getUser().then(({data})=>renderSession(data.user)).catch(()=>renderSession(null));
}else{$('account-status').textContent='Supabase ainda não configurado nesta publicação.';$('auth-message').textContent='Defina as variáveis públicas na hospedagem e publique novamente.';}
