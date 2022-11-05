  <p align="center">
  <a href="https://github.com/SpotX-CLI/SpotX-Mac"><img src="https://github.com/SpotX-CLI/SpotX-Mac/raw/main/.github/Pic/logo.png" />
</p>

<p align="center">        
      <a href="https://t.me/spotify_windows_mod"><img src="https://raw.githubusercontent.com/SpotX-CLI/SpotX-Mac/main/.github/Pic/Shields/tg.svg"></a>
      <a href="https://discord.gg/p43cusgUPm"><img src="https://discord.com/api/guilds/807273906872123412/widget.png"></a>
      </p>

 ***     

<center>
    <h4 align="center">A multi-featured adblocker for the Spotify macOS application.</h4>
    <p align="center">
        <strong>Last updated:</strong> 27 October 2022<br>
        <strong>Last tested version:</strong> 1.1.98.683
    </p> 
</center>

### Features:

- Blocks all banner/video/audio ads within the app
- Blocks logging (Sentry, etc)
- Unlocks the skip function for any track
- Blocks Spotify automatic updates (optional)
- Enables [experimental features](https://github.com/SpotX-CLI/SpotX-Win/discussions/50) (optional)
- Hides podcasts, episodes and audiobooks on Home Screen (optional)

### Installation/Update:

- Close Spotify completely.
- Run The following command in Terminal:

```
bash <(curl -sSL https://raw.githubusercontent.com/SpotX-CLI/SpotX-Mac/main/install.sh)
```

#### Optional Install Arguments:
`-c`  Clear app cache -- use if UI-related patches aren't working  
`-e`  Experimental features -- enables experimental features  
`-f`  Force patch -- forces re-patching if backup detected  
`-h`  Hide podcasts, episodes and audiobooks on home screen  
`-o`  Old UI -- skips forced 'new UI' patch  
`-p`  Premium subscription setup -- use if premium subscriber  
`-u`  Update block -- blocks automatic updates  

Use any combination of flags.  
The following example clears app cache, adds experimental features and blocks updates:
    
```
bash <(curl -sSL https://raw.githubusercontent.com/SpotX-CLI/SpotX-Mac/main/install.sh) -ceu
```


### Uninstall:

- Close Spotify completely.
- Run The following command in Terminal:

```
bash <(curl -sSL https://raw.githubusercontent.com/SpotX-CLI/SpotX-Mac/main/uninstall.sh)
```

or

- Reinstall Spotify

### DISCLAIMER

- Ad blocking is the main concern of this repo. Any other feature provided by SpotX-Mac or consequence of using those features will be the sole responsibility of the user, not BlockTheSpot/SpotX/SpotX-CLI/SpotX-Mac.

### Credits

- Thanks to [SpotX - amd64fox](https://github.com/amd64fox/spotx).
