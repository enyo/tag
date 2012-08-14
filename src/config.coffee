###
Loads the `tag` configuration from one of the possible config files.
###


fs = require "fs"
Q = require "q"
utils = require "./utils"


escapeRegexString = (string) -> string.replace /[-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"



class Config

  file: null
  fileUri: null
  config: null

  # In order of preference
  possibleConfigFiles: [
    ".tagconfig.json"
    ".tagconfig"
    "tagconfig.json"
    "tagconfig"
  ]


  constructor: (@dir) ->
    @load()

  getFileUri: (filename) ->
    "#{@dir}/#{filename}"

  load: ->
    for possibleConfigFile in @possibleConfigFiles
      try 
        config = fs.readFileSync "#{@getFileUri possibleConfigFile}", "utf-8"
        break if config?
      catch e

    if config?
      @setFile possibleConfigFile
      try
        @config = JSON.parse config
      catch e
        throw new Error "Invalid JSON."


  setFile: (file) ->
    @file = file
    @fileUri = @getFileUri @file

  save: ->
    Q.ncall fs.writeFile, fs, @fileUri, JSON.stringify(@config, null, "  "), "utf8"

  add: (filename, regex) ->
    @config.files.push { name: filename, regexs: escapeRegexString(regex or "###") }



module.exports = Config