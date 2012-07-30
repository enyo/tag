
Q = require "q"
util = require "util"
spawn = require("child_process").spawn
commander = require "commander"



wrapCommander = (method) ->
  (commanderArguments...) ->
    deferred = Q.defer()
    commanderArguments.push (response) -> deferred.resolve response
    commander[method].apply commander, commanderArguments
    deferred.promise


commanderMethods = [
  "prompt"
  "choose"
  "confirm"
]

exports[method] = wrapCommander method for method in commanderMethods
