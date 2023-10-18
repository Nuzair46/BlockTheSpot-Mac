#!/usr/bin/env bash

SPOTX_VERSION="1.2.22.982"

# dependencies check
command -v perl >/dev/null || { echo -e "\nperl was not found, exiting...\n" >&2; exit 1; }
command -v unzip >/dev/null || { echo -e "\nunzip was not found, exiting...\n" >&2; exit 1; }
command -v zip >/dev/null || { echo -e "\nzip was not found, exiting...\n" >&2; exit 1; }

# Script flags
APP_PATH="/Applications/Spotify.app"
FORCE_FLAG='false'
HIDE_PODCASTS_FLAG='false'
PATH_FLAG='false'
UPDATE_FLAG='false'
CUSTOM_APP_PATH='false'
SKIP_CODE_SIGNATURE='false'

while getopts 'cefhopuP:' flag; do
  case "${flag}" in
  f) FORCE_FLAG='true' ;;
  h) HIDE_PODCASTS_FLAG='true' ;;
  S) SKIP_CODE_SIGNATURE='true' ;;
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

XPUI_PATH="${INSTALL_PATH}/Contents/Resources/Apps"
APP_BINARY="${INSTALL_PATH}/Contents/MacOS/Spotify"
APP_BINARY_BAK="${INSTALL_PATH}/Contents/MacOS/Spotify.bak"
XPUI_DIR="${XPUI_PATH}/xpui"
XPUI_BAK="${XPUI_PATH}/xpui.bak"
XPUI_SPA="${XPUI_PATH}/xpui.spa"
XPUI_JS="${XPUI_DIR}/xpui.js"
XPUI_CSS="${XPUI_DIR}/xpui.css"
VENDOR_XPUI_JS="${XPUI_DIR}/vendor~xpui.js"

# Find client version
CLIENT_VERSION=$(awk '/CFBundleShortVersionString/{getline; print}' "${INSTALL_PATH}/Contents/Info.plist" | cut -d\> -f2- | rev | cut -d. -f2- | rev)

# Version function for version comparison
function ver { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

# Perl command
PERL="perl -pi -w -e"

# Ad-related regex
AD_EMPTY_AD_BLOCK='s|adsEnabled:!0|adsEnabled:!1|'
AD_PLAYLIST_SPONSORS='s|allSponsorships||'
AD_UPGRADE_BUTTON='s/(return|.=.=>)"free"===(.+?)(return|.=.=>)"premium"===/$1"premium"===$2$3"free"===/g'
AD_AUDIO_ADS='s/(case .:|async enable\(.\)\{)(this.enabled=.+?\(.{1,3},"audio"\),|return this.enabled=...+?\(.{1,3},"audio"\))((;case 4:)?this.subscription=this.audioApi).+?this.onAdMessage\)/$1$3.cosmosConnector.increaseStreamTime(-100000000000)/'
AD_BILLBOARD='s|.(\?\[.{1,6}[a-zA-Z].leaderboard,)|false$1|'
AD_UPSELL='s|Enables quicksilver in-app messaging modal",default:\K!.(?=})|false|s'
AD_ADS='s#/a\Kd(?=s/v1)|/a\Kd(?=s/v2/t)|/a\Kd(?=s/v2/se)#b#gs'
AD_SERV='s|(this\._product_state(?:_service)?=(.))|$1,$2.putOverridesValues({pairs:{ads:'\''0'\'',catalogue:'\''premium'\'',product:'\''premium'\'',type:'\''premium'\''}})|'
AD_PATCH_1='s|\x00\K\x61(?=\x64\x2D\x6C\x6F\x67\x69\x63\x2F\x73)|\x00|'
AD_PATCH_2='s|\x00\K\x73(?=\x6C\x6F\x74\x73\x00)|\x00|'

# Hide Premium-only features
HIDE_DL_QUALITY='s/(\(.,..jsxs\)\(.{1,3}|(.\(\).|..)createElement\(.{1,4}),\{(filterMatchQuery|filter:.,title|(variant:"viola",semanticColor:"textSubdued"|..:"span",variant:.{3,6}mesto,color:.{3,6}),htmlFor:"desktop.settings.downloadQuality.+?).{1,6}get\("desktop.settings.downloadQuality.title.+?(children:.{1,2}\(.,.\).+?,|\(.,.\){3,4},|,.\)}},.\(.,.\)\),)//'
HIDE_DL_ICON=' .BKsbV2Xl786X9a09XROH {display:none}'
HIDE_DL_MENU=' button.wC9sIed7pfp47wZbmU6m.pzkhLqffqF_4hucrVVQA {display:none}'
HIDE_VERY_HIGH=' #desktop\.settings\.streamingQuality>option:nth-child(5) {display:none}'

# Hide Podcasts/Episodes/Audiobooks on home screen
HIDE_PODCASTS3='s/(!Array.isArray\(.\)\|\|.===..length)/$1||e[0].key.includes('\''episode'\'')||e[0].key.includes('\''show'\'')/'

# Log-related regex
LOG_1='s|sp://logging/v3/\w+||g'
LOG_SENTRY='s|this\.getStackTop\(\)\.client=e|return;$&|'

# Updates
UPDATE_PATCH='s|\x64(?=\x65\x73\x6B\x74\x6F\x70\x2D\x75\x70)|\x00|g'

