
program = require "commander"
colors = require "colors"
Q = require "q"
utils = require "./utils"
fs = require "fs"
Config = require "./config"
git = require "gift"
repo = git process.cwd()
Table = require "cli-table"






program
  .version("1.1.9-dev")
  .usage("[options]")
  .option("-t, --tag <version>", "the tag if not incremental")
  .option("-d, --dev <version>", "the version you want to use after the tag")
  .option("-r, --rename", "rename only")
  .option("-m, --message [message]", "the tag message")
  .option("-a, --add", "add a file to the tagconfig")
  .option("--nomerge", "do not merge the tag to master")
  .option("--nopush", "do not push --all and --tags after tagging")
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
    branch = null
    repoClean = no
    infos = null
    previousVersion = null
    tagVersion = null
    nextDevVersion = null
    tagMessage = null

    Q.fcall(->
      throw new Error "No valid tagconfig file. Please see 'tag -h' on how to create one." unless config.config?
    )
    .then ->
      Q.ncall repo.status, repo
    .then (status) ->
      repoClean = status.clean
      Q.ncall repo.branch, repo
    .then (head) ->
      branch = head.name
      config.getVersions()
    .spread (thisInfos...) ->
      table = new Table
        head: [
          "Filename"
          "Version(s)"
          "Matched"
          "Regex(s)"
        ]

      versionConflict = no
      for info in thisInfos
        first = true
        for i in [0...info.regexs.length]
          regexInfo = info.regexs[i]
          for matches in regexInfo.matches
            previousVersion = matches.version unless previousVersion?
            thisVersionConflict = previousVersion? and previousVersion != matches.version
            versionConflict = versionConflict || thisVersionConflict
            table.push [
              if first then info.file.name.bold else ""
              if not thisVersionConflict then matches.version.green.bold else matches.version.red.bold
              matches.match
              regexInfo.originalRegex
            ]
            first = false
      console.log table.toString()
      console.log()
      throw new Error "There was a version conflict. Aborting." if versionConflict
      infos = thisInfos

    .then ->
      # Now lets get the next tag version
      if program.tag
        tagVersion = program.tag
      else
        tagVersion = config.increaseVersion previousVersion

      # The next dev version
      if program.dev
        nextDevVersion = program.dev
      else
        nextDevVersion = config.increaseVersion(tagVersion) + "-dev"

    .then ->
      console.log "================================"
      console.log   "Previous version: " + previousVersion
      if program.rename
        console.log "Next version:     " + tagVersion.green
      else
        console.log "Tag version:      " + tagVersion.green
        console.log "Next dev version: " + nextDevVersion.blue

      console.log "================================"
      console.log()
    .then ->
      unless program.rename
        # Means there will be a tag so lets make sure there's a tag message
        if program.message
          tagMessage = program.message
        else
          utils.prompt("Enter your tag message: ")
          .then (message) ->
            tagMessage = message
    .then ->
      throw new Error "Invalid message." unless tagMessage or program.rename

      console.log "I'm going to:"
      if program.rename
        console.log " - rename all version occurences with " + "#{tagVersion}".green
      else
        console.log " - tag " + "#{tagVersion}".green + " with message: " + "#{tagMessage}".green
        console.log " - change the version to " + "#{nextDevVersion}".green + " afterwards"
        console.log " - merge the tag to " + "master".green + " after" unless program.nomerge
        console.log " - push --all and --tags" unless program.nopush

      console.log "(Beware that you are on the branch " + "#{branch}".red.bold + "!)" if branch isnt "develop"
      unless repoClean
        console.log()
        console.log("Warning: ".red.bold + "The repository is not clean. You should commit or stash all your changes.".red)

      console.log()
      utils.confirm "Do you want to continue? "
    .then (doContinue) ->
      return console.log "Aborting." unless doContinue
      console.log()
      console.log "Replacing #{previousVersion} with #{tagVersion}."
      config.replaceVersion infos, tagVersion
    .then ->
      return true if program.rename
      console.log "Committing the change."
      utils.command "git", "commit", "-am", "Upgrading version to #{tagVersion}"
    .then ->
      console.log "Tagging the commit with " + "#{tagMessage}".green + "."
      utils.command "git", "tag", "-a", tagVersion, "-m", tagMessage.replace(/\"/, '\\"')
    .then ->
      console.log "Tagging the commit with " + "#{tagMessage}".green + "."
      utils.command "git", "tag", "-a", tagVersion, "-m", tagMessage
    .then ->
      unless program.nomerge
        console.log "Checking out master."
        utils.command("git", "checkout", "master")
        .then ->
          console.log "Merging #{tagVersion}."
          utils.command("git", "merge", "--no-ff", tagVersion)
        .then ->
          console.log "Checking out #{branch} again."
          utils.command("git", "checkout", branch)
    .then ->
      console.log "Tagging the commit with " + "#{tagMessage}".green + "."
      





.then ->
  console.log()
  process.exit()
.fail (err) ->
  console.log()
  console.log "Error: ".red.bold + err.message.red
  console.log()
  process.exit 1





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
  



