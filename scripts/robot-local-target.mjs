import {createApp} from '../sut/server.mjs';
const app=createApp();
app.listen(0,'127.0.0.1',()=>console.log(`http://127.0.0.1:${app.address().port}`));
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,()=>{
  app.closeAllConnections();
  app.close(()=>process.exit(0));
});
