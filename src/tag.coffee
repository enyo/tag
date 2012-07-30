
program = require "commander"

program
  .version("1.1.9-dev")
  .usage("[options] [<tag>]")
  .option("-d, --dev <version>", "the next dev version")
  .option("-r, --rename", "rename only")
  .parse(process.argv)



unless program.args.length == 1
  console.log program.helpInformation()
  process.exit()



config = require "./config"





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
  



