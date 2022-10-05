#!/usr/bin/env bash

# Inital paths and filenames
APP_PATH="/Applications/Spotify.app"
if [[ -d "${HOME}${APP_PATH}" ]]; then
    INSTALL_PATH="${HOME}${APP_PATH}"
elif [[ -d "${APP_PATH}" ]]; then
    INSTALL_PATH="${APP_PATH}"
else
    echo -e "\nSpotify not found. Exiting...\n"
    exit
fi
XPUI_PATH="${INSTALL_PATH}/Contents/Resources/Apps"
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