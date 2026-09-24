#!/bin/sh
# Tags, builds and publishes a GitHub release. Usage: ./release.sh 1.1.0
set -e
cd "$(dirname "$0")"
[ -n "$1" ] || { echo "Usage: ./release.sh <version>"; exit 1; }

git tag "v$1"
./build.sh
ditto -c -k --keepParent build/GifBar.app build/GifBar.zip
git push origin "v$1"
gh release create "v$1" build/GifBar.zip --title "GifBar $1" --generate-notes
