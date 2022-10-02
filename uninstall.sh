#!/usr/bin/env bash

# Inital paths and filenames
if [[ -d "${HOME}/Applications/Spotify.app" ]]; then
    XPUI_PATH="${HOME}/Applications/Spotify.app/Contents/Resources/Apps"
elif [[ -d "/Applications/Spotify.app" ]]; then
    XPUI_PATH="/Applications/Spotify.app/Contents/Resources/Apps"
else
    echo -e "Spotify.app not found.\nExiting...\n"
    exit
fi
XPUI_SPA="xpui.spa"
XPUI_SPA_BAK="xpui.bak"

# Check for backup file
if [[ ! -f "$XPUI_PATH/$XPUI_SPA_BAK"]]; then
    echo -e "Backup file not found.\nExiting...\n"
    exit
fi

# Uninstall patch
echo "Removing patch..."
cd "$XPUI_PATH"
rm "$XPUI_SPA"
mv "$XPUI_SPA_BAK" "$XPUI_SPA"

echo -e "Patch removed successfully!\n"