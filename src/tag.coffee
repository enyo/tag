
program = require "commander"
colors = require "colors"
Q = require "q"



program
  .version("1.1.9-dev")
  .usage("[options] [<tag message>]")
  .option("-t, --tag <version>", "the tag if not incremental")
  .option("-d, --dev <version>", "the next dev version")
  .option("-r, --rename", "rename only")
  .parse(process.argv)



# unless program.args.length == 1
#   console.log program.helpInformation()
#   process.exit()


raiseError = (error) ->
  console.log()
  console.error error.red.bold
  process.exit()


Config = require "./config"

git = require "gift"
repo = git process.cwd()




Q.fcall(->
  config = new Config()
)
.then ->
  Q.ncall(repo.status, repo)
.then (status) ->
  throw new Error "Repository is not clean." unless status.clean


.fail (err) ->
  raiseError err.message


versionRegex = "[0-9]+\\.[0-9]+\\.[0-9]+(?:-dev)?"




console.log "dev", program.dev

console.log ' args: %j', program.args


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
  



