
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




exports.extractVersion = (string) ->
  matches = string.match(new RegExp(versionRegex))
  throw new Error("Could not extract version out of '" + string + "'")  unless matches? and matches.length == 1
  matches[0]

exports.increaseLastVersion = (string) ->
  splitVersion = string.split(".")
  splitVersion[2]++
  splitVersion.join "."



# Since aparently ninvoke doesn't work with filewrites
exports.writeFile = (filename, data) ->
  deferred = Q.defer()

  fs.writeFile filename, data, "utf8", (err) ->
    if err?
      deferred.reject err
    else
      deferred resolve()

  deferred.promise


exports.command = (cmd, args...) ->
  deferred = Q.defer()
  command = spawn cmd, args

  command.stdout.pipe process.stdout, end: false
  command.stderr.pipe process.stderr, end: false

  command.on "exit", (code) ->
    if code == null || code != 0
      deferred.reject "Command (#{cmd}) exited with code: #{code}"
    else
      deferred.resolve()

  deferred.promise