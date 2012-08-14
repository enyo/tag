
# The first one will be used as default if no config is available.
createConfig = ->
  console.log "Neither of those possible config files exists: %s", possibleConfigFileUris.join(", ")
  nl()
  console.log "To create %s, please specify all files that should be parsed.", configFileUri
  nl()
  getFile = (files, onFinishCallback) ->
    nl()
    file = {}
    console.log "Filename (Empty ends the list):"
    readFromStdIn (text) ->
      if text is ""
        if files.length is 0
          nl()
          console.error "You have to provide at least one filename."
          nl()
          getFile files, onFinishCallback
        else
          onFinishCallback files
          return
      else
        file.name = text
        file.regexs = []
        nl()
        if files.length is 0
          console.log "The version string defines the string that should be replaced with the actual version."
          console.log "You can just use ### (which is the default) if you only have one version in the file, or a more detailed phrase, eg: version=\"###\""
          console.log "If you actually want to specify a more complex regular expression edit the .tagconfig file after but be careful to use parentheses without capturing like this: (?:stuff)."
          nl()
        console.log "Version string: [ ### ] "
        readFromStdIn (text) ->
          file.regexs.push escapeRegexString((if text then text else "###"))
          files.push file
          getFile files, onFinishCallback



  getFile [], (files) ->
    config = files: files
    nl()
    console.log "Writing config to %s...", configFileUri
    fs.writeFileSync configFileUri, JSON.stringify(config, null, 2), "utf8"
    console.log "Successfully created the config."
    console.log "Add %s to git and commit it. Then start this script again.", configFileUri
    nl()
    nl()


###
Now go through the files, and add all additional information.
###

# if (regexInfos.matches.length > 1) {
#   console.log('---------------------------------------------------------------------------------------------');
#   console.log(' WARNING: Multiple matches found in "%s" with regex "%s"', fileInfo.name, regex);
#   console.log('---------------------------------------------------------------------------------------------');
# }

# executes `pwd`

# Let's go for it!
each = (list, callback) ->
  i = 0

  while i < list.length
    callback list[i], i
    i++
extractVersion = (string) ->
  matches = string.match(new RegExp(versionRegex))
  throw new Error("Could not extract version out of '" + string + "'")  if not matches or matches.length < 1 or matches.length > 1
  matches[0]
increaseLastVersion = (string) ->
  splitVersion = string.split(".")
  splitVersion[2]++
  splitVersion.join "."
replaceVersion = (files, version) ->
  each files, (fileInfo) ->
    replacedContent = fileInfo.content
    each fileInfo.regexInfos, (regexInfo) ->
      replacedContent = replacedContent.replace(regexInfo.complete, "$1" + version + "$3")

    fs.writeFileSync fileInfo.name, replacedContent, "utf8"

spawnWithCallback = (commandString, arguments, callback) ->
  command = spawn(commandString, arguments)
  command.stdout.pipe process.stdout,
    end: false

  command.stderr.pipe process.stderr,
    end: false

  command.on "exit", (code) ->
    if code is null or code isnt 0
      console.error "Command (%s) exited with code: %d", commandString, code
      process.exit()
      return
    callback()

readFromStdIn = (callback) ->
  process.stdin.resume()
  process.stdin.setEncoding "utf8"
  eventListener = (text) ->
    process.stdin.pause()
    process.stdin.removeListener "data", eventListener
    callback text.replace(/^\s+|\s+$/g, "")

  process.stdin.on "data", eventListener
