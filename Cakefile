
{spawn, exec} = require 'child_process'


# ANSI Terminal Colors
bold = '\x1b[0;1m'
green = '\x1b[0;32m'
reset = '\x1b[0m'
red = '\x1b[0;31m'



task 'publish', 'checkout master, publish to npm, checkout develop', -> publish -> log ":-)", green


log = (message, color, explanation) -> console.log color + message + reset + ' ' + (explanation or '')

launch = (cmd, options=[], callback) ->
  app = spawn cmd, options
  app.stdout.pipe(process.stdout)
  app.stderr.pipe(process.stderr)
  app.on 'exit', (status) -> callback?() if status is 0


publish = (callback) ->
  launch "git", [ "checkout", "master" ], ->
    launch "npm", [ "publish" ], ->
      launch "git", [ "checkout", "develop" ], callback

