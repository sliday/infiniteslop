# SlopWindow

Floating always-on-top macOS window that plays [infiniteslop.ai](https://infiniteslop.ai) — video only, with ❤️ like.

Picture-in-Picture style: borderless rounded window, hover-reveal controls (✕ close, 🔊 mute toggle, ❤️ like + count), drag anywhere inside, resize by edges (9:16 aspect locked), floats over all apps and Spaces, remembers position.

## Build & run

```sh
./build.sh
open SlopWindow.app
```

Requires Xcode command line tools (swiftc). No dependencies.

## How it works

Single-file AppKit app (`Sources/main.swift`): a non-activating floating `NSPanel` hosts a `WKWebView` loading the live site, with injected CSS stripping everything except the video. A native overlay swallows mouse events for window dragging and hosts the hover controls; like/mute call the site's own JS (`heartPress()` → `POST api/like`).

Built with a [Gauntlet Loop](https://somethingbig.ai/gauntlet-loop) against a macOS-native PiP quality bar — see `workbench.md` for the round log.
