# SlopWindow

<img width="1512" height="982" alt="CleanShot 2026-08-31 at 16 55 41" src="https://github.com/user-attachments/assets/7db0d43b-a4d4-446b-af22-057a0a9d5734" />

A tiny Mac app that puts [infiniteslop.ai](https://infiniteslop.ai) in a small floating window. That site is an endless TV channel where every video is made by AI.

The window shows just the video. No chat, no menus, no clutter. It stays on top of everything, so you can watch while you do other stuff.

## Get it

Grab the newest build from **[Releases](https://github.com/sliday/infiniteslop/releases)**. Unzip, then open `SlopWindow.app`.

First open: right-click the app → Open (it is not from the App Store, so your Mac asks once).

## How to use it

- **Move it**: click anywhere on the video and drag.
- **Resize it**: drag the edges. It keeps its tall phone shape.
- **Like a video**: move your mouse over the window, click the ❤️. Hearts fly. Your like counts on the real site.
- **Sound**: click the speaker icon to unmute.
- **Close**: click the ✕ in the corner.
- Controls hide by themselves when your mouse leaves. Just the video, like Picture-in-Picture.
- It remembers where you left it.

## Build it yourself

```sh
./build.sh
open SlopWindow.app
```

You need the Xcode command line tools. That is all. One Swift file, no dependencies.

## How it works (short version)

The app opens the real website inside a hidden browser view, then injects a bit of CSS that hides everything except the video. The buttons you see (❤️, ✕, speaker) are native Mac buttons drawn on top. The ❤️ button calls the site's own like code, so likes are real.

Built with a [Gauntlet Loop](https://somethingbig.ai/gauntlet-loop): one agent builds, a separate fresh agent judges it against real macOS Picture-in-Picture, repeat. Round log lives in `workbench.md`.
