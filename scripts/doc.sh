#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

project=$(basename -- $(realpath "./"))
type_pattern='Type$'

DHALL=../dhall-haskell/.stack-work/dist/x86_64-osx-nix/Cabal-2.2.0.1/build/Dhall/dhall

echo '<html>'
echo '<head>'
echo '<title>'$project'</title>'
echo '<meta http-equiv="Content-Type" content="text/html; charset=utf-8">'
echo '</head>'
echo '<body>'
echo '<h1>'$project'</h1>'

for f in $(./scripts/find-dhall-files.sh)
do
    if [ -d "$f" ]; then
        echo '<h2 style="background-color: #bbb; width: 100%">'$f'</h2>'
    else
        type=$($DHALL resolve <<< $f | $DHALL type)
        if [[ $type =~ $type_pattern ]] ; then
            echo "<h3>"$(basename -- "$f")" (type)</h3>";
            echo '<dl>'
            echo '<dt>kind</dt><dd><pre>'
            echo "$type"
            echo '</pre></dd>'
            echo '<dt>type</dt><dd><pre>'
            $DHALL <<< $f
            echo '</pre></dd>'
            echo '</dl>'
        else
            echo "<h3>"$(basename -- "$f")" (term)</h3>";
            echo '<dl>'
            echo '<dt>type</dt><dd><pre>'
            echo "$type"
            echo '</pre></dd>'
            echo '</dl>'
        fi
    fi
done

echo '</body></html>'
