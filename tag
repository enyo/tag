#!/usr/bin/env node


var
    fs = require('fs')
  , util = require('util')
  , spawn = require('child_process').spawn
  , version = '1.1.6'
  // The first one will be used as default if no config is available.
  , possibleConfigFileUris = [ './.tagconfig.json', './.tagconfig', './tagconfig.json', './tagconfig' ]
  , configFileUri
  , versionRegex = '[0-9]+\\.[0-9]+\\.[0-9]+(?:-dev)?'
  , previousVersion
  , nextVersion
  , nextDevVersion
  , tagName
;



console.log("Usage (v%s): tag [nextVersion [nextDevVersion]] [--replace-only]", version);

nl();



function createConfig() {
  console.log("Neither of those possible config files exists: %s", possibleConfigFileUris.join(', '));
  nl();
  console.log("To create %s, please specify all files that should be parsed.", configFileUri);
  nl();


  var getFile = function(files, onFinishCallback) {
    nl();
    var file = {};
    console.log("Filename (Empty ends the list):");
    readFromStdIn(function(text) {
      if (text === '') {
        if (files.length === 0) {
          nl();
          console.error("You have to provide at least one filename.");
          nl();
          getFile(files, onFinishCallback);
        }
        else {
          onFinishCallback(files);
          return;
        }
      }
      else {
        file.name = text;
        file.regexs = [];
        nl();
        if (files.length === 0) {
          console.log("The version string defines the string that should be replaced with the actual version.");
          console.log("You can just use ### (which is the default) if you only have one version in the file, or a more detailed phrase, eg: version=\"###\"");
          console.log("If you actually want to specify a more complex regular expression edit the .tagconfig file after but be careful to use parentheses without capturing like this: (?:stuff).");
          nl();
        }
        console.log("Version string: [ ### ] ");
        readFromStdIn(function(text) {
          file.regexs.push(escapeRegexString(text ? text : '###'));
          files.push(file);
          getFile(files, onFinishCallback);
        });
      }
    });
  };

  getFile([], function(files) {
    var config = { files: files };
    nl();
    console.log('Writing config to %s...', configFileUri);
    fs.writeFileSync(configFileUri, JSON.stringify(config, null, 2), 'utf8');
    console.log('Successfully created the config.')
    console.log('Add %s to git and commit it. Then start this script again.', configFileUri);
    nl();
    nl();

  });


}



var i = 0;
while(i < possibleConfigFileUris.length && !configFileUri) {
  try {
    var configStats = fs.statSync(possibleConfigFileUris[i]);
    if (configStats.isFile()) {
      configFileUri = possibleConfigFileUris[i];
    }
  }
  catch (e) { }
  i ++;
}

if (!configFileUri) {
  configFileUri = possibleConfigFileUris[0];
  createConfig();
  return;
}

