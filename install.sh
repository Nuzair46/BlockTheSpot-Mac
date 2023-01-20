#!/usr/bin/env bash

SPOTX_VERSION="1.2.3.1115-1"

# dependencies check
command -v perl >/dev/null || { echo -e "\nperl was not found, exiting...\n" >&2; exit 1; }
command -v unzip >/dev/null || { echo -e "\nunzip was not found, exiting...\n" >&2; exit 1; }
command -v zip >/dev/null || { echo -e "\nzip was not found, exiting...\n" >&2; exit 1; }

# Script flags
APP_PATH="/Applications/Spotify.app"
CACHE_FLAG='false'
EXCLUDE_FLAG=''
EXPERIMENTAL_FLAG='false'
FORCE_FLAG='false'
HIDE_PODCASTS_FLAG='false'
OLD_UI_FLAG='false'
PATH_FLAG='false'
PREMIUM_FLAG='false'
UPDATE_FLAG='false'
CUSTOM_APP_PATH='false'

while getopts 'cefhopuP:' flag; do
  case "${flag}" in
  c) CACHE_FLAG='true' ;;
  E) EXCLUDE_FLAG+=("${OPTARG}") ;;
  e) EXPERIMENTAL_FLAG='true' ;; #currently disabled
  f) FORCE_FLAG='true' ;;
  h) HIDE_PODCASTS_FLAG='true' ;;
  o) OLD_UI_FLAG='true' ;;
  p) PREMIUM_FLAG='true' ;;
  P)
    APP_PATH="${OPTARG}"
    PATH_FLAG='true'
    ;;
  u) UPDATE_FLAG='true' ;;
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

# Find client version
CLIENT_VERSION=$(awk '/CFBundleShortVersionString/{getline; print}' "${INSTALL_PATH}/Contents/Info.plist" | cut -d\> -f2- | rev | cut -d. -f2- | rev)