# Credits
echo
echo "************************"
echo "SpotX-Mac by @Nuzair46"
echo "************************"
echo

# Report versions
echo -e "Spotify version: ${CLIENT_VERSION}"
echo -e "SpotX-Mac version: ${SPOTX_VERSION}\n"

if [[ $(ver "${CLIENT_VERSION}") -lt $(ver "${SPOTX_VERSION}") ]]; then
  echo "This version of SpotX-Mac is not compatible with your Spotify version."
  echo "Pleas use an older version of SpotX-Mac or update Spotify."
  exit; fi

if [[ "${SKIP_CODE_SIGNATURE}" == "true" ]]; then
  echo "Skipping code signature check..."
elif ! command -v codesign &> /dev/null; then
  echo "codesign was not found."
  echo "Install the Xcode command line tools to enable code signature checks."
  echo "With xcode-select --install";
  echo "You can try to skip code signature checks with the -S flag. Exiting..."
  exit; 
fi

# xpui detection
if [[ ! -f "${XPUI_SPA}" ]]; then
  echo -e "\nxpui not found!\nReinstall Spotify then try again.\nExiting...\n"
  exit
else
  if [[ "${FORCE_FLAG}" == "false" ]]; then
    if [[ -f "${XPUI_BAK}" ]] || [[ -f "${APP_BINARY_BAK}" ]]; then
      echo "SpotX backup found, SpotX has already been used on this install."
      echo -e "Re-run SpotX using the '-f' flag to force xpui patching.\n"
      echo "Skipping xpui patches and continuing SpotX..."
      XPUI_SKIP="true"
    else
      echo "Creating backup..."
      cp "${XPUI_SPA}" "${XPUI_BAK}"
      cp "${APP_BINARY}" "${APP_BINARY_BAK}"
      XPUI_SKIP="false"; fi
  else
    if [[ -f "${XPUI_BAK}" ]] || [[ -f "${APP_BINARY_BAK}" ]]; then
      echo "Backup found, restoring original..."
      rm "${XPUI_SPA}"
      rm "${APP_BINARY}"
      cp "${XPUI_BAK}" "${XPUI_SPA}"
      cp "${APP_BINARY_BAK}" "${APP_BINARY}"
      XPUI_SKIP="false"
    else
      echo "Creating backup..."
      cp "${XPUI_SPA}" "${XPUI_BAK}"
      cp "${APP_BINARY}" "${APP_BINARY_BAK}"
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
  # Remove Empty ad block
  echo "Removing ad-related content..."
  $PERL "${AD_ADS}" "${XPUI_JS}"
  $PERL "${AD_ADS}" "${APP_BINARY}"
  $PERL "${AD_BILLBOARD}" "${XPUI_JS}"
  $PERL "${AD_EMPTY_AD_BLOCK}" "${XPUI_JS}"
  $PERL "${AD_SERV}" "${XPUI_JS}"
  $PERL "${AD_PATCH_1}" "${APP_BINARY}"
  $PERL "${AD_PLAYLIST_SPONSORS}" "${XPUI_JS}"
  $PERL "${AD_PATCH_2}" "${APP_BINARY}"
  $PERL "${AD_UPSELL}" "${XPUI_JS}"

  # Remove Premium-only features
  echo "Removing premium-only features..."
  $PERL "${HIDE_DL_QUALITY}" "${XPUI_JS}"
  echo "${HIDE_DL_ICON}" >> "${XPUI_CSS}"
  echo "${HIDE_DL_MENU}" >> "${XPUI_CSS}"
  echo "${HIDE_VERY_HIGH}" >> "${XPUI_CSS}"; fi

# Remove logging
if [[ "${XPUI_SKIP}" == "false" ]]; then
  echo "Removing logging..."
  $PERL "${LOG_1}" "${XPUI_JS}"
  $PERL "${LOG_SENTRY}" "${VENDOR_XPUI_JS}"; fi

# Hide podcasts, episodes and audiobooks on home screen
if [[ "${XPUI_SKIP}" == "false" ]]; then
  if [[ "${HIDE_PODCASTS_FLAG}" == "true" ]]; then
    if [[ $(ver "${CLIENT_VERSION}") -ge $(ver "1.1.98.683") ]]; then
      echo "Hiding non-music items on home screen..."
      $PERL "${HIDE_PODCASTS3}" "${XPUI_JS}"; fi; fi; fi
  
# Automatic updates handling
if [[ "${UPDATE_FLAG}" == "true" ]]; then
  echo "Blocking updates..."
  $PERL "${UPDATE_PATCH}" "${APP_BINARY}"; fi
  
# Rebuild xpui.spa
if [[ "${XPUI_SKIP}" == "false" ]]; then
  echo "Rebuilding xpui..."
  echo -e "\n//# SpotX was here" >> "${XPUI_JS}"; fi

# Zip files inside xpui folder
if [[ "${XPUI_SKIP}" == "false" ]]; then
  (cd "${XPUI_DIR}"; zip -qq -r ../xpui.spa .)
  rm -rf "${XPUI_DIR}"; fi

# Sign APP_BINARY
echo "Signing Spotify..."
codesign -f --deep -s - "${APP_PATH}" 2>/dev/null;

echo -e "SpotX finished patching!\n"
