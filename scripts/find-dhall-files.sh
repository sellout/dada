find . \
     -not -path '*/\.*' \
     -not -path '*/dist/*' \
     -not -path '*/dist-newstyle/*' \
     -not -path '*/docs/*' \
     -not -path '*/scripts/*' \
     -not -path '*/src/*' \
     -not -iname "*.cabal" \
     -not -iname "*.hs" \
     -not -iname "*.md" \
     -not -iname "LICENSE" \
     -not -iname "Makefile" \
     "$@"
