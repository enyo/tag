#!/bin/bash

version="0.0.9-dev"
configFile=".tagconfig"



echo "(Tag script version $version, config file: $configFile)"
echo


escapeRegex() {
  local regex="$1"
  printf "%s" "$regex" | sed -e 's/[\/&]/\\&/g';
}

escapeString() {
  local string="$1"
  printf "%s" "$string" | sed -e "s/[']/\\\\&/g";
}


versionRegex='[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\(-dev\)*'


createConfig() {
  local filename=""
  local versionString=""
  local i=0

  echo "There is no $configFile file.";
  echo
  echo "To create one, please specify all files that should be parsed."

  echo "# You can replace the regexs with any regular expression you like," > "$configFile"
  echo "# but make sure you leave the version with the parentheses intact. " >> "$configFile"
  echo "# You must not add additional parentheses before the version." >> "$configFile"
  echo "" >> "$configFile"

  while [ true ];
  do
    echo
    echo -n "Filename (Empty ends the list): "
    read filename
    if [ "$filename" == "" ]; then
      if [ $i -eq 0 ]; then echo "You must specify at least one filename!"; continue; fi
      break;
    fi
    echo "files[$i]='$filename'" >> "$configFile"

    if [ $i -eq 0 ]; then
      echo
      echo "The version string defines the string that should be replaced with the actual version."
      echo "You can just use ### (which is the default) if you only have one version in the file, or a more detailed phrase, eg: version=\"###\""
      echo "If you actually want to specify a more complex regular expression edit the .tagconfig file after."
      echo
    fi

    echo -n "Version string (###): "
    read versionString

    if [ "$versionString" == "" ]; then versionString="###"; fi

    versionString=$( escapeRegex "$versionString" )
    versionString=$( printf "%s" "$versionString" | sed -e "s/###/($versionRegex)/g" )
    versionString=$( escapeString "$versionString" )

    echo "regexs[$i]='$versionString'" >> "$configFile"

    i=$(( $i + 1 ));
  done
  echo
  echo "Config file created."
  echo "Add $configFile to git and commit it. Then start this script again."
  echo
  exit  
}


if [ ! -f "$configFile" ]; then
  createConfig
fi




##
## The config is created, so let's start the actual script.
##


#
# Helper functions
#
printUsage() {
  echo
  echo Usage:
  echo "  $0 [ nextVersion [ nextDevVersion ] ]"
  echo
  echo If nextDevVersion is not provided, it will be nextVersion-dev.
  echo
  exit 1
}

answer() {
  local answer
  echo -n "$1 (Y n) "
  read answer

  if [ "$answer" = '' ] || [ "$answer" = 'Y' ] || [ "$answer" = 'y' ]; then
    return 0;
  else
    return 1;
  fi
}

parts=()

splitVersion() {
  parts=()
  for i in $(echo -n $1 | tr . " "); do
    parts+=($i)
  done;
}

fail() {
  echo "Command failed. Exiting."
  echo
  exit
}

replaceVersion() {
  local file="$1"
  local search="$2"
  # local search="lkjsdf"
  local replace="$3"
  local temporaryVersionFile="/tmp/version.$$"

  echo "Replacing $search with $replace in $file"
  sed  "s/$search/$replace/" "$file"
  echo sed  "s/$search/$replace/" "$file"
  exit;
  sed  "s/$search/$replace/" "$file" > "$temporaryVersionFile" || fail
  cat "$temporaryVersionFile" > "$file" || fail
  rm "$temporaryVersionFile" || fail

}



# Read the config
source $configFile

#
# First check if the defined files actually exist and all contain the version.
#


fileCount=${#files[*]}

i=0
foundVersionCount=0
previousVersion=""

for (( i=0; i<$fileCount; i++ ))
do
  f=${files[$i]}
  regex=${regexs[$i]}

  matchCountInFile=0

  f=${f%% *} # Remove all whitespace at the end

  if [ ! -f "$f" ]; then
    echo "The version file '$f' does not exist";
    echo
    exit 1;
  fi

  while read line; do

    [[ $line =~ $regex ]] || continue

    if [ $matchCountInFile -eq 1 ]; then echo "========================================================"; echo " WARNING: multiple matches in file '$f'"; echo "========================================================"; fi;

    matchCountInFile=$(( $matchCountInFile + 1 ))

    thisFoundVersion="${BASH_REMATCH[1]}"

    if [ "$previousVersion" == "" ]; then
      previousVersion="$thisFoundVersion";
    elif [ "$previousVersion" != "$thisFoundVersion" ]; then
      echo
      echo "Error!"
      echo "Two different versions have been detected."
      echo "The first version found was $previousVersion, and another version ($thisFoundVersion) was found in file: $f"
      echo
      exit 1
    fi

    foundVersionMatches[$foundVersionCount]="'$f': $line"
    foundVersionCount=$(( $foundVersionCount + 1 ));
  done < $f

done;




previousVersionNoDev=${previousVersion/-dev/}


echo
echo "Detected version $previousVersion in line(s): "
echo

for (( i=0; i<$foundVersionCount; i++ ))
do
  echo ${foundVersionMatches[$i]}
done
echo


wasDevVersion=1
if [ "$previousVersion" = "$previousVersionNoDev" ]; then wasDevVersion=0; fi

if [ "$wasDevVersion" -eq 1 ]; then
  nextVersion=$previousVersionNoDev;
else
  splitVersion "$previousVersionNoDev"

  nextVersion="${parts[0]}.${parts[1]}.$(( ${parts[2]} + 1 ))"
fi


nextVersion=${1:-$nextVersion}

splitVersion "$nextVersion"
nextDevVersion=${2:-${parts[0]}.${parts[1]}.$(( ${parts[2]} + 1 ))-dev}

tagName="v$nextVersion"

echo "========================================";
echo " Current version:    $previousVersion";
echo " Next version:       $nextVersion";
echo " Next dev version:   $nextDevVersion";
echo "========================================";
echo
echo "Make sure you're on the right (develop) branch:"
git branch
echo
echo -n "Hit enter to continue..."
read
echo
for (( i=0; i<$fileCount; i++ ))
do
  f=${files[$i]}
  regex=${regexs[$i]}
  replaceVersion "$f" "$regex" "$nextVersion"
done
echo

exit

echo "Commiting the change"
git commit -am "Upgrading version to $nextVersion" || fail
echo

echo -n "Tagging the commit. Enter your message: "
read tagMessage
git tag -a "$tagName" -m "$tagMessage" || fail
echo

for i in $files; do
  replaceVersion "$i" "$nextVersion" "$nextDevVersion"
done
echo

git commit -am "Upgrading version to $nextDevVersion" || fail
echo

if answer "Do you want to merge the tag $tagName to master?"; then
  echo
  echo "Checking out master"
  git checkout master || fail
  echo "Merging $tagName"
  git merge --no-ff "$tagName" || fail
  echo "Checking out develop again"
  git checkout develop
fi


echo
