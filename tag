#!/bin/bash

echo

if [ $# -ne 3 ] && [ $# -ne 4 ]; then

  echo Usage:
  echo "  $0 versionX versionY versionZ [ versionNameAfter ];"
  echo
  echo If versionAfter is not provided, it will be versionName-dev
  echo
  exit 1;

fi

versionName=$1.$2.$3;
versionNameAfter=${4:-$1.$2.$(( $3 + 1 ))-dev}



echo "Your version:     $versionName";
echo "The next version: $versionNameAfter";
echo
echo "Hit enter to continue..."
read

echo

#sed  "s/define[[:space:]]*([[:space:]]*'RINCEWIND_VERSION'[[:space:]]*,[[:space:]]*'[^)]*'[[:space:]]*)[[:space:]]*;/test/" ./rincewind.php
