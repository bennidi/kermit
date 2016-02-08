crawl = require '../cherry.modules'
tCookie = require 'tough-cookie'

class CookieSupport extends crawl.extensions.Extension

  constructor: () ->
    super  ["PROCESSING"]
    @cookiejar = new tCookie.CookieJar();

  apply: (item) ->
    Cookie = tCookie.Cookie;
    cookie = Cookie.parse(item.response.headers["set-cookie"]);

  initialize: (context) ->
    super context
