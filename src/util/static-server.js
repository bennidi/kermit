const serve = require('koa-static');
const Koa = require('koa');
export class FixtureServer{

  constructor(port = 3000, basedir = "./fixtures"){
    this.port = port;
    this.basedir = basedir;
  }


  start(){
    const app = new Koa();
    app.use(serve(this.basedir));
    this.server = app.listen(this.port);
    console.log(`Fixture server listening on port ${this.port} closed`);
  }


  stop(){
    this.server.close();
    console.log(`Fixture server listening on port ${this.port} closed`);
  }


}
