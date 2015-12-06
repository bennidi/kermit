import {Crawler} from "simplecrawler";
import cheerio from "cheerio";
import {lokijs} from "lokijs";
import {_} from 'lodash';



class ExecutionTrace{

  info(msg){
    console.info(msg);
  }

  debug(msg){
    console.debug(msg);
  }
  error(msg){
    console.error(msg);
  }

}

/**
 * A CherryTree can be used to conveniently crawl websites with composed handlers.
 */
export class CherryTree {

  /**
   * Create a new default CherryTree
   * @param {collectors} A map of collector functions: ("scenario" -> collector)
   */
  constructor( collectors ) {
    this.dispatcher = new Dispatcher(collectors);
    this.urlToContext = new Map();
    this.crawler = new Crawler()
      .on("crawlstart", ( ) => {
        console.log("Started crawling");
      })
      .on("fetchcomplete", ( item, data, response ) => {
        console.log(`Fetching of ${item.url} complete`);
        let context = item.context;
        context.data(data);
        context.request = item;
        this.dispatcher.dispatch(context);
      })
      .on("queueadd", ( newQueueItem, parsedURL ) => {
        console.log(`Queueing ${newQueueItem.url}`);
        // Attach context to created queueitem
        let context = this.urlToContext.get(parsedURL);
        newQueueItem.context = context;
      })
      .on("queueerror", ( error, parsedURL ) => {
        console.error(error);
      })
      .on("fetcherror", ( error, parsedURL ) => {
        console.error(error);
      })
      .on("fetchstart", ( queueitem, requestOptions ) => {
        console.log("Started fetching" + queueitem.url);
      })
      .on("fetchclienterror", ( queueitem, requestOptions ) => {
        console.log(queueitem);
      })
      .on("fetchredirect", ( original, redirectedUrl, response ) => {
        this.urlToContext.set(redirectedUrl, original.context);
      })
      .on("fetchdataerror", ( queueitem, requestOptions ) => {
        console.log(queueitem);
      })
      .on("fetch404", ( queueitem, response ) => {
        console.log(`Received 404 for ${queueitem.path}`);
      })
      .on("fetchtimeout", ( queueitem, requestOptions ) => {
        console.log(queueitem);
      });

    this.crawler.filterByDomain = false;
    this.crawler.discoverResources = false;
    this.crawler.userAgent = "Mozilla/5.0 (X11; Linux i686; rv:38.0) Gecko/20100101 Firefox/38.0 Iceweasel/38.4.0"
    this.crawler.interval = 2000;
  }

  /**
   * Initiate the scraping process.
   * @param {scenario} The scenario that will be used to start scraping the initial site
   * @return {CherryTree} this cherry tree
   */
  start( url, scenario ) {
    this.enqueue(new Context(this, scenario, null), url);
    this.crawler.start();
  }

  onComplete(callback){
    this.crawler.on("complete", callback);
    return this;
  }

  /**
   * Add a new item to the tree
   * @param {context} The context from which the item was added
   * @param {url} The url that will be scraped
   * @param {scenario} The scenario used to collect data from the item
   * @return {CherryTree} this cherry tree
   */
  enqueue(context, url) {
    let crawlRequest = this.crawler.processURL(url);
    if(crawlRequest){
      this.urlToContext.set(crawlRequest, context);
      this.crawler.queueURL(crawlRequest);
    }
    else{
      // TODO: Notify of error
    }
    return this;
  }

}

class DataWrapper{

  constructor(data, context){
    this._raw = data;
    this.current = cheerio.load(data);
    this.context = context;
  }

  each(fnct){
    this.current.each((i, item) => {
      fnct.call(this.context, cheerio(item))
    });
  }

  select(selector){
    this.current = cheerio(this.current(selector));
    return this;
  }

  raw(){
    return this._raw;
  }
}

class Context {

  constructor( scraper, scenario, parent ) {
    this.scraper = scraper;
    this.scenario = scenario;
    this.parent = parent;
  }

  select(selector) {
    return this.content.select(selector);
  }

  data( data ) {
    this.content = new DataWrapper(data, this);
    return this;
  }

  follow( scenario, url ) {
    this.scraper.enqueue(this.fork(scenario), url)
  }

  fork( scenario ) {
    return new Context( this.scraper, scenario, this );
  }

}

class Dispatcher {

  constructor( handlers ) {
    this.handlers = handlers || {};
  }

  dispatch(context ) {
    var handler = this.handlers[ context.scenario ];
    if (handler) {
      handler.apply(context);
    } else {
      console.log(`No handler found for scenario ${context.scenario} `)
    }
  }

}
