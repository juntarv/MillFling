#!/bin/bash
# builds self-contained 390x844 mockups: parts/<name>.body.html -> <name>.html
cd "$(dirname "$0")"
for p in parts/*.body.html; do
  n=$(basename "$p" .body.html)
  {
    echo '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">'
    echo '<meta name="viewport" content="width=390, initial-scale=1">'
    echo "<title>MillFling — $n</title><style>"
    cat tokens.css
    cat components.css
    echo '</style></head><body>'
    cat "$p"
    echo '</body></html>'
  } > "$n.html"
  echo "built $n.html"
done
