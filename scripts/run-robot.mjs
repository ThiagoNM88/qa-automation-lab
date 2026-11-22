import {existsSync} from 'node:fs';
import {spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {join} from 'node:path';
import {once} from 'node:events';

const root=fileURLToPath(new URL('../',import.meta.url));
const python=join(root,'.venv',process.platform==='win32'?'Scripts':'bin',process.platform==='win32'?'python.exe':'python');
const headless=process.argv.includes('--headless');
const local=process.argv.includes('--local');
const demo=process.argv.includes('--demo-falhas');
const smoke=process.argv.includes('--smoke');
if(process.argv.slice(2).some(arg=>!['--headless','--local','--demo-falhas','--smoke'].includes(arg)) || (smoke && demo)){
  console.error('Uso: npm run test:robot -- [--headless] [--local] [--demo-falhas | --smoke]');process.exit(2);
}
if(!existsSync(python)){
  console.error('Ambiente Robot ausente. Siga docs/robot-primeiro-teste.md para instalar.');process.exit(2);
}
const args=['-m','robot','--outputdir','results/robot','--variable',`HEADLESS:${headless?'True':'False'}`,'--variable',`SLOW_MO:${headless?'0ms':'400ms'}`];
if(smoke){
  args.push('--include','smoke');
  console.log('Seleção smoke: somente cenários com a tag smoke.');
}
let target;
try{
  if(local){
    const {createApp}=await import('../sut/server.mjs');
    target=createApp();
    target.listen(0,'127.0.0.1');
    await once(target,'listening');
    const url=`http://127.0.0.1:${target.address().port}`;
    args.push('--variable',`BASE_URL:${url}`);
    console.log(`Checkout: simulador da versão local em ${url}`);
  }else console.log('Checkout: loja publicada. Pagamentos: simulador local descartável.');
  args.push('tests/robot');
  if(demo){
    args.push('examples/falhas-controladas.robot');
    console.log('DEMONSTRAÇÃO: duas falhas intencionais serão executadas; o resultado esperado é reprovação.');
  }
  console.log('Relatório: results/robot/report.html');
  const child=spawn(python,args,{cwd:root,stdio:'inherit',env:{...process.env,PYTHONIOENCODING:'utf-8'}});
  process.once('SIGINT',()=>child.kill('SIGINT'));
  process.once('SIGTERM',()=>child.kill('SIGTERM'));
  process.exitCode=await new Promise((resolve,reject)=>{
    child.once('error',reject);
    child.once('exit',(code,signal)=>resolve(code??(signal?1:0)));
  });
}catch(error){console.error(error.message);process.exitCode=1;}
finally{
  if(target){target.closeAllConnections();await new Promise(resolve=>target.close(resolve));}
}
