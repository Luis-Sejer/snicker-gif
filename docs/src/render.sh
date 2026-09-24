#!/bin/sh
# Renders the README artwork and launch video from the HTML sources.
# Needs Google Chrome, Node, ffmpeg and img2webp (`brew install webp`).
set -e
cd "$(dirname "$0")"
ASSETS=../assets
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
FPS=30
VIDEO_SECONDS=15

[ -d node_modules ] || yarn install --silent

"$CHROME" --headless=new --disable-gpu --hide-scrollbars --default-background-color=00000000 \
    --window-size=1024,1024 --screenshot="$PWD/$ASSETS/icon.png" "file://$PWD/icon.html" 2>/dev/null
# The still hero is the moment "Copied" has just appeared.
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 \
    --window-size=1280,720 --screenshot="$PWD/$ASSETS/hero.png" "file://$PWD/anim.html?t=7.2" 2>/dev/null
node frames.mjs "file://$PWD/anim.html" build/frames $FPS $VIDEO_SECONDS 1.5

# Sound cues and voiceover lines are placed on the beats defined at the top of anim.html (in ms).
# The music ducks under the voice, and the 14s music loop plays twice to cover the 15s video.
ffmpeg -v error -y -framerate $FPS -i build/frames/%04d.png \
    -stream_loop 1 -i audio/bed.mp3 \
    -i audio/whoosh.mp3 -i audio/typing.mp3 -i audio/pop.mp3 -i audio/whoosh.mp3 -i audio/paste.mp3 \
    -i audio/vo_1.mp3 -i audio/vo_2.mp3 -i audio/vo_3.mp3 -i audio/vo_4.mp3 -i audio/vo_5.mp3 -i audio/vo_6.mp3 \
    -filter_complex "\
[1]atrim=0:$VIDEO_SECONDS,afade=t=in:d=0.4,afade=t=out:st=13.8:d=1.2,volume=0.5[bed];\
[2]adelay=950|950,volume=2[open];\
[3]adelay=3700|3700,volume=2.5[type];\
[4]adelay=6800|6800,volume=6[pop];\
[5]adelay=8000|8000,volume=0.9[close];\
[6]adelay=9800|9800,volume=1.3[paste];\
[7]adelay=100|100[v1];[8]adelay=1600|1600[v2];[9]adelay=3600|3600[v3];\
[10]adelay=6400|6400[v4];[11]adelay=8800|8800[v5];[12]adelay=11300|11300[v6];\
[v1][v2][v3][v4][v5][v6]amix=inputs=6:normalize=0,volume=1.6,asplit[voice][sidechain];\
[bed][sidechain]sidechaincompress=threshold=0.02:ratio=8:attack=15:release=350[ducked];\
[ducked][open][type][pop][close][paste][voice]amix=inputs=7:normalize=0:duration=first,alimiter=limit=0.9[a]" \
    -map 0:v -map "[a]" -c:v libx264 -crf 20 -preset slow -pix_fmt yuv420p -c:a aac -b:a 160k \
    -movflags +faststart -t $VIDEO_SECONDS "$ASSETS/snicker-launch.mp4"

# Animated WebP autoplays in a README at a fraction of a GIF's size.
rm -rf build/webp && mkdir -p build/webp
ffmpeg -v error -i "$ASSETS/snicker-launch.mp4" -vf "fps=20,scale=1280:-1:flags=lanczos" build/webp/%04d.png
img2webp -loop 0 -lossy -q 70 -m 4 -d 50 build/webp/*.png -o "$ASSETS/hero.webp" >/dev/null
echo "Rendered icon.png, hero.png, hero.webp and snicker-launch.mp4 into docs/assets"
