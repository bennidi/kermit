{obj, uri} = require './tools'

describe  'Tools collection',  ->
  describe ' has uri utilities', ->
    it ' #clean(base, urls) to clean sets of URLs ', ->
      base = "http://kermit.cc/base/"
      uncleaned = [
        'javascript:alert(0);' # removes javascript
        'mailto:hello@kermit.cc' # removes email
        '#inpage-anchor'
        '//kermit.cc/other/path/not/under/base'
        '/relative/path/to/base'
        'some/page/under/base/index.html'
        'some/page/under/base/index.html?q=includesQueryWithParams&param=value'
      ]
      expected = [
        'http://kermit.cc/other/path/not/under/base'
        'http://kermit.cc/relative/path/to/base'
        'http://kermit.cc/base/some/page/under/base/index.html'
        'http://kermit.cc/base/some/page/under/base/index.html?q=includesQueryWithParams&param=value'
      ]

      cleaned = uri.cleanAll base, uncleaned
      expect(cleaned).to.contain expectedUrl for expectedUrl in expected

    it ' #toLocalPath(basedir, url) translates URLs to file identifiers for local storage ', ->
      base = "/tmp"
      expect(uri.toLocalPath base, "http://example.co.uk").to.equal "#{base}/co.uk/example/index.html"
      expect(uri.toLocalPath base, "http://example.co.uk/somepage").to.equal "#{base}/co.uk/example/somepage/index.html"
      expect(uri.toLocalPath base, "https://medialize.github.io/URI.js/docs.html#accessors-tld").to.equal "#{base}/io/github/medialize/URI.js/docs.html"
      expect(uri.toLocalPath base, "http://github.com/some/other/../directory/help.html").to.equal "#{base}/com/github/some/directory/help.html"
      expect(uri.toLocalPath base, "https://raw.githubusercontent.com/moll/js-must/master/lib/es6.js").to.equal "#{base}/com/githubusercontent/raw/moll/js-must/master/lib/es6.js"
      expect(uri.toLocalPath base, "https://github.com/moll/js-must/blob/v0.13.0-beta2/lib/index.js").to.equal "#{base}/com/github/moll/js-must/blob/v0.13.0-beta2/lib/index.js"
      expect(uri.toLocalPath base, "https://en.wikipedia.org/wiki/Web_scraping").to.equal "#{base}/org/wikipedia/en/wiki/Web_scraping/index.html"
      expect(uri.toLocalPath base, "http://upload.wikimedia.org/wikipedia/commons/thumb/b/bd/Ambox_globe_content.svg/48px-Ambox_globe_content.svg.png").to.equal "#{base}/org/wikimedia/upload/wikipedia/commons/thumb/b/bd/Ambox_globe_content.svg/48px-Ambox_globe_content.svg.png"
      expect(uri.toLocalPath base, "http://en.wikipedia.org/wiki/index.php?title=Web_scraping&amp;action=edit&amp;section=1").to.equal "#{base}/org/wikipedia/en/wiki/index[title=Web_scraping&action=edit&section=1].php"
      expect(uri.toLocalPath base, "http://en.wikipedia.org/wiki/Talk:Web_scraping").to.equal "#{base}/org/wikipedia/en/wiki/Talk:Web_scraping/index.html"
      expect(uri.toLocalPath base, "http://en.wikipedia.org/wiki/EBay vs. Bidder%27s Edge").to.equal "#{base}/org/wikipedia/en/wiki/EBay vs. Bidder's Edge/index.html"
      expect(uri.toLocalPath base, "https://en.wikipedia.org/wiki/Nokogiri_(software)").to.equal "#{base}/org/wikipedia/en/wiki/Nokogiri_(software)/index.html"
      expect(uri.toLocalPath base, "https://en.wikipedia.org/wiki/Yahoo!_Query_Language").to.equal "#{base}/org/wikipedia/en/wiki/Yahoo!_Query_Language/index.html"
