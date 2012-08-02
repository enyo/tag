
Q = require "q"
util = require "util"
spawn = require("child_process").spawn
commander = require "commander"

versionRegex = "[0-9]+\\.[0-9]+\\.[0-9]+(?:-dev)?"


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




exports.extractVersion = (string) ->
  matches = string.match(new RegExp(versionRegex))
  throw new Error("Could not extract version out of '" + string + "'")  unless matches? and matches.length == 1
  matches[0]

exports.increaseLastVersion = (string) ->
  splitVersion = string.split(".")
  splitVersion[2]++
  splitVersion.join "."
