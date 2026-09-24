#!/bin/sh
# Renders the README artwork and launch video from the HTML sources.
# Needs Google Chrome, Node, ffmpeg and img2webp (`brew install webp`).
set -e
cd "$(dirname "$0")"
ASSETS=../assets
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
FPS=30
SECONDS_LONG=12

[ -d node_modules ] || yarn install --silent

"$CHROME" --headless=new --disable-gpu --hide-scrollbars --default-background-color=00000000 \
    --window-size=1024,1024 --screenshot="$PWD/$ASSETS/icon.png" "file://$PWD/icon.html" 2>/dev/null
# The still hero is the moment "Copied" has just appeared.
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 \
    --window-size=1280,720 --screenshot="$PWD/$ASSETS/hero.png" "file://$PWD/anim.html?t=6.2" 2>/dev/null
node frames.mjs "file://$PWD/anim.html" build/frames $FPS $SECONDS_LONG 1.5

# Sound cues line up with the timeline constants in anim.html.
ffmpeg -v error -y -framerate $FPS -i build/frames/%04d.png \
    -i audio/bed.mp3 -i audio/whoosh.mp3 -i audio/typing.mp3 -i audio/pop.mp3 -i audio/whoosh.mp3 -i audio/paste.mp3 \
    -filter_complex "\
[1]atrim=0:$SECONDS_LONG,afade=t=in:d=0.4,afade=t=out:st=10.8:d=1.2,volume=0.45[bed];\
[2]adelay=950|950,volume=2[open];\
[3]adelay=2600|2600,volume=2.5[type];\
[4]adelay=5800|5800,volume=6[pop];\
[5]adelay=6600|6600,volume=0.9[close];\
[6]adelay=8400|8400,volume=1.3[paste];\
[bed][open][type][pop][close][paste]amix=inputs=6:normalize=0:duration=first,alimiter=limit=0.9[a]" \
    -map 0:v -map "[a]" -c:v libx264 -crf 20 -preset slow -pix_fmt yuv420p -c:a aac -b:a 160k \
    -movflags +faststart -t $SECONDS_LONG "$ASSETS/snicker-launch.mp4"

# Animated WebP autoplays in a README at a fraction of a GIF's size.
rm -rf build/webp && mkdir -p build/webp
ffmpeg -v error -i "$ASSETS/snicker-launch.mp4" -vf "fps=20,scale=1280:-1:flags=lanczos" build/webp/%04d.png
img2webp -loop 0 -lossy -q 70 -m 4 -d 50 build/webp/*.png -o "$ASSETS/hero.webp" >/dev/null
echo "Rendered icon.png, hero.png, hero.webp and snicker-launch.mp4 into docs/assets"
