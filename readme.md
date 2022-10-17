[![Discord](https://discord.com/api/guilds/807273906872123412/widget.png)](https://discord.gg/p43cusgUPm)

<center>
    <h1 align="center">SpotX for macOS</h1>
    <h4 align="center">A multi-purpose adblocker and skip-bypass for the Spotify macOS application.</h4>
    <h5 align="center">Please support Spotify by purchasing premium</h5>
    <p align="center">
        <strong>Last updated:</strong> 11 October 2022<br>
        <strong>Last tested version:</strong> 1.1.96.783.ga553e8b1
    </p> 
</center>

### Features:

- Blocks all banner/video/audio ads within the app
- Retains friend, vertical video and radio functionality
- Unlocks the skip function for any track
- Blocks Spotify automatic updates (optional)
- Hides podcasts, episodes and audiobooks (optional)

### Installation/Update:

- Close Spotify completely.
- Run The following command in Terminal:

```
curl -sL https://raw.githubusercontent.com/SpotX-CLI/SpotX-Mac/master/install.sh | bash
```

#### Optional Install Arguments:
`-c`  Clear app cache -- use if UI-related patches aren't working  
`-f`  Force patch -- use if backup detected and want to force patch  
`-h`  Hide podcasts, episodes and audiobooks on home screen  
`-o`  Old UI -- skips forced 'new UI' patch  
`-p`  Premium subscription setup -- use if premium subscriber  
`-u`  Update block -- use to block automatic updates  

Use any combination of flags.  
The following example clears app cache, skips new UI patch and blocks updates:
    
```
curl -sL https://raw.githubusercontent.com/SpotX-CLI/SpotX-Mac/master/install.sh | bash -s -- -cou
```


### Uninstall:

- Close Spotify completely.
- Run The following command in Terminal:

```
curl -sL https://raw.githubusercontent.com/SpotX-CLI/SpotX-Mac/master/install.sh | bash
```

or

- Reinstall Spotify

### DISCLAIMER

- Ad blocking is the main concern of this repo. Any other feature provided by SpotX-Mac or consequence of using those features will be the sole responsibility of the user and not either BlockTheSpot or SpotX, SpotX-Mac team will be responsible.

### Credits

- Thanks to [SpotX - amd64fox](https://github.com/amd64fox/spotx).
