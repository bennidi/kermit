{obj} = require '../util/tools'
libCookie = require('cookie')
_ = require 'lodash'
{Extension} = require '../Extension'

class UserAgent
  
  @defaults:->
    headers:
      'User-Agent'     :'Opera/9.80 (X11; Linux i686; Ubuntu/14.10) Presto/2.12.388 Version/12.16'
      'Accept'         :'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
      'Accept-Encoding':'gzip, deflate, sdch'
  
  constructor:(properties = {})->
    @properties = obj.overlay UserAgent.defaults(), properties
    @id = obj.randomId()
    @cache = {}
    @cookieJar = {}
  
  headers:-> _.clone @properties.headers
  
  import:(response) ->
    headers = response.headers
    cookieHeader = headers['set-cookie'] or headers['cookie']
    if cookieHeader
      for cookie in cookieHeader
        @cookieJar[key] = value for key,value of libCookie.parse cookie
  
  addCookies:(headers, url)->
    cookies = (libCookie.serialize key, value for key, value of @cookieJar)
    if not _.isEmpty cookies then headers['cookie'] = cookies.join('; ');

class UserAgents
  
  
  agentheaders = [
    #chrome
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.0 Safari/537.36"
    "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.0 Safari/537.36"
    "Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2049.0 Safari/537.36"
    "Mozilla/5.0 (Windows NT 4.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2049.0 Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.93 Safari/537.36"
    # firefox
    "Mozilla/5.0 (X11; Linux i586; rv:31.0) Gecko/20100101 Firefox/31.0"
    "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:31.0) Gecko/20130401 Firefox/31.0"
    "Mozilla/5.0 (Windows NT 5.1; rv:31.0) Gecko/20100101 Firefox/31.0"
    "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:29.0) Gecko/20120101 Firefox/29.0"
    "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:25.0) Gecko/20100101 Firefox/29.0"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10; rv:33.0) Gecko/20100101 Firefox/33.0"
    "Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0"
    "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:21.0) Gecko/20130331 Firefox/21.0"
    "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:21.0) Gecko/20100101 Firefox/21.0"
    "Mozilla/5.0 (X11; Linux i686; rv:21.0) Gecko/20100101 Firefox/21.0"
    "Mozilla/5.0 (Windows NT 6.2; WOW64; rv:21.0) Gecko/20130514 Firefox/21.0"
    "Mozilla/5.0 (Windows NT 6.2; rv:21.0) Gecko/20130326 Firefox/21.0"
    "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:21.0) Gecko/20130401 Firefox/21.0"
    "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:21.0) Gecko/20130331 Firefox/21.0"
    "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:21.0) Gecko/20130330 Firefox/21.0"
    "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:21.0) Gecko/20100101 Firefox/21.0"
    "Mozilla/5.0 (Windows NT 6.1; rv:21.0) Gecko/20130401 Firefox/21.0"
    "Mozilla/5.0 (Windows NT 6.1; rv:21.0) Gecko/20130328 Firefox/21.0"
    "Mozilla/5.0 (Windows NT 6.1; rv:21.0) Gecko/20100101 Firefox/21.0"
    "Mozilla/5.0 (Windows NT 5.1; rv:21.0) Gecko/20130401 Firefox/21.0"
    "Mozilla/5.0 (Windows NT 5.1; rv:21.0) Gecko/20130331 Firefox/21.0"
    "Mozilla/5.0 (Windows NT 5.1; rv:21.0) Gecko/20100101 Firefox/21.0"
    "Mozilla/5.0 (Windows NT 5.0; rv:21.0) Gecko/20100101 Firefox/21.0"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0"
    # iceweasel
    "Mozilla/5.0 (X11; Linux x86_64; rv:10.0.7) Gecko/20100101 Firefox/10.0.7 Iceweasel/10.0.7"
    "Mozilla/5.0 (X11; Linux ppc; rv:10.0.7) Gecko/20100101 Firefox/10.0.7 Iceweasel/10.0.7"
    "Mozilla/5.0 (X11; Linux i686; rv:10.0.7) Gecko/20100101 Iceweasel/10.0.7"
    "Mozilla/5.0 (X11; Linux i686; rv:10.0.7) Gecko/20100101 Firefox/10.0.7 Iceweasel/10.0.7"
  ]
  
  
  @create: (size = 20) ->
    agents = []
    for i in [0..size]
      agents.push new UserAgent new UserAgent headers:'User-Agent': agentheaders[obj.randomIndex agentheaders.length]
    agents


class UserAgentProvider extends Extension
  
  # @nodoc
  constructor:->
    super()
    @agents = UserAgents.create()
    console.log @agents
    @on INITIAL:(item) => item.set 'user-agent', @UserAgentFor item
  
  # Retrieve a
  UserAgentFor:(item) ->
    url = item.get('Referer') or item.url()
    hash = url.hashCode() # get hash from url
    @agents[hash % @agents.length]


module.exports = {
  UserAgent
  UserAgentProvider
}
