#!/usr/bin/env node


var
    fs = require('fs')
  , util = require('util')
  , spawn = require('child_process').spawn
  , version = '1.0.1-dev'
  , configFileUri = './.tagconfig'
  , versionRegex = '[0-9]+\\.[0-9]+\\.[0-9]+(?:-dev)?'
  , previousVersion
  , nextVersion
  , nextDevVersion
  , tagName
;



console.log("\nTag script version %s, config file: %s, Usage:", version, configFileUri);

console.log(" tag [ nextVersion [ nextDevVersion ] ]\n");
console.log(' # If `nextVersion` is not provided, the last digit will either be increased by one, or -dev removed.');
console.log(' # If `nextDevVersion` is not provided, it will be nextVersion-dev.');

nl();

try {
  
  var configStats = fs.statSync(configFileUri);

  if (!configStats.isFile()) {
    console.log('- Must create config file.')
  }



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
      each(regexInfos.matches, function(match) {
        if (extractVersion(match) !== previousVersion) throw new Error("Detected different version than '" + previousVersion + "' in file '" + fileInfo.name + "': " + match);
      });
      fileInfo.regexInfos.push(regexInfos);
    });

  });

  nl();

  console.log('Matches:');

  each(config.files, function(fileInfo) {
    each(fileInfo.regexInfos, function(regexInfo) {
      console.log('\n%s (%s)', fileInfo.name, regexInfo.original);
      each(regexInfo.matches, function(match) {
        console.log(' - %s', match);
      });
    });
  });

  nl();
  nl();


  // if ()
  if (process.argv[2]) nextVersion = process.argv[2];
  if (process.argv[3]) nextDevVersion = process.argv[3];


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
  console.log(' Current version:   %s', previousVersion);
  console.log(' Next version:      %s', nextVersion);
  console.log(' Next dev version:  %s', nextDevVersion);
  console.log(' Tag name:          %s', tagName);
  console.log('========================================');

  nl();
  console.log("Make sure you're on the right (develop) branch: ");

  var child;

// executes `pwd`
  spawnWithCallback('git', [ 'branch', '--color' ], function() {
    nl();
    console.log('Press enter to continue (Ctrl-c to abort)...');

    readFromStdIn(function (text) {
      if (text !== '\n') {
        console.log('Aborting.');
        process.exit();
      }

      // Let's go for it!
      replaceVersion(config.files, nextVersion);

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
                if (text !== 'Y\n' && text !== '\n') return;

                spawnWithCallback('git', [ 'checkout', 'master' ], function() {
                  console.log('Merging %s', tagName);
                  spawnWithCallback('git', [ 'merge', '--no-ff', tagName ], function() {
                    nl();
                    spawnWithCallback('git', [ 'checkout', 'develop' ], function() {
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
}
catch (e) {
  console.log('\n\nFatal error:\n\n%s', e.message);
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


function spawnWithCallback(command, arguments, callback) {
  command = spawn(command, arguments);

  command.stdout.pipe(process.stdout, { end: false });

  command.on('exit', function(code) {
    if (code === null) {
      console.error('Exec error: ', error);
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
    callback(text);
  };

  process.stdin.on('data', eventListener);
}


function nl() { console.log(); }