import {createServer} from 'node:http';
import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';
import {catalog,quote,createOrderStore,CheckoutError} from './checkout.mjs';

export function createApp({log=()=>{}}={}){
  const store=createOrderStore();
  return createServer(async(req,res)=>{
    const correlationId=crypto.randomUUID();
    res.setHeader('X-Correlation-ID',correlationId);
    res.setHeader('Cache-Control','no-store');
    res.setHeader('X-Content-Type-Options','nosniff');
    const json=(status,data)=>{res.writeHead(status,{'Content-Type':'application/json; charset=utf-8'});res.end(JSON.stringify(data));};
    try{
      const path=new URL(req.url,'http://localhost').pathname;
      if(req.method==='GET'&&path==='/'){
        res.writeHead(200,{'Content-Type':'text/html; charset=utf-8'});
        res.end(await readFile(new URL('./index.html',import.meta.url)));return;
      }
      if(req.method==='GET'&&path==='/health'){json(200,{status:'ok'});return;}
      if(req.method==='GET'&&path==='/api/catalog'){json(200,catalog);return;}
      if(req.method==='POST'){
        // No CORS is enabled. Browser mutations require the local app origin.
        const origin=req.headers.origin;
        if(origin&&origin!==`http://${req.headers.host}`)throw new CheckoutError('INVALID_ORIGIN','Origem não permitida.','request',403);
      }
      const attempt=path.match(/^\/api\/attempts\/([a-zA-Z0-9_-]{8,100})(\/resolve)?$/);
      if(attempt&&req.method==='GET'&&!attempt[2]){json(200,store.get(attempt[1]));return;}
      if(attempt&&req.method==='POST'&&attempt[2]){
        const order=store.resolve(attempt[1]);log({event:'simulation_resolved',correlationId,orderId:order.id,status:order.status});json(200,order);return;
      }
      if(req.method==='POST'&&['/api/quote','/api/orders'].includes(path)){
        if(!req.headers['content-type']?.startsWith('application/json'))throw new CheckoutError('UNSUPPORTED_MEDIA_TYPE','Envie JSON.','request',415);
        const chunks=[];let size=0;
        for await(const chunk of req){size+=chunk.length;if(size>16384)throw new CheckoutError('BODY_TOO_LARGE','Requisição muito grande.','request',413);chunks.push(chunk);}
        let input;try{input=JSON.parse(Buffer.concat(chunks).toString('utf8'));}catch{throw new CheckoutError('INVALID_JSON','JSON inválido.','request',400);}
        if(path==='/api/quote'){json(200,quote(input));return;}
        const result=store.submit(req.headers['idempotency-key'],input);
        log({event:result.created?'payment_simulated':'attempt_reused',correlationId,orderId:result.order.id,status:result.order.status});
        json(result.order.status==='pending'?202:result.created?201:200,result.order);return;
      }
      json(404,{error:{code:'NOT_FOUND',message:'Recurso não encontrado.',field:'request'},correlationId});
    }catch(error){
      const known=error instanceof CheckoutError;
      log({event:'request_failed',correlationId,code:known?error.code:'INTERNAL_ERROR'});
      json(known?error.status:500,{error:{code:known?error.code:'INTERNAL_ERROR',message:known?error.message:'Falha interna.',field:known?error.field:'request'},correlationId});
    }
  });
}

if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  const port=Number(process.env.PORT||4173);
  const app=createApp({log:event=>console.log(JSON.stringify(event))});
  app.listen(port,'127.0.0.1',()=>console.log(`Loja Aurora (simulação): http://127.0.0.1:${port}`));
  for(const signal of ['SIGINT','SIGTERM'])process.on(signal,()=>app.close(()=>process.exit(0)));
}
