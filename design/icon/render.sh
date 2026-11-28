#!/bin/sh
# Renders design/icon/porotos-icon.svg to the AppIcon set (1024x1024, no alpha).
set -e
cd "$(dirname "$0")/../.."
tmp=$(mktemp -d)
qlmanage -t -s 1024 -o "$tmp" design/icon/porotos-icon.svg >/dev/null 2>&1
# Round-tripping through JPEG drops the alpha channel.
sips -s format jpeg -s formatOptions 100 "$tmp/porotos-icon.svg.png" --out "$tmp/icon.jpg" >/dev/null
sips -s format png "$tmp/icon.jpg" --out Porotos/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png >/dev/null
rm -rf "$tmp"
sips -g pixelWidth -g pixelHeight -g hasAlpha Porotos/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
