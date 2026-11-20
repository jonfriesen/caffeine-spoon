# Caffeine Spoon

Keep your Mac's display awake from the Hammerspoon menu bar, either until you turn Caffeine off or for a preset duration.

## Install

Install [Hammerspoon](https://www.hammerspoon.org/) and copy the entire `Caffeine.spoon` folder into `~/.hammerspoon/Spoons/` (or the `Spoons/` directory in your Hammerspoon config). Keep `init.lua` and both menu bar icons, `caffeine-on.pdf` and `caffeine-off.pdf`, together in the folder.

Add this to your Hammerspoon `init.lua`, then reload the configuration:

```lua
hs.loadSpoon("Caffeine")
-- Optional: uncomment to toggle with Option-Command-C.
-- spoon.Caffeine:bindHotkeys({ toggle = { { "alt", "cmd" }, "c" } })
spoon.Caffeine:start()
```

## Use

- **Left-click** the menu bar icon or press the optional hotkey to toggle display sleep prevention.
- **Right-click** for the same toggle and presets of 5, 15, or 30 minutes, or 1, 4, or 8 hours. Reopen the menu to see the remaining time.
- Choosing another preset replaces the timer. A manual toggle cancels it.
- Locking the screen, letting the timer expire, or stopping Caffeine cancels the timer and releases display sleep prevention if Caffeine enabled it. An assertion already active when Caffeine starts is left alone by this automatic cleanup.

## Lua API

| Method | Behavior |
| --- | --- |
| `start()` | Shows the menu bar icon and starts watching for screen locks. Calling it again stops the previous session first. |
| `stop()` | Ends the session, removes the menu bar icon, and disables the hotkey. The binding is retained for the next `start()`. |
| `bindHotkeys(mapping)` | Configures the optional `toggle` binding before startup, or replaces it immediately if Caffeine is running. |
| `setState(on)` | Requires `start()`. Sets display sleep prevention and cancels any timer. `false` explicitly turns it off, even if it was already active before Caffeine started. |
| `enableForDuration(seconds)` | Requires `start()`. Enables display sleep prevention and starts or replaces the timer. |
| `cancelTimer()` | Cancels the timer without changing display sleep prevention. |
| `buildMenu()` | Returns the menu items. The menu actions require `start()`. |

## Development

Run the lifecycle test with Lua 5.4: `lua tests/lifecycle.lua`.

Build the install ZIP from the repository root:

```sh
git archive --format=zip --prefix=Caffeine.spoon/ \
  -o ../Caffeine.spoon.zip HEAD init.lua README.md LICENSE LICENSE-MIT \
  docs.json caffeine-on.pdf caffeine-off.pdf
```

## License

Caffeine was originally written by Chris Jones and contributors for [Hammerspoon Spoons](https://github.com/Hammerspoon/Spoons). The upstream work remains under the [MIT License](LICENSE-MIT). Modifications are Copyright 2026 Jon Friesen and licensed under [Apache-2.0](LICENSE).
