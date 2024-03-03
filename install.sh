#!/usr/bin/env bash

BLOCKTHESPOT_VERSION="1.2.32.985.g3be2709c"

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
DEVELOPER_MODE='false'
UNINSTALL_FLAG='false'

while getopts 'UfhSPud:' flag; do
  case "${flag}" in
  U) UNINSTALL_FLAG='true' ;;
  f) FORCE_FLAG='true' ;;
  h) HIDE_PODCASTS_FLAG='true' ;;
  S) SKIP_CODE_SIGNATURE='true' ;;
  d) DEVELOPER_MODE='true' ;;
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
XPUI_DESKTOP_MODAL_JS="${XPUI_DIR}/xpui-desktop-modals.js"

if [[ "${UNINSTALL_FLAG}" == "true" ]]; then
  if [[ ! -f "${XPUI_BAK}" ]] || [[ ! -f "${APP_BINARY_BAK}" ]]; then
    echo -e "Backup not found, BlockTheSpot-Mac has not been used on this installation."
    exit 
  fi
  echo "Backup found, restoring original..."
  rm "${XPUI_SPA}"
  rm "${APP_BINARY}"
  mv "${XPUI_BAK}" "${XPUI_SPA}"
  mv "${APP_BINARY_BAK}" "${APP_BINARY}"
  echo -e "BlockTheSpot-Mac has been uninstalled!"
  exit
fi

# Find client version
CLIENT_VERSION=$(awk '/CFBundleShortVersionString/{getline; print}' "${INSTALL_PATH}/Contents/Info.plist" | cut -d\> -f2- | rev | cut -d. -f2- | rev)

# Get Mac OS Architecture
MAC_ARCH=$(uname -m)

# Version function for version comparison
function ver { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

# Perl command
PERL="perl -pi -w -e"

# Ad-related regex
AD_EMPTY_AD_BLOCK='s|adsEnabled:!0|adsEnabled:!1|'
AD_PLAYLIST_SPONSORS='s|allSponsorships||'
AD_SPONSORS='s/ht.{14}\...\..{7}\....\/.{8}ap4p\/|ht.{14}\...\..{7}\....\/s.{15}t\/v.\///g'
# AD_UPGRADE_BUTTON='s/(return|.=.=>)"free"===(.+?)(return|.=.=>)"premium"===/$1"premium"===$2$3"free"===/g'
# AD_AUDIO_ADS='s/(case .:|async enable\(.\)\{)(this.enabled=.+?\(.{1,3},"audio"\),|return this.enabled=...+?\(.{1,3},"audio"\))((;case 4:)?this.subscription=this.audioApi).+?this.onAdMessage\)/$1$3.cosmosConnector.increaseStreamTime(-100000000000)/'
AD_BILLBOARD='s|.(?=\?\[.{1,6}[a-zA-Z].leaderboard,)|false|'
AD_UPSELL='s|Enables quicksilver in-app messaging modal",default:\K!.(?=})|false|s'
AD_ADS='s#/a\Kd(?=s/v1)|/a\Kd(?=s/v2/t)|/a\Kd(?=s/v2/se)#b#gs'
AD_SERV='s|(this\._product_state(?:_service)?=(.))|$1,$2.putOverridesValues({pairs:{ads:'\''0'\'',catalogue:'\''premium'\'',product:'\''premium'\'',type:'\''premium'\''}})|'
AD_PATCH_1='s|\x00\K\x61(?=\x64\x2D\x6C\x6F\x67\x69\x63\x2F\x73)|\x00|'
AD_PATCH_2='s|\x00\K\x73(?=\x6C\x6F\x74\x73\x00)|\x00|'
AD_PATCH_3='s|\x70\x6F\x64\x63\x61\x73\x74\K\x2D\x70|\x20\x70|g'
AD_PATCH_4='s|\x70\x6F\x64\x63\x61\x73\x74\K\x2D\x6D\x69|\x20\x6D\x69|g'
AD_PATCH_5='s|\x00\K\x67(?=\x61\x62\x6F\x2D\x72\x65\x63\x65\x69\x76\x65\x72\x2D\x73\x65\x72\x76\x69\x63\x65)|\x00|g'
HPTO_ENABLED='s|hptoEnabled:!\K0|1|s'
HPTO_PATCH='s|(ADS_PREMIUM,isPremium:)\w(.*?ADS_HPTO_HIDDEN,isHptoHidden:)\w|$1true$2true|'

