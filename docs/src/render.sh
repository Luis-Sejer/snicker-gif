#!/bin/sh
# Renders the README artwork from the HTML sources with headless Chrome.
set -e
cd "$(dirname "$0")"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
render() { "$CHROME" --headless=new --disable-gpu --hide-scrollbars --default-background-color=00000000 \
    --force-device-scale-factor="$4" --window-size="$2" --screenshot="$PWD/../assets/$3" "file://$PWD/$1" 2>/dev/null; }
render icon.html 1024,1024 icon.png 1
render hero.html 1280,720 hero.png 2
