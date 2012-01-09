#!/bin/bash

version=0.0.1
echo "Version $version"
echo



printUsage() {
  echo
  echo Usage:
  echo "  $0 versionFile [ versionX versionY versionZ [ versionNameAfter ] ]"
  echo
  echo If versionAfter is not provided, it will be versionName-dev.
  echo
  exit 1
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


echo "The line that will be replaced:"
grep "$versionRegex" "$versionFileUri"
echo

if [ $# -lt 4 ]; then
  printUsage;
fi


temporaryVersionFile="/tmp/version.$$"

versionName=$2.$3.$4;
versionNameAfter=${5:-$2.$3.$(( $4 + 1 ))-dev}


echo "Your version:     $versionName";
echo "The next version: $versionNameAfter";
echo "The version file: $versionFileUri";
echo
echo "Hit enter to continue..."
read

echo "Writing $versionName to $versionFileUri" &&
sed  "s/$versionRegex/$versionName/" "$versionFileUri" > "$temporaryVersionFile" && cat "$temporaryVersionFile" > "$versionFileUri" && rm "$temporaryVersionFile" &&
echo "Commiting the change" &&
git commit -am "Upgrading version to $versionName" &&
echo "Tagging the commit" &&
git tag -a "v$versionName" &&
echo "Writing $versionNameAfter to $versionFileUri" &&
sed  "s/$versionRegex/$versionNameAfter/" "$versionFileUri" > "$temporaryVersionFile" && cat "$temporaryVersionFile" > "$versionFileUri" && rm "$temporaryVersionFile" &&
git commit -am "Upgrading version to $versionNameAfter"

echo
