#!/usr/bin/env bash

echo -e "\n*********************************\n\n  SpotX-Mac Spotify Uninstaller\n\n*********************************\n\n"

while true; do
    read -n 1 -p $"Do you want uninstall Spotify? [Y/N] " yn
    case $yn in
        [Yy]* )
            # Uninstall Spotify on macOS
            echo -e "\nRemoving Spotify files..."
            osascript -e 'quit app "Spotify"' && \
            rm -rf /Applications/Spotify.app
            rm -rf "${HOME}/Applications/Spotify.app"
            chflags nouchg "${HOME}/Library/Application Support/Spotify/PersistentCache/Update" 2> /dev/null
            rm -rf "${HOME}/Library/Application Support/Spotify"
            rm -rf "${HOME}/Library/Caches/com.spotify.client"
            rm -rf "${HOME}/Library/Saved Application State/com.spotify.client.savedState"
            (cd "${HOME}/Library/Preferences/" && rm com.spotify*.plist 2> /dev/null)
            (cd "${HOME}/Library/Logs/DiagnosticReports/" && rm Spotify*.crash 2> /dev/null)
            (cd "${HOME}/Library/Application Support/CrashReporter/" && rm Spotify*.plist 2> /dev/null)
            echo -e "Finished!\n"
            break;;
        [Nn]* ) 
            echo -e "\nExiting...\n"
            break;;
        * ) echo -e "\nPlease enter yes or no.";;
    esac
done
exit
