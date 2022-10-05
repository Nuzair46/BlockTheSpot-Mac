#!/usr/bin/env bash

# Inital paths and filenames
XPUI="xpui"
XPUI_SPA="xpui.spa"
XPUI_SPA_BAK="xpui.bak"
XPUI_ZIP="xpui.zip"
CACHE_PATH="${HOME}/Library/Caches/com.spotify.client"

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

# Ad enablers
AD_EMPTY_AD_BLOCK='adsEnabled:!0'
AD_PLAYLIST_SPONSORS='allSponsorships'
AD_UPGRADE_BUTTON_FREE='"free"==='
AD_UPGRADE_BUTTON_PREMIUM='"premium"==='
AD_AUDIO_AD_REGEX='case 0:return this\.enabled=!0,this\.onInfoCallback=t,e\.next=4,this\.audioApi\.addNewSlot\([a-z],"audio"\);case 4:this\.subscription=this\.audioApi\.subscribeToSlotType\([a-z],this\.onAdMessage\);'
AD_BILLBOARD_REGEX='concat\(\([0]\,[a-zA-Z]\.[a-zA-Z]\)\([e]\?'

# Ad disablers
PATCH_EMPTY_AD_BLOCK='adsEnabled:!1'
PATCH_PLAYLIST_SPONSORS=''
PATCH_UPGRADE_BUTTON_TEMP='"temporary"==='
PATCH_AUDIO_AD='case 0:;case 4:this.subscription=this.audioApi.cosmosConnector.increaseStreamTime(-100000000000);'
PATCH_BILLBOARD='(false?'

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
    cp "${XPUI_PATH}/${XPUI_SPA}" "${XPUI_PATH}/${XPUI_SPA_BAK}"
fi

echo "Extracting xpui.js..."
cd "$XPUI_PATH"
rm -rf "$XPUI"
mv "$XPUI_SPA" "$XPUI_ZIP"
unzip -qq "$XPUI_ZIP" -d "$XPUI"
rm "$XPUI_ZIP"
XPUI_JS=$(find "$XPUI" -name "xpui.js")

# Remove Ads
echo "Applying the patch..."

# Remove Empty ad block
echo "Removing empty ad block..."
perl -pi -w -e "s/$AD_EMPTY_AD_BLOCK/$PATCH_EMPTY_AD_BLOCK/" $XPUI_JS

# Remove Playlist sponsors
echo "Removing playlist sponsors..."
perl -pi -w -e "s/$AD_PLAYLIST_SPONSORS/$PATCH_PLAYLIST_SPONSORS/" $XPUI_JS

# Remove Upgrade button
echo "Removing upgrade button..."
perl -pi -w -e "s/$AD_UPGRADE_BUTTON_PREMIUM/$PATCH_UPGRADE_BUTTON_TEMP/g" $XPUI_JS
perl -pi -w -e "s/$AD_UPGRADE_BUTTON_FREE/$AD_UPGRADE_BUTTON_PREMIUM/g" $XPUI_JS
perl -pi -w -e "s/$PATCH_UPGRADE_BUTTON_TEMP/$AD_UPGRADE_BUTTON_FREE/g" $XPUI_JS

# Remove Audio ads
echo "Removing audio ads..."
perl -pi -w -e "s/$AD_AUDIO_AD_REGEX/$PATCH_AUDIO_AD/g;" $XPUI_JS

# Remove billboard ads
echo "Removing billboard ads..."
# get matched string
MATCHED_STRING=$(grep -E -o "$AD_BILLBOARD_REGEX" $XPUI_JS)
TO_PATCH='(e?'
PATCH_BILLBOARD_AD=${MATCHED_STRING/$TO_PATCH/$PATCH_BILLBOARD}
perl -pi -w -e "s/\Q$MATCHED_STRING\E/$PATCH_BILLBOARD_AD/g;" $XPUI_JS

# Rebuild xpui.spa
echo "Rebuilding xpui.spa..."

# Zip files inside xpui folder
cd "$XPUI"
zip -r -qq "$XPUI_SPA" *
mv "$XPUI_SPA" "$XPUI_PATH"
cd "$XPUI_PATH"
rm -rf "$XPUI"

# Delete app cache
if [[ "${CACHE_FLAG}" == "true" ]]; then
    echo "Clearing app cache..."
    rm -rf "$CACHE_PATH"
fi

echo -e "Patch applied successfully!\n"
