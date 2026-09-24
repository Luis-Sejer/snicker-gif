#!/bin/sh
# Tags a release. GitHub Actions then builds it with the KLIPY key secret and publishes it.
# Usage: ./release.sh 1.4.0
set -e
cd "$(dirname "$0")"
[ -n "$1" ] || { echo "Usage: ./release.sh <version>"; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "Commit your changes first."; exit 1; }
grep -q "^## \[$1\]" CHANGELOG.md || { echo "Add a '## [$1]' section to CHANGELOG.md first."; exit 1; }

git push origin HEAD
git tag "v$1"
git push origin "v$1"
echo "Tagged v$1. Follow the build with: gh run watch"
