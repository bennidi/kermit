import {Crawler} from "simplecrawler";
import cheerio from "cheerio";
import {lokijs} from "lokijs";
import {_} from 'lodash';

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
    this.trace = new Map();
    this.crawler = new Crawler()
      .on("crawlstart", ( ) => {
        console.log("Started crawling");
      })
      .on("fetchcomplete", ( item, data, response ) => {
        console.log(`Fetching of ${item.path}`);
        this.dispatcher.dispatch(item.context.withData(cheerio.load(data)))
      })
      .on("queueadd", ( newQueueItem, parsedURL ) => {
        console.log(`Queueing ${parsedURL}`);
        newQueueItem['context'] = this.trace.get(parsedURL);
      })
      .on("queueerror", ( error, parsedURL ) => {
        console.log(error);
      })
      .on("fetcherror", ( error, parsedURL ) => {
        console.log(error);
      })
      .on("fetchstart", ( queueitem, requestOptions ) => {
        console.log("Started fetching" + queueitem.path);
      })
      .on("fetchclienterror", ( queueitem, requestOptions ) => {
        console.log(queueitem);
      })
      .on("fetchredirect", ( original, redirectedUrl, response ) => {
        this.trace.set(redirectedUrl, original.context);
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
      this.trace.set(crawlRequest, context);
      let successful = this.crawler.queueURL(crawlRequest);
      console.log(`Queueing of ${JSON.stringify(url)} successful: ${successful}`);
    }
    else{
      // TODO: Notify of error
    }
    return this;
  }

}

class DataWrapper{

  constructor(data){
    this.src = data;
    this.current = data;
  }

  each(fnct){
    this.current.each((i, item) => fnct(cheerio(item)))
  }

  select(selector){
    this.current = cheerio(this.current(selector));
    return this;
  }
}

class Context {

  constructor( scraper, scenario, parent ) {
    this.scraper = scraper;
    this.scenario = scenario;
    this.parent = parent;
  }

  select(selector) {
    return this.data.select(selector);
  }

  withData( data ) {
    this.data = new DataWrapper(data);
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
