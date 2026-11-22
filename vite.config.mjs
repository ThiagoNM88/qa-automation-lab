import {defineConfig,loadEnv} from 'vite';
import {fileURLToPath} from 'node:url';
const base=fileURLToPath(new URL('.',import.meta.url));
export default defineConfig(({mode})=>{
 const env={...loadEnv(mode,base),...process.env};
 if(!env.VITE_SUPABASE_URL?.startsWith('https://')||!env.VITE_SUPABASE_PUBLISHABLE_KEY?.startsWith('sb_publishable_'))throw Error('Configure VITE_SUPABASE_URL e VITE_SUPABASE_PUBLISHABLE_KEY antes de construir a aplicação.');
 return {root:'web',envDir:base,build:{outDir:'../dist',emptyOutDir:true}};
});