escapeRegexString = (string) ->
  string.replace /[-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"
nl = ->
  console.log()

###
Taken from: https://github.com/loopj/commonjs-ansi-color
###
color = (str, color) ->
  ANSI_CODES =
    off: 0
    bold: 1
    italic: 3
    underline: 4
    blink: 5
    inverse: 7
    hidden: 8
    black: 30
    red: 31
    green: 32
    yellow: 33
    blue: 34
    magenta: 35
    cyan: 36
    white: 37
    black_bg: 40
    red_bg: 41
    green_bg: 42
    yellow_bg: 43
    blue_bg: 44
    magenta_bg: 45
    cyan_bg: 46
    white_bg: 47

  return str  unless color
  color_attrs = color.split("+")
  ansi_str = ""
  i = 0
  attr = undefined

  while attr = color_attrs[i]
    ansi_str += "\u001b[" + ANSI_CODES[attr] + "m"
    i++
  ansi_str += str + "\u001b[" + ANSI_CODES["off"] + "m"
  ansi_str
fs = require("fs")
util = require("util")
spawn = require("child_process").spawn
version = "1.1.9-dev"
possibleConfigFileUris = [ "./.tagconfig.json", "./.tagconfig", "./tagconfig.json", "./tagconfig" ]
configFileUri = undefined
versionRegex = "[0-9]+\\.[0-9]+\\.[0-9]+(?:-dev)?"
previousVersion = undefined
nextVersion = undefined
nextDevVersion = undefined
tagName = undefined
console.log "Usage (v%s): tag [nextVersion [nextDevVersion]] [--rename-only]", version
nl()
i = 0
while i < possibleConfigFileUris.length and not configFileUri
  try
    configStats = fs.statSync(possibleConfigFileUris[i])
    configFileUri = possibleConfigFileUris[i]  if configStats.isFile()
  i++
unless configFileUri
  configFileUri = possibleConfigFileUris[0]
  createConfig()
  process.exit 1
try
  console.log "Using config file %s\n", configFileUri
  try
    config = JSON.parse(fs.readFileSync(configFileUri, "utf8"))
    throw new Error("Did not contain a files list.")  unless config.files
  catch e
    throw new Error("Invalid config file (" + configFileUri + ")\nThe error: " + e.message)
  each config.files, (fileInfo) ->
    fileInfo.content = fs.readFileSync(fileInfo.name, "utf8")
    fileInfo.regexInfos = []
    each fileInfo.regexs, (regex) ->
      regexInfos = original: regex
      matchCount = (if regex.match(/###/g) then regex.match(/###/g).length else 0)
      throw new Error("The regular expression did contain " + matchCount + " occurences of ### for file: " + fileInfo.name + " (" + regex + ")")  if matchCount isnt 1
      regexInfos.complete = new RegExp("(" + regex.replace("###", ")(" + versionRegex + ")(") + ")", "gm")
      regexInfos.matches = fileInfo.content.match(regexInfos.complete)
      throw new Error("No match found in file " + fileInfo.name + " with regex: " + regex)  unless regexInfos.matches
      previousVersion = extractVersion(regexInfos.matches[0])  unless previousVersion
      fileInfo.regexInfos.push regexInfos


  nl()
  console.log color("Matches:", "underline")
  error = undefined
  each config.files, (fileInfo) ->
    each fileInfo.regexInfos, (regexInfo) ->
      console.log "\nFile: %s (Regular expression: %s)", color(fileInfo.name, "green"), color(regexInfo.original, "green")
      each regexInfo.matches, (match, i) ->
        rightVersion = extractVersion(match) is previousVersion
        matchDisplay = undefined
        if rightVersion and i is 0
          matchDisplay = match
        else unless rightVersion
          error = "Detected different version than '" + previousVersion + "' in file '" + fileInfo.name + "': " + match
          matchDisplay = color(match, "red_bg") + color(" (Error: wrong version)", "red")
        else
          matchDisplay = color(match, "red") + " (Warning: multiple matches)"
        console.log " - %s", matchDisplay



  throw new Error(error)  if error
  nl()
  nl()
  renameOnly = false
  argCount = 0
  i = 2

  while i < process.argv.length
    thisArg = process.argv[i]
    unless thisArg is "--rename-only"
      if argCount is 0
        nextVersion = thisArg
      else nextDevVersion = thisArg  if argCount is 1
      argCount++
    i++
  unless nextVersion
    devRegex = /\-dev$/
    if devRegex.test(previousVersion)
      nextVersion = previousVersion.replace(devRegex, "")
    else
      nextVersion = increaseLastVersion(previousVersion)
  nextDevVersion = increaseLastVersion(nextVersion) + "-dev"  unless nextDevVersion
  tagName = "v" + nextVersion
  console.log "========================================"
  console.log " Current version:    %s", color(previousVersion, "red+bold")
  console.log " Next version:       %s", color(nextVersion, "green")
  unless renameOnly
    console.log " Tag name:          %s", color(tagName, "green")
    console.log " Next dev version:   %s", color(nextDevVersion, "blue")
  console.log "========================================"
  if renameOnly
    nl()
    console.log color("(Only renaming)", "bold+blue")
  nl()
  console.log "Make sure you're on the right (develop) branch: "
  child = undefined
  spawnWithCallback "git", [ "branch", "--color" ], ->
    nl()
    console.log "Press enter to continue (Ctrl-c to abort)..."
    readFromStdIn (text) ->
      if text isnt ""
        console.log "Aborting."
        process.exit()
      replaceVersion config.files, nextVersion
      if renameOnly
        console.log "Replacing only, so stopping here."
        nl()
      else
        console.log "Commiting the change."
        spawnWithCallback "git", [ "commit", "-am", "Upgrading version to " + nextVersion ], ->
          nl()
          console.log "Tagging the commit. Enter your message: "
          readFromStdIn (text) ->
            nl()
            spawnWithCallback "git", [ "tag", "-a", tagName, "-m", text.replace(/\"/, "\\\"") ], ->
              replaceVersion config.files, nextDevVersion
              spawnWithCallback "git", [ "commit", "-am", "Upgrading version to " + nextDevVersion ], ->
                nl()
                console.log "Do you want to merge the tag %s to master? [ Y n ]", tagName
                readFromStdIn (text) ->
                  nl()
                  return  if text isnt "Y" and text isnt ""
                  console.log "Checking out master"
                  spawnWithCallback "git", [ "checkout", "master" ], ->
                    nl()
                    console.log "Merging %s", tagName
                    spawnWithCallback "git", [ "merge", "--no-ff", tagName ], ->
                      nl()
                      console.log "Checking out develop again"
                      spawnWithCallback "git", [ "checkout", "develop" ], ->
                        nl()
                        console.log "Do you want to push --all and push --tags? [ Y n ]"
                        readFromStdIn (text) ->
                          nl()
                          return  if text isnt "Y" and text isnt ""
                          spawnWithCallback "git", [ "push", "-v", "--all" ], ->
                            spawnWithCallback "git", [ "push", "-v", "--tags" ], ->
                              nl()













catch e
  console.log "\n\nFatal error:\n\n%s", color(e.message, "red+bold")
  nl()