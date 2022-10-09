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

CACHE_PATH="${HOME}/Library/Caches/com.spotify.client"
XPUI_PATH="${INSTALL_PATH}/Contents/Resources/Apps"
XPUI_DIR="${XPUI_PATH}/xpui"
XPUI_BAK="${XPUI_PATH}/xpui.bak"
XPUI_SPA="${XPUI_PATH}/xpui.spa"
XPUI_JS="${XPUI_DIR}/xpui.js"
VENDOR_XPUI_JS="${XPUI_DIR}/vendor~xpui.js"

# Script flags
CACHE_FLAG='false'

while getopts 'c' flag; do
  case "${flag}" in
    c) 
      CACHE_FLAG='true'
      ;;
    *) 
      echo "Error: Flag not supported."
      exit
      ;;
  esac
done

# Perl command
PERL="perl -pi -w -e"

# Ad-related regex
AD_EMPTY_AD_BLOCK='s|adsEnabled:\!\K0|1|'
AD_PLAYLIST_SPONSORS='s|allSponsorships||'
AD_UPGRADE_BUTTON='s/(return|.=.=>)"free"===(.+?)(return|.=.=>)"premium"===/$1"premium"===$2$3"free"===/g'
AD_AUDIO_ADS='s|(case .:)return this.enabled=...+?(;case .:this.subscription=this.audioApi).+?(;case .)|$1$2.cosmosConnector.increaseStreamTime(-100000000000)$3|'
AD_BILLBOARD='s|.(\?\[..\(..leaderboard,)|false$1|'
AD_UPSELL='s|(Enables quicksilver in-app messaging modal",default:)(!0)|$1false|'

# Log-related regex
LOG_1='s|sp://logging/v3/\w+||g'
LOG_SENTRY='s|this\.getStackTop\(\)\.client=e|return;$&|'

# Credits
echo "************************"
echo "SpotX-Mac by @SpotX-CLI"
echo "************************"
echo

# Create backup and extract xpui.js
echo "Creating backup of xpui.spa..."
if [[ -f "${XPUI_PATH}/${XPUI_SPA_BAK}" ]]; then
  echo "Found xpui.bak, skipping backup..."
else
  echo "Creating backup of xpui.spa..."
  cp "${XPUI_SPA}" "${XPUI_BAK}"
fi

echo "Extracting xpui.js..."
unzip -qq "${XPUI_SPA}" -d "${XPUI_DIR}"
rm "${XPUI_SPA}"

# Remove Ads
echo "Applying SpotX patches..."

# Remove Empty ad block
echo "Removing empty ad block..."
$PERL "${AD_EMPTY_AD_BLOCK}" "${XPUI_JS}"

# Remove Playlist sponsors
echo "Removing playlist sponsors..."
$PERL "${AD_PLAYLIST_SPONSORS}" "${XPUI_JS}"

# Remove Upgrade button
echo "Removing upgrade button..."
$PERL "${AD_UPGRADE_BUTTON}" "${XPUI_JS}"

# Remove Audio ads
echo "Removing audio ads..."
$PERL "${AD_AUDIO_ADS}" "${XPUI_JS}"

# Remove billboard ads
echo "Removing billboard ads..."
$PERL "${AD_BILLBOARD}" "${XPUI_JS}"

# Remove logging
echo "Removing logging..."
$PERL "${LOG_1}" "${XPUI_JS}"
$PERL "${LOG_SENTRY}" "${VENDOR_XPUI_JS}"

# Rebuild xpui.spa
echo "Rebuilding xpui.spa..."

# Zip files inside xpui folder
(cd "${XPUI_DIR}"; zip -qq -r ../xpui.spa .)
rm -rf "${XPUI_DIR}"

# Delete app cache
if [[ "${CACHE_FLAG}" == "true" ]]; then
  echo "Clearing app cache..."
  rm -rf "$CACHE_PATH"
fi

echo -e "Patch applied successfully!\n"
