#!/usr/bin/env bash

# Inital paths and filenames
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     XPUI_PATH="/usr/share/spotify/Apps";;
    Darwin*)    XPUI_PATH="/Applications/Spotify.app/Contents/Resources/Apps";;
esac
XPUI_SPA="xpui.spa"
XPUI_SPA_BAK="xpui.bak"

# Uninstall patch
echo "Removing patch..."
cd "$XPUI_PATH"
rm "$XPUI_SPA"
mv "$XPUI_SPA_BAK" "$XPUI_SPA"

echo "Patch removed successfully!"
