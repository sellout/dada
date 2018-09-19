find . \
     -not -path '*/\.*' \
     -not -path '*/docs/*' \
     -not -path '*/scripts/*' \
     -not -iname "*.md" \
     -not -iname "LICENSE" \
     -not -iname "Makefile" \
     "$@"
