import {existsSync} from 'node:fs';
import {spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {join} from 'node:path';

const root=fileURLToPath(new URL('../',import.meta.url));
const python=join(root,'.venv',process.platform==='win32'?'Scripts':'bin',process.platform==='win32'?'python.exe':'python');
const headless=process.argv.includes('--headless');
if(process.argv.slice(2).some(arg=>arg!=='--headless')){
  console.error('Uso: npm run test:robot -- [--headless]');process.exit(2);
}
if(!existsSync(python)){
  console.error('Ambiente Robot ausente. Siga docs/robot-primeiro-teste.md para instalar.');process.exit(2);
}
const args=['-m','robot','--outputdir','results/robot','--variable',`HEADLESS:${headless?'True':'False'}`,'--variable',`SLOW_MO:${headless?'0ms':'400ms'}`,'tests/robot'];
console.log('Robot: abrir loja → adicionar mochila → aplicar cupom → conferir valores.');
console.log('Relatório: results/robot/report.html');
const child=spawn(python,args,{cwd:root,stdio:'inherit',env:{...process.env,PYTHONIOENCODING:'utf-8'}});
child.on('error',error=>{console.error(error.message);process.exitCode=1;});
child.on('exit',(code,signal)=>{process.exitCode=code??(signal?1:0);});
