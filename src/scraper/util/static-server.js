const serve = require('koa-static');
const Koa = require('koa');
export class LocalStorageServer{

  constructor(port = 3000, basedir = "./fixtures"){
    this.port = port;
    this.basedir = basedir;
  }


  start(){
    const app = new Koa();
    app.use(serve(this.basedir));
    this.server = app.listen(this.port);
    console.log(`LocalStorageServer listening on port ${this.port} and basedir ${this.basedir}`);
  }


  stop(){
    this.server.close();
    console.log(`LocalStorageServer closed`);
  }


}