# Version function for version comparison
function ver { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

# Handle multiple "exclude" flags if desired
for EXCLUDE_VAL in "${EXCLUDE_FLAG[@]}"; do
  if [[ "${EXCLUDE_VAL}" == "leftsidebar" ]]; then EX_LEFTSIDEBAR='true'; fi
done

# Perl command
PERL="perl -pi -w -e"

# Ad-related regex
AD_EMPTY_AD_BLOCK='s|adsEnabled:!0|adsEnabled:!1|'
AD_PLAYLIST_SPONSORS='s|allSponsorships||'
AD_UPGRADE_BUTTON='s/(return|.=.=>)"free"===(.+?)(return|.=.=>)"premium"===/$1"premium"===$2$3"free"===/g'
AD_AUDIO_ADS='s/(case .:|async enable\(.\)\{)(this.enabled=.+?\(.{1,3},"audio"\),|return this.enabled=...+?\(.{1,3},"audio"\))((;case 4:)?this.subscription=this.audioApi).+?this.onAdMessage\)/$1$3.cosmosConnector.increaseStreamTime(-100000000000)/'
AD_BILLBOARD='s|.(\?\[.{1,6}[a-zA-Z].leaderboard,)|false$1|'
AD_UPSELL='s|(Enables quicksilver in-app messaging modal",default:)(!0)|$1false|'

# Experimental (A/B test) features
ENABLE_ADD_PLAYLIST='s|(Enable support for adding a playlist to another playlist",default:)(!1)|$1true|s'
ENABLE_BAD_BUNNY='s|(Enable a different heart button for Bad Bunny",default:)(!1)|$1true|s'
ENABLE_BALLOONS='s|(Enable showing balloons on album release date anniversaries",default:)(!1)|$1true|s'
ENABLE_BLOCK_USERS='s|(Enable block users feature in clientX",default:)(!1)|$1true|s'
ENABLE_CAROUSELS='s|(Use carousels on Home",default:)(!1)|$1true|s'
ENABLE_CLEAR_DOWNLOADS='s|(Enable option in settings to clear all downloads",default:)(!1)|$1true|s'
ENABLE_DEVICE_LIST_LOCAL='s|(Enable splitting the device list based on local network",default:)(!1)|$1true|s'
ENABLE_DISCOG_SHELF='s|(Enable a condensed disography shelf on artist pages",default:)(!1)|$1true|s'
ENABLE_ENHANCE_PLAYLIST='s|(Enable Enhance Playlist UI and functionality for end-users",default:)(!1)|$1true|s'
ENABLE_ENHANCE_SONGS='s|(Enable Enhance Liked Songs UI and functionality",default:)(!1)|$1true|s'
ENABLE_EQUALIZER='s|(Enable audio equalizer for Desktop and Web Player",default:)(!1)|$1true|s'
ENABLE_FOLLOWERS_ON_PROFILE='s|(Enable a setting to control if followers and following lists are shown on profile",default:)(!1)|$1true|s'
ENABLE_FORGET_DEVICES='s|(Enable the option to Forget Devices",default:)(!1)|$1true|s'
ENABLE_IGNORE_REC='s|(Enable Ignore In Recommendations for desktop and web",default:)(!1)|$1true|s'
ENABLE_LIKED_SONGS='s|(Enable Liked Songs section on Artist page",default:)(!1)|$1true|s'
ENABLE_LYRICS_CHECK='s|(With this enabled, clients will check whether tracks have lyrics available",default:)(!1)|$1true|s'
ENABLE_LYRICS_MATCH='s|(Enable Lyrics match labels in search results",default:)(!1)|$1true|s'
ENABLE_PATHFINDER_DATA='s|(Fetch Browse data from Pathfinder",default:)(!1)|$1true|s'
ENABLE_PLAYLIST_CREATION_FLOW='s|(Enables new playlist creation flow in Web Player and DesktopX",default:)(!1)|$1true|s'
ENABLE_PLAYLIST_PERMISSIONS_FLOWS='s|(Enable Playlist Permissions flows for Prod",default:)(!1)|$1true|s'
ENABLE_PODCAST_PLAYBACK_SPEED='s|(playback speed range from 0.5-3.5 with every 0.1 increment",default:)(!1)|$1true|s'
ENABLE_PODCAST_TRIMMING='s|(Enable silence trimming in podcasts",default:)(!1)|$1true|s'
ENABLE_SEARCH_BOX='s|(Adds a search box so users are able to filter playlists when trying to add songs to a playlist using the contextmenu",default:)(!1)|$1true|s'
ENABLE_SIMILAR_PLAYLIST='s/,(.\.isOwnedBySelf&&)((\(.{0,11}\)|..createElement)\(.{1,3}Fragment,.+?{(uri:.|spec:.),(uri:.|spec:.).+?contextmenu.create-similar-playlist"\)}\),)/,$2$1/s'

# Home screen UI (new)
NEW_UI='s|(Enable the new home structure and navigation",values:.,default:)(..DISABLED)|$1true|'
NEW_UI_2='s|(Enable the new home structure and navigation",values:.,default:.)(.DISABLED)|$1.ENABLED_CENTER|'
AUDIOBOOKS_CLIENTX='s|(Enable Audiobooks feature on ClientX",default:)(!1)|$1true|s'
ENABLE_LEFT_SIDEBAR='s|(Enable Your Library X view of the left sidebar",default:)(!1)|$1true|s'
ENABLE_RIGHT_SIDEBAR='s|(Enable the view on the right sidebar",default:)(!1)|$1true|s'
ENABLE_RIGHT_SIDEBAR_LYRICS='s|(Show lyrics in the right sidebar",default:)(!1)|$1true|s'

# Hide Premium-only features
HIDE_DL_QUALITY='s/(\(.,..jsxs\)\(.{1,3}|(.\(\).|..)createElement\(.{1,4}),\{(filterMatchQuery|filter:.,title|(variant:"viola",semanticColor:"textSubdued"|..:"span",variant:.{3,6}mesto,color:.{3,6}),htmlFor:"desktop.settings.downloadQuality.+?).{1,6}get\("desktop.settings.downloadQuality.title.+?(children:.{1,2}\(.,.\).+?,|\(.,.\){3,4},|,.\)}},.\(.,.\)\),)//'
HIDE_DL_ICON=' .BKsbV2Xl786X9a09XROH {display:none}'
HIDE_DL_MENU=' button.wC9sIed7pfp47wZbmU6m.pzkhLqffqF_4hucrVVQA {display:none}'
HIDE_VERY_HIGH=' #desktop\.settings\.streamingQuality>option:nth-child(5) {display:none}'

# Hide Podcasts/Episodes/Audiobooks on home screen
HIDE_PODCASTS='s|withQueryParameters\(.\)\{return this.queryParameters=.,this}|withQueryParameters(e){return this.queryParameters=(e.types?{...e, types: e.types.split(",").filter(_ => !["episode","show"].includes(_)).join(",")}:e),this}|'
HIDE_PODCASTS2='s/(!Array.isArray\(.\)\|\|.===..length)/$1||e.children[0].key.includes('\''episode'\'')||e.children[0].key.includes('\''show'\'')/'
HIDE_PODCASTS3='s/(!Array.isArray\(.\)\|\|.===..length)/$1||e[0].key.includes('\''episode'\'')||e[0].key.includes('\''show'\'')/'

