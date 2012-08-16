
program = require "commander"
colors = require "colors"
Q = require "q"
utils = require "./utils"
fs = require "fs"
Config = require "./config"
git = require "gift"
repo = git process.cwd()
Table = require "cli-table"


separate = (char = "=", length = 79) ->
  string = []
  for i in [1..length]
    string.push char
  console.log()
  console.log string.join ""
  console.log()



program
  .version("2.0.5-dev")
  .usage("[options]")
  .option("-t, --tag <version>", "the tag if not incremental")
  .option("-d, --dev <version>", "the version you want to use after the tag")
  .option("-r, --rename", "rename only")
  .option("-m, --message [message]", "the tag message")
  .option("-a, --add", "add a file to the tagconfig")
  .option("--nomerge", "do not merge the tag to master")
  .option("--nopush", "do not push --all and --tags after tagging")
  .option("--nopull", "do not pull origin/master before mergin the tag to master")
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
      regex = regx || "###"
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
    tagName = null # Has a v in front of it
    nextDevVersion = null
    tagMessage = null

    Q.fcall(->
      unless config.config?
        throw new Error "No valid tagconfig file. Please see 'tag -h' on how to create one." 
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
              if not thisVersionConflict then matches.version.green else matches.version.red.bold
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

      tagName = "v#{tagVersion}"

      # The next dev version
      if program.dev
        nextDevVersion = program.dev
      else
        nextDevVersion = config.increaseVersion(tagVersion) + "-dev"

    .then ->
      separate "=", 35
      console.log   "Previous version: " + previousVersion
      if program.rename
        console.log "Next version:     " + tagVersion.green
      else
        console.log "Tag version:      " + tagVersion.green
        console.log "Tag name:        " + tagName.green
        console.log "Next dev version: " + nextDevVersion.blue

      separate "=", 35
    .then ->
      unless repoClean
        console.log("Warning: ".red.bold + "The repository is not clean. You should commit or stash all your changes.".red)
        console.log()

      unless program.rename
        # Means there will be a tag so lets make sure there's a tag message
        if program.message
          tagMessage = program.message
        else
          utils.prompt("Enter your tag message: ")
          .then (message) ->
            console.log()
            tagMessage = message
    .then ->
      throw new Error "Invalid message." unless tagMessage or program.rename

      console.log "I'm going to:"
      if program.rename
        console.log " - rename all version occurences with " + "#{tagVersion}".green
      else
        console.log " - create tag " + "#{tagName}".green + " with message: " + "#{tagMessage}".green
        console.log " - change the version to " + "#{nextDevVersion}".green
        console.log " - merge the tag " + "#{tagName}".green + " to " + "master".green unless program.nomerge
        console.log " - push --all and --tags" unless program.nopush

      console.log "(Beware that you are on the branch " + "#{branch}".red.bold + "!)" if branch isnt "develop"

      console.log()
      utils.confirm "Do you want to continue? "
    .then (doContinue) ->
      throw new Error "Aborting." unless doContinue
      separate()
      console.log "#{previousVersion}".green + " => ".blue + "#{tagVersion}".green + (if program.rename then ".".blue else " and committing the change.".blue)
      config.replaceVersion infos, tagVersion
    .then ->
      return true if program.rename
      console.log()
      utils.command("git", "commit", "-am", "Upgrading version to #{tagVersion}")
      .then ->
        separate "-"
        console.log "Creating tag ".blue + "#{tagName}".green + " with message ".blue + "#{tagMessage}".green + ".".blue
        utils.command "git", "tag", "-a", tagName, "-m", tagMessage
      .then ->
        separate "-"
        console.log "#{tagVersion}".green + " => ".blue + "#{nextDevVersion}".green + " and committing the change.".blue
        config.replaceVersion infos, nextDevVersion
      .then ->
        console.log()
        utils.command "git", "commit", "-am", "Upgrading version to #{nextDevVersion}"
      .then ->
        unless program.nomerge
          separate "-"
          console.log "Merging tag #{tagName} to master.".blue
          utils.command("git", "checkout", "master")
          .then ->
            unless program.nopull
              console.log()
              utils.command "git", "pull", "origin", "master" 
          .then ->
            console.log()
            utils.command "git", "merge", "--no-ff", tagName
          .then ->
            console.log()
            utils.command "git", "checkout", branch
      .then ->
        unless program.nopush
          separate "-"
          console.log "Pushing --all and --tag".blue
          utils.command("git", "push", "-v", "--all")
          .then ->
            utils.command("git", "push", "-v", "--tags")
    .then ->
      separate "-"
      console.log()
      console.log "Success :)".green





.then ->
  console.log()
  process.exit()
.fail (err) ->
  console.log()
  console.log "Error: ".red.bold + err.message.red
  console.log()
  process.exit 1



