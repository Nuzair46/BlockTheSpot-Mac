#!/usr/bin/env bash

# Inital paths and filenames
APP_PATH="/Applications/Spotify.app"
if [[ -d "${HOME}${APP_PATH}" ]]; then
  INSTALL_PATH="${HOME}${APP_PATH}"
elif [[ -d "${APP_PATH}" ]]; then
  INSTALL_PATH="${APP_PATH}"
else
  echo -e "\nSpotify not found. Exiting...\n"
  exit; fi

CACHE_PATH="${HOME}/Library/Caches/com.spotify.client"
UPDATE_PATH="${HOME}/Library/Application Support/Spotify/PersistentCache/Update"
XPUI_PATH="${INSTALL_PATH}/Contents/Resources/Apps"
XPUI_DIR="${XPUI_PATH}/xpui"
XPUI_BAK="${XPUI_PATH}/xpui.bak"
XPUI_SPA="${XPUI_PATH}/xpui.spa"
XPUI_JS="${XPUI_DIR}/xpui.js"
XPUI_CSS="${XPUI_DIR}/xpui.css"
HOME_V2_JS="${XPUI_DIR}/home-v2.js"
VENDOR_XPUI_JS="${XPUI_DIR}/vendor~xpui.js"

# Script flags
CACHE_FLAG='false'
HIDE_PODCASTS_FLAG='false'
OLD_UI_FLAG='false'
PREMIUM_FLAG='false'
UPDATE_FLAG='false'

while getopts 'chopu' flag; do
  case "${flag}" in
    c) 
      CACHE_FLAG='true' ;;
    h)
      HIDE_PODCASTS_FLAG='true' ;;
    o)
      OLD_UI_FLAG='true' ;;
    p)
      PREMIUM_FLAG='true' ;;
    u)
      UPDATE_FLAG='true' ;;
    *) 
      echo "Error: Flag not supported."
      exit ;;
  esac
done

# Perl command
PERL="perl -pi -w -e"

# Ad-related regex
AD_EMPTY_AD_BLOCK='s|adsEnabled:!0|adsEnabled:!1|'
AD_PLAYLIST_SPONSORS='s|allSponsorships||'
AD_UPGRADE_BUTTON='s/(return|.=.=>)"free"===(.+?)(return|.=.=>)"premium"===/$1"premium"===$2$3"free"===/g'
AD_AUDIO_ADS='s|(case .:)return this.enabled=...+?(;case .:this.subscription=this.audioApi).+?(;case .)|$1$2.cosmosConnector.increaseStreamTime(-100000000000)$3|'
AD_BILLBOARD='s|.(\?\[....\.leaderboard,)|false$1|'
AD_UPSELL='s|(Enables quicksilver in-app messaging modal",default:)(!0)|$1false|'

# Home screen UI (new) | this will soon become obsolete
NEW_UI='s|(Enable the new home structure and navigation",values:.,default:)(..DISABLED)|$1true|'

# Hide Premium-only features
HIDE_DL_QUALITY='s/(.\("audio.play_bitrate_enumeration",.\)},)children:.*\(.,.\)}\).+\("audio.sync_bitrate_enumeration",.\)},(children:.*\(.,.\)}\)}\)]}\))/$1$2/'
HIDE_DL_ICON=' .BKsbV2Xl786X9a09XROH {display:none}'
HIDE_DL_MENU=' button.wC9sIed7pfp47wZbmU6m.pzkhLqffqF_4hucrVVQA {display:none}'
HIDE_VERY_HIGH=' #desktop\.settings\.streamingQuality>option:nth-child(5) {display:none}'

# Hide Podcasts/Episodes/Audiobooks on home screen
HIDE_PODCASTS='s/(\!Array.isArray\(.\)\|\|.===..length)/$1||e.children[0].key.includes('episode')||e.children[0].key.includes('show')/'

# Log-related regex
LOG_1='s|sp://logging/v3/\w+||g'
LOG_SENTRY='s|this\.getStackTop\(\)\.client=e|return;$&|'

