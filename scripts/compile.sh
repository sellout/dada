#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

for f in $(./scripts/find-dhall-files.sh -type f)
do
  # Echo the filename
  echo $f;
  # Compile the Dhall file
  TMPFILE=$(mktemp --tmpdir dhall-bhat.XXXXXXXXXX)
  ../dhall-haskell/.stack-work/dist/x86_64-osx-nix/Cabal-2.2.0.1/build/Dhall/dhall <<< $f >/dev/null 2>$TMPFILE || (cat $TMPFILE && exit 1)
  rm $TMPFILE
done
