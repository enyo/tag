
program = require "commander"
colors = require "colors"
Q = require "q"
utils = require "./utils"
fs = require "fs"
Config = require "./config"
git = require "gift"
repo = git process.cwd()






program
  .version("1.1.9-dev")
  .usage("[options]")
  .option("-t, --tag <version>", "the tag if not incremental")
  .option("-d, --dev <version>", "the next dev version")
  .option("-r, --rename", "rename only")
  .option("-m, --message", "the tag message")
  .option("-a, --add", "add a file to the tagconfig")
  .parse(process.argv)



# I want an empty line at the beginning.
console.log()





config = null

Q.fcall(->
  config = new Config process.cwd()
)
.then ->
  if program.add

    # Add a new file to the config.

    filename = null
    regex = null

    Q.fcall(->
      unless config.config?
        console.log "You don't have a tagconfig file yet."
        console.log "Please choose a filename where to store your configuration:"
        console.log()
        utils.choose(config.possibleConfigFiles)
        .then (fileIndex) ->
          console.log()
          config.setFile config.possibleConfigFiles[fileIndex]
          config.config = { files: [] }
    )
    .then ->
      utils.prompt "Please enter the version filename: "
    .then (name) ->
      filename = name
      utils.prompt "Please enter the expression to look for [ ### ]: "
    .then (regx) ->
      regex = regx
      config.add filename, regex
      config.save()
    .then ->
      {
        filename: filename
        regex: regex
      }

    .then (info) ->
      console.log "Successfully added '#{info.filename}' to the config file '#{config.file}'.".green

  else
    Q.fcall(->
      throw new Error "No valid tagconfig file. Please see 'tag -h' on how to create one." unless config.config?
    )
    .then ->
      Q.ncall(repo.status, repo)
    .then (status) ->
      throw new Error "Repository is not clean. Please commit or stash all your changes." unless status.clean


.then ->
  console.log()
  process.exit()
.fail (err) ->
  console.log()
  console.log "Error: ".red.bold + err.message.red
  console.log()
  process.exit 1

versionRegex = "[0-9]+\\.[0-9]+\\.[0-9]+(?:-dev)?"




# console.log "dev", program.dev

# console.log ' args: %j', program.args


# fs = require("fs")
# possibleConfigFileUris = [ "./.tagconfig.json", "./.tagconfig", "./tagconfig.json", "./tagconfig" ]
# configFileUri = undefined
# previousVersion = undefined
# nextVersion = undefined
# nextDevVersion = undefined
# tagName = undefined


# color = require "./color"




# utils.prompt("Are you fine: ")
# .then (response) ->
#   utils.confirm "Sure?: "
# .then (response) ->
#   utils.choose [ "bla", "bli" ]
# .then (response) ->
#   console.log  "bla", response
  



