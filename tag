#!/bin/bash

version="0.0.6"
echo "(Tag script version $version)"
echo



printUsage() {
  echo
  echo Usage:
  echo "  $0 versionFile [ versionName [ versionNameAfter ] ]"
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
  for i in $(echo -n $1 | tr . " "); do
    parts+=($i)
  done;
}


if [ $# -lt 1 ]; then
  printUsage;
fi

versionFileUri="$1"

if [ ! -f "$versionFileUri" ]; then
  echo "The version file '$versionFileUri' does not exist";
  echo
  exit 1;
fi

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
grep "$previousVersion" "$versionFileUri"
echo



wasDevVersion=1
if [ "$previousVersion" = "$previousVersionNoDev" ]; then wasDevVersion=0; fi

if [ "$wasDevVersion" -eq 1 ]; then
  nextVersion=$previousVersionNoDev;
else
  splitVersion "$previousVersionNoDev"

  nextVersion="${parts[0]}.${parts[1]}.$(( ${parts[2]} + 1 ))"
fi


temporaryVersionFile="/tmp/version.$$"

versionName=${2:-$nextVersion}

splitVersion "$versionName"

versionNameAfter=${3:-${parts[0]}.${parts[1]}.$(( ${parts[2]} + 1 ))-dev}

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
echo "Writing $versionName to $versionFileUri" &&
sed  "s/$previousVersion/$versionName/" "$versionFileUri" > "$temporaryVersionFile" && cat "$temporaryVersionFile" > "$versionFileUri" && rm "$temporaryVersionFile" &&
echo "Commiting the change" &&
git commit -am "Upgrading version to $versionName" &&
echo "Tagging the commit" &&
git tag -a "$tagName" &&
echo "Writing $versionNameAfter to $versionFileUri" &&
sed  "s/$versionName/$versionNameAfter/" "$versionFileUri" > "$temporaryVersionFile" && cat "$temporaryVersionFile" > "$versionFileUri" && rm "$temporaryVersionFile" &&
git commit -am "Upgrading version to $versionNameAfter"


if answer "Do you want to merge the tag $tagName to master?"; then
  echo "Checking out master"
  git checkout master
  echo "Merging $tagName"
  git merge "$tagName"
  echo "Checking out develop again"
  git checkout develop
fi


echo
