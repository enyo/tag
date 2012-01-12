#!/bin/bash

version="0.0.8-dev"
configFile=".tagconfig"

echo "(Tag script version $version, config file: $configFile)"
echo


if [ ! -f "$configFile" ]; then
  echo "There is no $configFile file.";
  echo
  echo "To create one, enter the files, separated by space, in which the tag script should replace versions:"
  read files
  echo "files=\"$files\"" > "$configFile"
  echo
  echo "Config file created."
  echo
fi



# Read the config
source $configFile

for i in $files; do
  if [ ! -f "$i" ]; then
    echo "The version file '$i' does not exist";
    echo
    exit 1;
  fi
done;





versionFileUri=${files%% *}


printUsage() {
  echo
  echo Usage:
  echo "  $0 [ versionName [ versionNameAfter ] ]"
  echo
  echo If versionNameAfter is not provided, it will be versionName-dev.
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
  local replace="$3"
  local temporaryVersionFile="/tmp/version.$$"

  echo "Replacing $2 with $3 in $1"
  sed  "s/$search/$replace/" "$file" > "$temporaryVersionFile" || fail
  cat "$temporaryVersionFile" > "$i" || fail
  rm "$temporaryVersionFile" || fail

}



versionRegex='[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\(-dev\)*'

matches=$(grep -c "$versionRegex" "$versionFileUri");


if [ $matches -eq 0 ]; then
  echo "Error: There have been no matches of any version number."
  echo
  exit
fi
if [ $matches -gt 1 ]; then
  echo "Multiple versions detected. The first match will be used."
fi


previousVersion=$(grep -o "$versionRegex" "$versionFileUri" | sed -n 1p)
previousVersionNoDev=${previousVersion/-dev/}


echo
echo "Detected version $previousVersion in line(s): "
for i in $files; do
  echo
  echo "$i: "
  grep "$previousVersion" "$i"
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


versionName=${1:-$nextVersion}

splitVersion "$versionName"
versionNameAfter=${2:-${parts[0]}.${parts[1]}.$(( ${parts[2]} + 1 ))-dev}

tagName="v$versionName"

echo "========================================";
echo " Current version:    $previousVersion";
echo " Next version:       $versionName";
echo " Next dev version:   $versionNameAfter";
echo " The version file:   $versionFileUri";
echo "========================================";
echo
echo "Make sure you're on the right (develop) branch:"
git branch
echo
echo -n "Hit enter to continue..."
read
echo
for i in $files; do
  replaceVersion "$i" "$previousVersion" "$versionName"
done
echo

echo "Commiting the change"
git commit -am "Upgrading version to $versionName" || fail
echo

echo -n "Tagging the commit. Enter your message: "
read tagMessage
git tag -a "$tagName" -m "$tagMessage" || fail
echo

for i in $files; do
  replaceVersion "$i" "$versionName" "$versionNameAfter"
done
echo

git commit -am "Upgrading version to $versionNameAfter" || fail
echo

if answer "Do you want to merge the tag $tagName to master?"; then
  echo
  echo "Checking out master"
  git checkout master || fail
  echo "Merging $tagName"
  git merge "$tagName" || fail
  echo "Checking out develop again"
  git checkout develop
fi


echo
