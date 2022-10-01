#!/usr/bin/env bash

# Detect Installation Path
if [[ -d "~/Applications/Spotify.app" ]]; then
    XPUI_PATH="~/Applications/Spotify.app/Contents/Resources/Apps"
elif [[ -d "/Applications/Spotify.app" ]]; then
    XPUI_PATH="/Applications/Spotify.app/Contents/Resources/Apps"
else
    echo -e "Spotify.app not found.\nExiting..."
    exit
fi

# Inital paths and filenames
XPUI_SPA="xpui.spa"
XPUI_SPA_BAK="xpui.bak"

# Detect then uninstall patch
if [[ ! -f "$XPUI_PATH/$XPUI_SPA_BAK"]]; then
    echo -e "Backup file not found.\nExiting..."
    exit
else
    echo "Removing patch..."
    cd "$XPUI_PATH"
    rm "$XPUI_SPA"
    mv "$XPUI_SPA_BAK" "$XPUI_SPA"

    echo "Patch removed successfully!"
fi