# Log-related regex
LOG_1='s|sp://logging/v3/\w+||g'
LOG_SENTRY='s|this\.getStackTop\(\)\.client=e|return;$&|'

# Spotify Connect unlock / UI
CONNECT_OLD_1='s| connect-device-list-item--disabled||' # 1.1.70.610+
CONNECT_OLD_2='s|connect-picker.unavailable-to-control|spotify-connect|' # 1.1.70.610+
CONNECT_OLD_3='s|(className:.,disabled:)(..)|$1false|' # 1.1.70.610+
CONNECT_NEW='s/return (..isDisabled)(\?(..createElement|\(.{1,10}\))\(..,)/return false$2/' # 1.1.91.824+
DEVICE_PICKER_NEW='s|(Enable showing a new and improved device picker UI",default:)(!1)|$1true|' # 1.1.90.855 - 1.1.95.893
DEVICE_PICKER_OLD='s|(Enable showing a new and improved device picker UI",default:)(!0)|$1false|' # 1.1.96.783 - 1.1.97.962

# Credits
echo
echo "************************"
echo "SpotX-Mac by @SpotX-CLI"
echo "************************"
echo

# Report versions
echo -e "Spotify version: ${CLIENT_VERSION}"
echo -e "SpotX-Mac version: ${SPOTX_VERSION}\n"

# xpui detection
if [[ ! -f "${XPUI_SPA}" ]]; then
  echo -e "\nxpui not found!\nReinstall Spotify then try again.\nExiting...\n"
  exit
else
  if [[ "${FORCE_FLAG}" == "false" ]]; then
    if [[ -f "${XPUI_BAK}" ]]; then
      echo "SpotX backup found, SpotX has already been used on this install."
      echo -e "Re-run SpotX using the '-f' flag to force xpui patching.\n"
      echo "Skipping xpui patches and continuing SpotX..."
      XPUI_SKIP="true"
    else
      echo "Creating xpui backup..."
      cp "${XPUI_SPA}" "${XPUI_BAK}"
      XPUI_SKIP="false"; fi
  else
    if [[ -f "${XPUI_BAK}" ]]; then
      echo "Backup xpui found, restoring original..."
      rm "${XPUI_SPA}"
      cp "${XPUI_BAK}" "${XPUI_SPA}"
      XPUI_SKIP="false"
    else
      echo "Creating xpui backup..."
      cp "${XPUI_SPA}" "${XPUI_BAK}"
      XPUI_SKIP="false"; fi; fi; fi

# Extract xpui.spa
if [[ "${XPUI_SKIP}" == "false" ]]; then
  echo "Extracting xpui..."
  unzip -qq "${XPUI_SPA}" -d "${XPUI_DIR}"
  if grep -Fq "SpotX" "${XPUI_JS}"; then
    echo -e "\nWarning: Detected SpotX patches but no backup file!"
    echo -e "Further xpui patching not allowed until Spotify is reinstalled/upgraded.\n"
    echo "Skipping xpui patches and continuing SpotX..."
    XPUI_SKIP="true"
    rm "${XPUI_BAK}" 2>/dev/null
    rm -rf "${XPUI_DIR}" 2>/dev/null
  else
    rm "${XPUI_SPA}"; fi; fi

echo "Applying SpotX patches..."

