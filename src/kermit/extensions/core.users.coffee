{obj} = require '../util/tools'
libCookie = require('cookie')
_ = require 'lodash'

class UserAgent

  @defaults:->
    headers:
      'User-Agent':'Opera/9.80 (X11; Linux i686; Ubuntu/14.10) Presto/2.12.388 Version/12.16'
      'Accept':'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
      'Accept-Encoding': 'gzip, deflate, sdch'

  constructor:(properties = {})->
    @properties = obj.overlay UserAgent.defaults(), properties
    @id = obj.randomId()
    @cache = {}
    @cookieJar= {}

  headers:-> _.clone @properties.headers

  import: (response) ->
    headers = response.headers
    cookieHeader = headers['set-cookie'] or headers['cookie']
    if cookieHeader
      for cookie in cookieHeader
        @cookieJar[key] = value for key,value of libCookie.parse cookie

  addCookies:(headers, url)->
    cookies = (libCookie.serialize key, value for key, value of @cookieJar)
    if not _.isEmpty cookies then headers['cookie'] = cookies.join('; ');


module.exports = {
  UserAgent
}