try {
  console.log("Using config file %s\n", configFileUri);

  try {
    var config = JSON.parse(fs.readFileSync(configFileUri, 'utf8'));
    if (!config.files) throw new Error('Did not contain a files list.');
  }
  catch (e) {
    throw new Error('Invalid config file (' + configFileUri + ')\nThe error: ' + e.message);
  }


  /**
   * Now go through the files, and add all additional information.
   */


   each(config.files, function(fileInfo) {
     
    fileInfo.content = fs.readFileSync(fileInfo.name, 'utf8');
    fileInfo.regexInfos = [ ];

    each(fileInfo.regexs, function(regex) {
      var regexInfos = {
        original: regex
      };
      var matchCount = regex.match(/###/g) ? regex.match(/###/g).length : 0;
      if (matchCount !== 1) {
        throw new Error('The regular expression did contain ' + matchCount + ' occurences of ### for file: ' + fileInfo.name + ' (' + regex + ')');
      }
      regexInfos.complete = new RegExp('(' + regex.replace('###', ')(' + versionRegex + ')(') + ')', 'gm');
      regexInfos.matches = fileInfo.content.match(regexInfos.complete);
      if (!regexInfos.matches) throw new Error('No match found in file ' + fileInfo.name + ' with regex: ' + regex);
      // if (regexInfos.matches.length > 1) {
      //   console.log('---------------------------------------------------------------------------------------------');
      //   console.log(' WARNING: Multiple matches found in "%s" with regex "%s"', fileInfo.name, regex);
      //   console.log('---------------------------------------------------------------------------------------------');
      // }

      if (!previousVersion) {
        previousVersion = extractVersion(regexInfos.matches[0]);
      }
      fileInfo.regexInfos.push(regexInfos);
    });

  });

  nl();

  console.log(color('Matches:', 'underline'));

  var error;
  each(config.files, function(fileInfo) {
    each(fileInfo.regexInfos, function(regexInfo) {
      console.log('\nFile: %s (Regular expression: %s)', color(fileInfo.name, 'green'), color(regexInfo.original, 'green'));
      each(regexInfo.matches, function(match, i) {
        var rightVersion = extractVersion(match) === previousVersion;
        var matchDisplay;
        if (rightVersion && i === 0) {
          matchDisplay = match;
        }
        else if (!rightVersion) {
          error = "Detected different version than '" + previousVersion + "' in file '" + fileInfo.name + "': " + match;
          matchDisplay = color(match, 'red_bg') + color(' (Error: wrong version)', 'red');
        }
        else {
          matchDisplay = color(match, 'red') + ' (Warning: multiple matches)';
        }
        console.log(' - %s', matchDisplay);
      });
    });
  });

  if (error) throw new Error(error);

  nl();
  nl();



  var replaceOnly = false;
  var argCount = 0;
  for (var i = 2; i < process.argv.length; i ++) {
    var thisArg = process.argv[i];
    if (thisArg === '--replace-only') replaceOnly = true;
    else {
      if (argCount === 0) nextVersion = thisArg;
      else if (argCount === 1) nextDevVersion = thisArg;
      argCount ++;
    }
  }


  if (!nextVersion) {
    var devRegex = /\-dev$/;
    if (devRegex.test(previousVersion)) {
      nextVersion = previousVersion.replace(devRegex, '');
    }
    else {
      nextVersion = increaseLastVersion(previousVersion);
    }
  }

  if (!nextDevVersion) {
    nextDevVersion = increaseLastVersion(nextVersion) + '-dev';
  }

  tagName = 'v' + nextVersion;

  console.log('========================================');
  console.log(' Current version:    %s', color(previousVersion, 'red+bold'));
  console.log(' Next version:       %s', color(nextVersion, 'green'));
  if (!replaceOnly) console.log(' Tag name:          %s', color(tagName, 'green'));
  if (!replaceOnly) console.log(' Next dev version:   %s', color(nextDevVersion, 'blue'));
  console.log('========================================');

  nl();
  console.log("Make sure you're on the right (develop) branch: ");

  var child;

// executes `pwd`
  spawnWithCallback('git', [ 'branch', '--color' ], function() {
    nl();
    console.log('Press enter to continue (Ctrl-c to abort)...');

    readFromStdIn(function (text) {
      if (text !== '') {
        console.log('Aborting.');
        process.exit();
      }

      // Let's go for it!
      replaceVersion(config.files, nextVersion);

      if (replaceOnly) {
        console.log('Replacing only, so stopping here.');
        nl();
      }
      else {
        console.log('Commiting the change.');
        spawnWithCallback('git', [ 'commit', '-am', 'Upgrading version to ' + nextVersion ], function() {
          nl();
          console.log('Tagging the commit. Enter your message: ')
          readFromStdIn(function (text) {
            nl();
            spawnWithCallback('git', [ 'tag', '-a', tagName, '-m', text.replace(/\"/, '\\"') ], function() {
              replaceVersion(config.files, nextDevVersion);
              spawnWithCallback('git', [ 'commit', '-am', 'Upgrading version to ' + nextDevVersion ], function() {
                nl();
                console.log('Do you want to merge the tag %s to master? [ Y n ]', tagName);
                readFromStdIn(function(text) {
                  nl();
                  if (text !== 'Y' && text !== '') return;
                  console.log('Checking out master');
                  spawnWithCallback('git', [ 'checkout', 'master' ], function() {
                    nl();
                    console.log('Merging %s', tagName);
                    spawnWithCallback('git', [ 'merge', '--no-ff', tagName ], function() {
                      nl();
                      console.log('Checking out develop again');
                      spawnWithCallback('git', [ 'checkout', 'develop' ], function() {
                        nl();
                        console.log('Do you want to push --all and push --tags? [ Y n ]');
                        readFromStdIn(function(text) {
                          nl();
                          if (text !== 'Y' && text !== '') return;
                          spawnWithCallback('git', [ 'push', '-v', '--all' ], function() {
                            spawnWithCallback('git', [ 'push', '-v', '--tags' ], function() {
                              nl();
                            });
                          });
                        });
                      });
                    });
                  });
                });
              });
            });
          });
        });
      }
    });
  });
}
catch (e) {
  console.log('\n\nFatal error:\n\n%s', color(e.message, 'red+bold'));
  nl();
}

function each(list, callback) {
  for (var i = 0; i < list.length; i ++) {
    callback(list[i], i);
  }
}

function extractVersion(string) {
  var matches = string.match(new RegExp(versionRegex));
  if (!matches || matches.length < 1 || matches.length > 1) throw new Error("Could not extract version out of '" + string + "'");
  return matches[0];
}

function increaseLastVersion(string) {
  var splitVersion = string.split('.');
  splitVersion[2] ++;
  return splitVersion.join('.');
}

function replaceVersion(files, version) {
  each(files, function(fileInfo) {
    var replacedContent = fileInfo.content;
    each(fileInfo.regexInfos, function(regexInfo) {
      replacedContent = replacedContent.replace(regexInfo.complete, '$1' + version + '$3');
    });
    fs.writeFileSync(fileInfo.name, replacedContent, 'utf8');
  });
}


function spawnWithCallback(commandString, arguments, callback) {
  command = spawn(commandString, arguments);

  command.stdout.pipe(process.stdout, { end: false });
  command.stderr.pipe(process.stderr, { end: false });

  command.on('exit', function(code) {
    if (code === null || code !== 0) {
      console.error('Command (%s) exited with code: %d', commandString, code);
      process.exit();
      return;
    }
    callback();
  });
}

function readFromStdIn(callback) {
  process.stdin.resume();
  process.stdin.setEncoding('utf8');

  var eventListener = function(text) {
    process.stdin.pause();
    process.stdin.removeListener('data', eventListener);
    callback(text.replace(/^\s+|\s+$/g, ""));
  };

  process.stdin.on('data', eventListener);
}

function escapeRegexString(string) {
  return string.replace(/[-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
}

function nl() { console.log(); }



/**
 * Taken from: https://github.com/loopj/commonjs-ansi-color
 */
function color(str, color) {

  var ANSI_CODES = {
    "off": 0,
    "bold": 1,
    "italic": 3,
    "underline": 4,
    "blink": 5,
    "inverse": 7,
    "hidden": 8,
    "black": 30,
    "red": 31,
    "green": 32,
    "yellow": 33,
    "blue": 34,
    "magenta": 35,
    "cyan": 36,
    "white": 37,
    "black_bg": 40,
    "red_bg": 41,
    "green_bg": 42,
    "yellow_bg": 43,
    "blue_bg": 44,
    "magenta_bg": 45,
    "cyan_bg": 46,
    "white_bg": 47
  };

  if(!color) return str;

  var color_attrs = color.split("+");
  var ansi_str = "";
  for(var i=0, attr; attr = color_attrs[i]; i++) {
    ansi_str += "\033[" + ANSI_CODES[attr] + "m";
  }
  ansi_str += str + "\033[" + ANSI_CODES["off"] + "m";
  return ansi_str;
};
