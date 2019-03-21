#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
DHALL=dhall
for f in $(./scripts/find-dhall-files.sh -type f)
do
  # Echo the filename
  echo $f;
  $DHALL freeze --inplace $f
done