# Spotify Connect unlock
CONNECT_1='s| connect-device-list-item--disabled||'
CONNECT_2='s|connect-picker.unavailable-to-control|spotify-connect|'
CONNECT_3='s|(className:.,disabled:)(..)|$1false|'
CONNECT_4='s/return (..isDisabled)(\?(..createElement|\(.{1,10}\))\(..,)/return false$2/'

# Credits
echo
echo "************************"
echo "SpotX-Mac by @SpotX-CLI"
echo "************************"
echo

# Create backup and extract xpui.js
if [[ -f "${XPUI_BAK}" ]]; then
  echo "Found xpui.bak, skipping backup..."
else
  echo "Creating backup of xpui.spa..."
  cp "${XPUI_SPA}" "${XPUI_BAK}"; fi

echo "Extracting xpui.js..."
unzip -qq "${XPUI_SPA}" -d "${XPUI_DIR}"
rm "${XPUI_SPA}"

echo "Applying SpotX patches..."

if [[ "${PREMIUM_FLAG}" == "false" ]]; then
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
  
  # Remove premium upsells
  echo "Removing premium upselling..."
  $PERL "${AD_UPSELL}" "${XPUI_JS}"
  
  # Remove Premium-only features
  echo "Removing premium-only features..."
  $PERL "${HIDE_DL_QUALITY}" "${XPUI_JS}"
  echo "${HIDE_DL_ICON}" >> "${XPUI_CSS}"
  echo "${HIDE_DL_MENU}" >> "${XPUI_CSS}"
  echo "${HIDE_VERY_HIGH}" >> "${XPUI_CSS}"
  
  # Unlock Spotify Connect
  echo "Unlocking Spotify Connect..."
  $PERL "${CONNECT_1}" "${XPUI_JS}"
  $PERL "${CONNECT_2}" "${XPUI_JS}"
  $PERL "${CONNECT_3}" "${XPUI_JS}"
  $PERL "${CONNECT_4}" "${XPUI_JS}"
else
  echo "Premium subscription setup selected..."; fi

# Remove logging
echo "Removing logging..."
$PERL "${LOG_1}" "${XPUI_JS}"
$PERL "${LOG_SENTRY}" "${VENDOR_XPUI_JS}"

# Handle UI view | this will soon become obsolete
if [[ "${OLD_UI_FLAG}" == "true" ]]; then
  echo "Skipping new home UI patch..."
else
  echo "Forcing new home UI..."
  $PERL "${NEW_UI}" "${XPUI_JS}"; fi

# Hide podcasts, episodes and audiobooks on home screen
if [[ "${HIDE_PODCASTS_FLAG}" == "true" ]]; then
  echo "Hiding non-music items on home screen..."
  $PERL "${HIDE_PODCASTS}" "${HOME_V2_JS}"; fi

# Delete app cache
if [[ "${CACHE_FLAG}" == "true" ]]; then
  echo "Clearing app cache..."
  rm -rf "$CACHE_PATH"; fi
  
# Update handling
if [[ "${UPDATE_FLAG}" == "true" ]]; then
  echo "Blocking updates..."
  if [[ -d "${UPDATE_PATH}" ]]; then
    chflags nouchg "${UPDATE_PATH}" 2>/dev/null
    rm -rf "${UPDATE_PATH}" 
    mkdir -p "${UPDATE_PATH}"
    chflags uchg "${UPDATE_PATH}"
  else
    mkdir -p "${UPDATE_PATH}"
    chflags uchg "${UPDATE_PATH}"; fi
else
  if [[ -d "${UPDATE_PATH}" ]]; then
    chflags nouchg "${UPDATE_PATH}" 2>/dev/null; fi; fi
  
# Rebuild xpui.spa
echo "Rebuilding xpui.spa..."
  
# Zip files inside xpui folder
(cd "${XPUI_DIR}"; zip -qq -r ../xpui.spa .)
rm -rf "${XPUI_DIR}"

echo -e "SpotX patches applied successfully!\n"
