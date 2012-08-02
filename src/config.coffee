###
Loads the `tag` configuration from one of the possible config files.
###


fs = require "fs"



class Config


  config: null
  valid: false

  # In order of preference
  possibleConfigFiles = [
    ".tagconfig.json"
    ".tagconfig"
    "tagconfig.json"
    "tagconfig"
  ]


  constructor: ->
    for possibleConfigFile in possibleConfigFiles
      try 
        config = fs.readFileSync "#{process.cwd()}/#{possibleConfigFile}", "utf-8"
        break unless config?
      catch e
    throw new Error "No config file." unless config?
    @config = config
    @valid = true


module.exports = Config