# Hide Premium-only features
HIDE_DL_QUALITY='s|return \K([^;]+?)(?=\?null[^}]+?desktop\.settings\.downloadQuality\.title)|true|'
HIDE_DL_ICON=' .BKsbV2Xl786X9a09XROH {display:none}'
HIDE_DL_MENU=' button.wC9sIed7pfp47wZbmU6m.pzkhLqffqF_4hucrVVQA {display:none}'
HIDE_VERY_HIGH=' #desktop\.settings\.streamingQuality>option:nth-child(5) {display:none}'

# Hide Podcasts/Episodes/Audiobooks on home screen
HIDE_PODCASTS3='s/(!Array.isArray\(.\)\|\|.===..length)/$1||e[0].key.includes('\''episode'\'')||e[0].key.includes('\''show'\'')/'

MODAL_CREDITS='s;((..createElement|children:\(.{1,7}\))\(.{1,7},\{source:).{1,7}get\("about.copyright",.\),paragraphClassName:.(?=\}\));$1"<h3>About BlockTheSpot-Mac</h3><br><a href='\''https://github.com/Nuzair46/BlockTheSpot-Mac'\''><svg xmlns='\''http://www.w3.org/2000/svg'\'' width='\''20'\'' height='\''20'\'' viewBox='\''0 0 24 24'\''><path d='\''M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z'\'' fill='\''#fff'\''/></svg> Nuzair46/BlockTheSpot-Mac</a><br><a href='https://discord.gg/eYudMwgYtY'><svg xmlns='\''http://www.w3.org/2000/svg'\'' width='\''20'\'' height='\''20'\'' viewBox='\''0 0 24 24'\''><path id='\''discord'\'' d='\''M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z'\'' fill='\''#fff'\''/></svg> BlockTheSpot Discord</a><br><a href='https://github.com/mrpond/BlockTheSpot'><svg fill='\''#fff'\'' width='\''20'\'' height='\''20'\'' viewBox='\''0 0 24 24'\'' xmlns='\''http://www.w3.org/2000/svg'\''><path id='\''windows'\'' d='\''m9.84 12.663v9.39l-9.84-1.356v-8.034zm0-10.72v9.505h-9.84v-8.145zm14.16 10.72v11.337l-13.082-1.803v-9.534zm0-12.663v11.452h-13.082v-9.649z'\''/></svg> For Windows 10/11</a><br><br>BlockTheSpot-Mac is provided &quot\;as is&quot\ without any warranties at the users descretion. Use at your own risk. BlockTheSpot/BlockTheSpot-Mac team is not responsible for any consequences of using this project, <a href='\''https://github.com/Nuzair46/BlockTheSpot-Mac/blob/main/LICENSE'\''>More info</a>.<br><br>Spotify&reg\; is a registered trademark of Spotify Group.";'

# Log-related regex
LOG_1='s|sp://logging/v3/\w+||g'
LOG_SENTRY='s|this\.getStackTop\(\)\.client=e|return;$&|'

# Updates
UPDATE_PATCH='s|\x64(?=\x65\x73\x6B\x74\x6F\x70\x2D\x75\x70)|\x00|g'

# Developer mode
if [[ "${MAC_ARCH}" == "arm64" ]]; then
  DEVELOPER_MODE_PATCH='s|\xF8\xFF[\x37\x77\xF7][\x06\x07\x08]\x39\xFF.[\x00\x04]\xB9\xE1[\x03\x43\xC3][\x06\x07\x08]\x91\xE2.[\x02\x03\x13]\x91\K..\x00\x94(?=[\xF7\xF8]\x03)|\x60\x00\x80\xD2|'
else
  DEVELOPER_MODE_PATCH='s|\xFF\xFF\x48\xB8\x65\x76\x65.{5}\x48.{36,40}\K\xE8.{2}(?=\x00\x00)|\xB8\x03\x00|'
fi

# Credits
echo
echo "************************"
echo "BlockTheSpot-Mac by @Nuzair46"
echo "************************"
echo

