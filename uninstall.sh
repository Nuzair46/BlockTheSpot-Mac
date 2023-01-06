#!/usr/bin/env bash

APP_PATH="/Applications/Spotify.app"
PATH_FLAG='false'

while getopts 'P:' flag; do
  case "${flag}" in
  P)
    APP_PATH="${OPTARG}"
    PATH_FLAG='true'
    ;;
  *)
    echo "Error: Flag not supported."
    exit
    ;;
  esac
done

# Inital paths and filenames
if [[ "${PATH_FLAG}" == 'false' ]]; then
  if [[ -d "${HOME}${APP_PATH}" ]]; then
    INSTALL_PATH="${HOME}${APP_PATH}"
  elif [[ -d "${APP_PATH}" ]]; then
    INSTALL_PATH="${APP_PATH}"
  else
    echo -e "\nSpotify not found. Exiting...\n"
    exit
  fi
else
  if [[ -d "${APP_PATH}" ]]; then
    INSTALL_PATH="${APP_PATH}"
  else
    echo -e "\nSpotify not found. Exiting...\n"
    exit
  fi
fi
XPUI_PATH="${INSTALL_PATH}/Contents/Resources/Apps"
XPUI_SPA="${XPUI_PATH}/xpui.spa"
XPUI_BAK="${XPUI_PATH}/xpui.bak"

# Check for backup file
if [[ ! -f "${XPUI_BAK}" ]]; then
  echo -e "Backup file not found.\nExiting...\n"
  exit 
fi

# Uninstall patch
echo "Removing patch..."
rm "${XPUI_SPA}"
mv "${XPUI_BAK}" "${XPUI_SPA}"

echo -e "Patch removed successfully!\n"
