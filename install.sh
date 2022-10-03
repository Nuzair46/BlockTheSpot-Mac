#!/usr/bin/env bash

# Inital paths and filenames
if [[ -d "${HOME}/Applications/Spotify.app" ]]; then
    INSTALL_PATH="${HOME}/Applications/Spotify.app"
elif [[ -d "/Applications/Spotify.app" ]]; then
    INSTALL_PATH="/Applications/Spotify.app"
else
    INSTALL_PATH="/Applications/Spotify.app"
    NOT_INSTALLED=yes
fi
UPDATER_PATH="${HOME}/Library/Application Support/Spotify/PersistentCache/Update"
XPUI="xpui"
XPUI_PATH="${INSTALL_PATH}/Contents/Resources/Apps"
XPUI_SPA="xpui.spa"
XPUI_SPA_BAK="xpui.bak"
XPUI_ZIP="xpui.zip"

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
echo "************************************************"
echo "SpotX-Mac by @nuzair46"
echo "Thanks to @amd64fox for the original SpotX patch"
echo "************************************************"
echo

if [[ "$NOT_INSTALLED" == "yes" ]]; then
    while true; do
        read -n 1 -p 'Spotify.app not found, install Spotify? [Y/N] ' yn
        case $yn in
            [Yy]* )
                DOWNLOAD_APP=yes
                break;;
            [Nn]* ) 
                echo
                echo -e "Exiting...\n"
                exit
                break;;
                * ) echo -e "\nPlease enter yes or no.";;
        esac
    done
else
    while true; do
        read -n 1 -p 'Do you want to download and install Spotify? [Y/N] ' yn
        case $yn in
            [Yy]* )
                DOWNLOAD_APP=yes
                break;;
            [Nn]* ) 
                DOWNLOAD_APP=no
                break;;
                * ) echo -e "\nPlease enter yes or no.";;
        esac
    done
fi

# Download and Install Spotify
if [[ "$DOWNLOAD_APP" == "yes" ]]; then

    # Detect Device Architecture
    if [[ $(sysctl -n machdep.cpu.brand_string) =~ "Apple" ]]; then
        buildarch=arm64
        echo
    else
        buildarch=x86_64
        echo
    fi

    # Build Number and Update Block Variables
    read -p 'Enter desired build # (ex. 1.1.95.893.g6cf4d40c-39): ' buildno
    while true; do
        read -n 1 -p 'Do you want to block Spotify updates? [Y/N] ' yn
        case $yn in
            [Yy]* )
                UPDATE_BLOCK=yes
                break;;
            [Nn]* ) 
                UPDATE_BLOCK=no
                break;;
                * ) echo -e "\nPlease enter yes or no.";;
        esac
    done

    # Download and Install
    echo -e "\n\nDownloading...\n"
    curl -f -o ${HOME}/Downloads/spotify-autoupdate-$buildno.tbz https://upgrade.scdn.co/upgrade/client/osx-$buildarch/spotify-autoupdate-$buildno.tbz && \
    if [[ -d "${INSTALL_PATH}" ]]; then echo -e "\nDeleting current Spotify.app..." && osascript -e 'quit app "Spotify"' && rm -rf "${INSTALL_PATH}"; fi && \
    echo "Installing..." && \
    mkdir "${INSTALL_PATH}" && \
    tar -xpjf ~/Downloads/spotify-autoupdate-$buildno.tbz -C "${INSTALL_PATH}" && \
    echo "Cleaning up..." && rm ${HOME}/Downloads/spotify-autoupdate-$buildno.tbz
else
    # Update Block Variable
    echo
    while true; do
        read -n 1 -p 'Do you want to block Spotify updates? [Y/N] ' yn
        case $yn in
            [Yy]* )
                UPDATE_BLOCK=yes
                echo
                break;;
            [Nn]* ) 
                UPDATE_BLOCK=no
                echo
                break;;
                * ) echo -e "\nPlease enter yes or no.";;
        esac
    done
fi

# Block Updates
if [[ "$UPDATE_BLOCK" == "yes" ]]; then
    echo "Blocking updates..."
    chflags nouchg "${UPDATER_PATH}" 2> /dev/null
    rm -rf "${UPDATER_PATH}"
    mkdir -p "${UPDATER_PATH}"
    chflags uchg "${UPDATER_PATH}"
else
    chflags nouchg "${UPDATER_PATH}" 2> /dev/null
fi

# Create backup and extract xpui.js
echo "Creating backup of xpui.spa..."
cp "$XPUI_PATH/$XPUI_SPA" "$XPUI_PATH/$XPUI_SPA_BAK"

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

#zip files inside xpui folder
cd "$XPUI"
zip -r -qq "$XPUI_SPA" *
mv "$XPUI_SPA" "$XPUI_PATH"
cd "$XPUI_PATH"
rm -rf "$XPUI"

echo -e "Patch applied successfully!\n"
