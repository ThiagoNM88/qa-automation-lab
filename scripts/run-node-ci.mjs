import {mkdirSync,readdirSync} from 'node:fs';
import {join} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawn} from 'node:child_process';

const root=fileURLToPath(new URL('../',import.meta.url));
const output=join(root,'results','node');
mkdirSync(output,{recursive:true});
const files=['unit','integration'].flatMap(level=>
  readdirSync(join(root,'tests',level)).filter(name=>name.endsWith('.test.mjs')).sort()
    .map(name=>join(root,'tests',level,name)));
const child=spawn(process.execPath,[
  '--test','--test-reporter=spec','--test-reporter=junit',
  '--test-reporter-destination=stdout',
  `--test-reporter-destination=${join(output,'junit.xml')}`,
  ...files,
],{cwd:root,stdio:'inherit'});
child.on('error',error=>{console.error(error.message);process.exitCode=1;});
child.on('exit',(code,signal)=>{process.exitCode=code??(signal?1:0);});
