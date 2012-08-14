###
Loads the `tag` configuration from one of the possible config files.
###


fs = require "fs"
Q = require "q"
utils = require "./utils"


escapeRegexString = (string) -> string.replace /[-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"

versionRegex = "[0-9]+\\.[0-9]+\\.[0-9]+(?:-dev)?"


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
    if @file?
      console.log "Using config file ".grey + "#{@file}".bold + ":"
      console.log()

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


  getVersions: ->
    Q.all(
      # A promise for each file
      for file in @config.files
        do (file) =>
          fileInfo =
            name: file.name
            uri: @getFileUri file.name
          Q.ncall(fs.readFile, fs, fileInfo.uri, "utf8")
          .then (content) =>
            fileInfo.content = content
            # Now all regular expressions... Pheeea
            info =
              file: fileInfo
              regexs: [ ]

            for regex in file.regexs
              regexInfo =
                originalRegex: regex
                completeRegex: new RegExp "(#{regex.replace('###', ')(' + versionRegex + ')(')})", "gm"
                matches: [ ]

              matches = content.match regexInfo.completeRegex
              throw new Error "No match found in file #{info.file.name} with regex: #{regex}" unless matches 
              for match in matches
                regexInfo.matches.push version: @extractVersion(match), match: match

              info.regexs.push regexInfo


            info
    )

  replaceVersion: (infos, version) ->
    Q.all (
      for info in infos
        replacedContent = info.file.content
        for regexInfo in info.regexs
          replacedContent = replacedContent.replace regexInfo.completeRegex, '$1' + version + '$3'
        Q.ncall fs.writeFile, fs, info.file.uri, replacedContent, 'utf8'
    )


  # Extracts the version out of a string. The string is already a small portion
  # of the file.
  extractVersion: (string) ->
    matches = string.match new RegExp versionRegex
    unless matches and matches[0]
      throw new Error("Could not extract version out of '" + string + "'")
    matches[0]

  # 1.2.3-dev => 1.2.3
  # 1.2.3 => 1.2.4
  increaseVersion: (version) ->
    devRegex = /\-dev$/;
    if devRegex.test version
      version.replace devRegex, ""
    else
      splitVersion = version.split "."
      splitVersion[2]++
      splitVersion.join "."

  setFile: (file) ->
    @file = file
    @fileUri = @getFileUri @file

  save: ->
    Q.ncall fs.writeFile, fs, @fileUri, JSON.stringify(@config, null, "  "), "utf8"

  add: (filename, regex) ->
    match = regex.match /###/g

    throw new Error "The regular expression did contain #{matchCount} occurences of ###." if !match or match.length != 1

    @config.files.push { name: filename, regexs: escapeRegexString(regex or "###") }



module.exports = Config