if [[ "${XPUI_SKIP}" == "false" ]]; then
  if [[ "${PREMIUM_FLAG}" == "false" ]]; then
    # Remove Empty ad block
    echo "Removing ad-related content..."
    $PERL "${AD_EMPTY_AD_BLOCK}" "${XPUI_JS}"
    # Remove Playlist sponsors
    $PERL "${AD_PLAYLIST_SPONSORS}" "${XPUI_JS}"
    # Remove Upgrade button
    $PERL "${AD_UPGRADE_BUTTON}" "${XPUI_JS}"
    # Remove Audio ads
    $PERL "${AD_AUDIO_ADS}" "${XPUI_JS}"
    # Remove billboard ads
    $PERL "${AD_BILLBOARD}" "${XPUI_JS}"
    # Remove premium upsells
    $PERL "${AD_UPSELL}" "${XPUI_JS}"
    
    # Remove Premium-only features
    echo "Removing premium-only features..."
    $PERL "${HIDE_DL_QUALITY}" "${XPUI_JS}"
    echo "${HIDE_DL_ICON}" >> "${XPUI_CSS}"
    echo "${HIDE_DL_MENU}" >> "${XPUI_CSS}"
    echo "${HIDE_VERY_HIGH}" >> "${XPUI_CSS}"
    
    # Unlock Spotify Connect
    echo "Unlocking Spotify Connect..."
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.70.610") && $(ver "${CLIENT_VERSION}") -lt $(ver "1.1.91.824") ]]; then
      $PERL "${CONNECT_OLD_1}" "${XPUI_JS}"
      $PERL "${CONNECT_OLD_2}" "${XPUI_JS}"
      $PERL "${CONNECT_OLD_3}" "${XPUI_JS}"
    elif [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.91.824") && $(ver "${CLIENT_VERSION}") -lt $(ver "1.1.96.783") ]]; then
      $PERL "${DEVICE_PICKER_NEW}" "${XPUI_JS}"
      $PERL "${CONNECT_NEW}" "${XPUI_JS}"
    elif [[ $(ver "${CLIENT_VERSION}") -gt $(ver "1.1.96.783") ]]; then
      $PERL "${CONNECT_NEW}" "${XPUI_JS}"; fi
  else
    echo "Premium subscription setup selected..."; fi; fi

# Experimental patches
if [[ "${XPUI_SKIP}" == "false" ]]; then
  if [[ "${EXPERIMENTAL_FLAG}" == "true" ]]; then
    echo "Adding experimental features..."
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.99.871") ]]; then $PERL "${ENABLE_ADD_PLAYLIST}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.99.871") ]]; then $PERL "${ENABLE_BAD_BUNNY}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.89.854") ]]; then $PERL "${ENABLE_BALLOONS}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.70.610") ]]; then $PERL "${ENABLE_BLOCK_USERS}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.93.896") ]]; then $PERL "${ENABLE_CAROUSELS}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.92.644") && $(ver "${CLIENT_VERSION}") -lt $(ver "1.1.99.871") ]]; then $PERL "${ENABLE_CLEAR_DOWNLOADS}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.99.871") ]]; then $PERL "${ENABLE_DEVICE_LIST_LOCAL}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.79.763") ]]; then $PERL "${ENABLE_DISCOG_SHELF}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.84.716") ]]; then $PERL "${ENABLE_ENHANCE_PLAYLIST}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.86.857") ]]; then $PERL "${ENABLE_ENHANCE_SONGS}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.88.595") ]]; then $PERL "${ENABLE_EQUALIZER}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.2.1.958") ]]; then $PERL "${ENABLE_FOLLOWERS_ON_PROFILE}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.2.0.1155") ]]; then $PERL "${ENABLE_FORGET_DEVICES}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.87.612") ]]; then $PERL "${ENABLE_IGNORE_REC}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.70.610") ]]; then $PERL "${ENABLE_LIKED_SONGS}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.70.610") && $(ver "${CLIENT_VERSION}") -lt $(ver "1.1.94.864") ]]; then $PERL "${ENABLE_LYRICS_CHECK}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.87.612") ]]; then $PERL "${ENABLE_LYRICS_MATCH}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.70.610") && $(ver "${CLIENT_VERSION}") -lt $(ver "1.1.96.783") ]]; then $PERL "${ENABLE_MADE_FOR_YOU}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.91.824") ]]; then $PERL "${ENABLE_PATHFINDER_DATA}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.70.610") && $(ver "${CLIENT_VERSION}") -lt $(ver "1.1.94.864") ]]; then $PERL "${ENABLE_PLAYLIST_CREATION_FLOW}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.75.572") ]]; then $PERL "${ENABLE_PLAYLIST_PERMISSIONS_FLOWS}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.2.0.1165") ]]; then $PERL "${ENABLE_PODCAST_PLAYBACK_SPEED}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.99.871") ]]; then $PERL "${ENABLE_PODCAST_TRIMMING}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.86.857") && $(ver "${CLIENT_VERSION}") -lt $(ver "1.1.94.864") ]]; then $PERL "${ENABLE_SEARCH_BOX}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.85.884") ]]; then $PERL "${ENABLE_SIMILAR_PLAYLIST}" "${XPUI_JS}"; fi; fi; fi

# Remove logging
if [[ "${XPUI_SKIP}" == "false" ]]; then
  echo "Removing logging..."
  $PERL "${LOG_1}" "${XPUI_JS}"
  $PERL "${LOG_SENTRY}" "${VENDOR_XPUI_JS}"; fi

# Handle new home screen UI
if [[ "${XPUI_SKIP}" == "false" ]]; then
  if [[ "${OLD_UI_FLAG}" == "true" ]]; then
    echo "Skipping new home UI patch..."
  elif [[ $(ver "${CLIENT_VERSION}") -gt $(ver "1.1.93.896") && $(ver "${CLIENT_VERSION}") -lt $(ver "1.1.97.956") ]]; then
    echo "Enabling new home screen UI..."
    $PERL "${NEW_UI}" "${XPUI_JS}"
    $PERL "${AUDIOBOOKS_CLIENTX}" "${XPUI_JS}"
  elif [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.97.956") && $(ver "${CLIENT_VERSION}") -lt $(ver "1.2.3.1107") ]]; then
    echo "Enabling new home screen UI..."
    $PERL "${NEW_UI_2}" "${XPUI_JS}"
    $PERL "${AUDIOBOOKS_CLIENTX}" "${XPUI_JS}"
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.98.683") ]]; then $PERL "${ENABLE_RIGHT_SIDEBAR}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.2.0.1165") ]]; then $PERL "${ENABLE_RIGHT_SIDEBAR_LYRICS}" "${XPUI_JS}"; fi
  elif [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.2.3.1107") ]]; then
    echo "Enabling new home screen UI..."
    $PERL "${AUDIOBOOKS_CLIENTX}" "${XPUI_JS}"
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.97.962") ]]; then $PERL "${ENABLE_LEFT_SIDEBAR}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.98.683") ]]; then $PERL "${ENABLE_RIGHT_SIDEBAR}" "${XPUI_JS}"; fi
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.2.0.1165") ]]; then $PERL "${ENABLE_RIGHT_SIDEBAR_LYRICS}" "${XPUI_JS}"; fi
  else
    :; fi; fi

# Hide podcasts, episodes and audiobooks on home screen
if [[ "${XPUI_SKIP}" == "false" ]]; then
  if [[ "${HIDE_PODCASTS_FLAG}" == "true" ]]; then
    if [[ $(ver "${CLIENT_VERSION}") -lt $(ver "1.1.93.896") ]]; then
      echo "Hiding non-music items on home screen..."
      $PERL "${HIDE_PODCASTS}" "${XPUI_JS}"
    elif [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.93.896") && $(ver "${CLIENT_VERSION}") -le $(ver "1.1.96.785") ]]; then
      echo "Hiding non-music items on home screen..."
      $PERL "${HIDE_PODCASTS2}" "${HOME_V2_JS}"
    elif [[ $(ver "${CLIENT_VERSION}") -gt $(ver "1.1.96.785") && $(ver "${CLIENT_VERSION}") -lt $(ver "1.1.98.683") ]]; then
      echo "Hiding non-music items on home screen..."
      $PERL "${HIDE_PODCASTS3}" "${HOME_V2_JS}"
    elif [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.98.683") ]]; then
      echo "Hiding non-music items on home screen..."
      $PERL "${HIDE_PODCASTS3}" "${XPUI_JS}"; fi; fi; fi

# Delete app cache
if [[ "${CACHE_FLAG}" == "true" ]]; then
  echo "Clearing app cache..."
  rm -rf "$CACHE_PATH"; fi
  
# Automatic updates handling
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
if [[ "${XPUI_SKIP}" == "false" ]]; then
  echo "Rebuilding xpui..."
  echo -e "\n//# SpotX was here" >> "${XPUI_JS}"; fi

# Zip files inside xpui folder
if [[ "${XPUI_SKIP}" == "false" ]]; then
  (cd "${XPUI_DIR}"; zip -qq -r ../xpui.spa .)
  rm -rf "${XPUI_DIR}"; fi

echo -e "SpotX finished patching!\n"
