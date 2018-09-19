#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

for f in $(./scripts/find-dhall-files.sh -type f)
do
  # Echo the filename
  echo $f;
  # Compile the Dhall file
  TMPFILE=$(mktemp --tmpdir dhall-bhat.XXXXXXXXXX)
  dhall <<< $f >/dev/null 2>$TMPFILE || (cat $TMPFILE && exit 1)
  rm $TMPFILE
done