# Report versions
echo -e "Spotify version: ${CLIENT_VERSION}"
echo -e "BlockTheSpot-Mac version: ${BLOCKTHESPOT_VERSION}\n"

if [[ $(ver "${CLIENT_VERSION}") -lt $(ver "${BLOCKTHESPOT_VERSION}") ]]; then
  echo "This version of BlockTheSpot-Mac is not compatible with your Spotify version."
  echo "Pleas use an older version of BlockTheSpot-Mac or update Spotify."
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
      echo "BlockTheSpot backup found, BlockTheSpot has already been used on this install."
      echo -e "Re-run BlockTheSpot using the '-f' flag to force xpui patching.\n"
      echo "Skipping xpui patches and continuing BlockTheSpot..."
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
  if grep -Fq "BlockTheSpot" "${XPUI_JS}"; then
    echo -e "\nWarning: Detected BlockTheSpot patches but no backup file!"
    echo -e "Further xpui patching not allowed until Spotify is reinstalled/upgraded.\n"
    echo "Skipping xpui patches and continuing BlockTheSpot..."
    XPUI_SKIP="true"
    rm "${XPUI_BAK}" 2>/dev/null
    rm -rf "${XPUI_DIR}" 2>/dev/null
  else
    rm "${XPUI_SPA}"; fi; fi

echo "Applying BlockTheSpot patches..."

if [[ "${XPUI_SKIP}" == "false" ]]; then
  echo "Removing ad-related content..."
  $PERL "${AD_ADS}" "${XPUI_JS}"
  $PERL "${AD_BILLBOARD}" "${XPUI_JS}"
  $PERL "${AD_EMPTY_AD_BLOCK}" "${XPUI_JS}"
  $PERL "${AD_SERV}" "${XPUI_JS}"
  $PERL "${AD_PLAYLIST_SPONSORS}" "${XPUI_JS}"
  $PERL "${AD_UPSELL}" "${XPUI_JS}"
  $PERL "${AD_SPONSORS}" "${XPUI_JS}"
  $PERL "${HPTO_ENABLED}" "${XPUI_JS}"
  $PERL "${HPTO_PATCH}" "${XPUI_JS}"

  echo "Patching Binary..."
  $PERL "${AD_ADS}" "${APP_BINARY}"
  $PERL "${AD_PATCH_1}" "${APP_BINARY}"
  $PERL "${AD_PATCH_2}" "${APP_BINARY}"
  $PERL "${AD_PATCH_3}" "${APP_BINARY}"
  $PERL "${AD_PATCH_4}" "${APP_BINARY}"
  $PERL "${AD_PATCH_5}" "${APP_BINARY}"

  # Remove Premium-only features
  echo "Removing premium-only features..."
  $PERL "${HIDE_DL_QUALITY}" "${XPUI_JS}"
  echo "${HIDE_DL_ICON}" >> "${XPUI_CSS}"
  echo "${HIDE_DL_MENU}" >> "${XPUI_CSS}"
  echo "${HIDE_VERY_HIGH}" >> "${XPUI_CSS}"; fi

if [[ "${DEVELOPER_MODE}" == "true" ]]; then
  echo "Enabling developer mode..."
  $PERL "${DEVELOPER_MODE_PATCH}" "${APP_BINARY}"; fi

# Remove logging
if [[ "${XPUI_SKIP}" == "false" ]]; then
  echo "Removing logging..."
  $PERL "${LOG_1}" "${XPUI_JS}"
  $PERL "${LOG_SENTRY}" "${VENDOR_XPUI_JS}"; fi

# Modal credits
if [[ "${XPUI_SKIP}" == "false" ]]; then
  echo "Adding credits..."
  $PERL "${MODAL_CREDITS}" "${XPUI_DESKTOP_MODAL_JS}"; fi

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

# Zip files inside xpui folder
if [[ "${XPUI_SKIP}" == "false" ]]; then
  (cd "${XPUI_DIR}"; zip -qq -r ../xpui.spa .)
  rm -rf "${XPUI_DIR}"; fi

# Sign APP_BINARY
echo "Signing Spotify..."
codesign -f --deep -s - "${APP_PATH}" 2>/dev/null;

echo -e "BlockTheSpot finished patching!\n"
