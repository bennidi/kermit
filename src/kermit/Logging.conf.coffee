basic = (basedir) ->
  basedir: basedir
  levels : ['trace', 'info', 'error', 'warn']
  destinations: [
    {
      appender:
        type : 'console'
      levels : ['trace', 'error', 'info', 'warn']
    }
  ]

production = (basedir) ->
  conf = basic basedir
  conf.destinations.push
    appender :
      type : 'file'
      filename : "#{basedir}/full.log"
    levels: conf.levels
  conf

detailed = (basedir) ->
  conf = basic basedir
  additionalLevels = ['debug']
  conf.levels.push level for level in additionalLevels
  appender.levels.push level for appender in conf.destinations for level in additionalLevels
  conf.destinations.push
    appender :
      type : 'file'
      filename : "#{basedir}/full.log"
    levels: ['trace', 'error', 'info', 'debug', 'warn']
  conf.destinations.push
    appender :
      type : 'file'
      filename : "#{basedir}/error.log"
    levels: ['error', 'warn']
  conf.destinations.push
    appender :
      type : 'file'
      filename : "#{basedir}/trace.log"
    levels: ['trace']
  conf

module.exports =
  basic : basic
  production : production
  detailed : detailed
