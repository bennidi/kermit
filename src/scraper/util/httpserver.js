const serve = require('koa-static');
const Koa = require('koa');
const request = require('request');

export class LocalHttpServer{

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

  canServe(url){
    return false;
  }

  stop(){
    this.server.close();
    console.log(`LocalStorageServer closed`);
  }


}
