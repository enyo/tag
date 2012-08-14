
Q = require "q"
util = require "util"
spawn = require("child_process").spawn
commander = require "commander"
fs = require "fs"
{spawn} = require "child_process"

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




exports.command = (cmd, args...) ->
  deferred = Q.defer()
  command = spawn cmd, args

  command.stdout.pipe process.stdout, end: false
  command.stderr.pipe process.stderr, end: false

  command.on "exit", (code) ->
    if code == null || code != 0
      deferred.reject new Error "Command (#{cmd}) exited with code: #{code}"
    else
      deferred.resolve()

  deferred.promise