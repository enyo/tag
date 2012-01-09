#!/bin/bash

version="0.0.5-dev"
echo "Version $version"
echo



printUsage() {
  echo
  echo Usage:
  echo "  $0 versionFile [ versionX versionY versionZ [ versionNameAfter ] ]"
  echo
  echo If versionNameAfter is not provided, it will be versionName-dev.
  echo
  exit 1
}

answer() {
  local answer
  echo -n "$1 (Y n)"
  read answer

  if [ "$answer" = '' ] || [ "$answer" = 'Y' ] || [ "$answer" = 'y' ]; then
    return 0;
  else
    return 1;
  fi
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

if [ $matches -ne 1 ]; then
  echo "Error: There have been $matches matches of a version number."
  echo
  if [ $matches -gt 1 ]; then
    echo "The lines that matched:"
    grep "$versionRegex" "$versionFileUri"
  fi
  echo
  exit
fi

foundVersion=$(grep -o "$versionRegex" "$versionFileUri")

echo
echo -n "Detected version $foundVersion in line: "
grep "$versionRegex" "$versionFileUri"
echo

#xxx=${foundVersion/-dev/}
#echo $xxx;

if [ $# -lt 4 ]; then
  printUsage;
fi


temporaryVersionFile="/tmp/version.$$"

versionName=$2.$3.$4;
versionNameAfter=${5:-$2.$3.$(( $4 + 1 ))-dev}

tagName="v$versionName"


echo "Your version:     $versionName";
echo "The next version: $versionNameAfter";
echo "The version file: $versionFileUri";
echo
echo "Make sure you're on the right (develop) branch:"
git branch
echo
echo "Hit enter to continue..."
read

echo "Writing $versionName to $versionFileUri" &&
sed  "s/$versionRegex/$versionName/" "$versionFileUri" > "$temporaryVersionFile" && cat "$temporaryVersionFile" > "$versionFileUri" && rm "$temporaryVersionFile" &&
echo "Commiting the change" &&
git commit -am "Upgrading version to $versionName" &&
echo "Tagging the commit" &&
git tag -a "$tagName" &&
echo "Writing $versionNameAfter to $versionFileUri" &&
sed  "s/$versionRegex/$versionNameAfter/" "$versionFileUri" > "$temporaryVersionFile" && cat "$temporaryVersionFile" > "$versionFileUri" && rm "$temporaryVersionFile" &&
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
