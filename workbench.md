# Gauntlet Loop — SlopWindow (floating infiniteslop.ai player for macOS)

## Goal
Native mac app: floating always-on-top window playing https://infiniteslop.ai video only, with like (❤️) ability.

## Bar
**macOS native Picture-in-Picture window** (Safari/QuickTime PiP): borderless rounded window, shadow,
hover-reveal controls, hidden-at-rest chrome, drag anywhere, floats over everything incl. fullscreen apps.
Plus mechanical checklist:

| # | Check | Status |
|---|-------|--------|
| 1 | Builds clean via swiftc, zero warnings | ⬜ |
| 2 | Video plays (screenshot shows live frame) | ⬜ |
| 3 | Floats above other apps + fullscreen (level/collectionBehavior) | ⬜ |
| 4 | Video-only: no sidebar/chat/queue/credits visible | ⬜ |
| 5 | Like works: heart visible, click POSTs api/like, count shown | ⬜ |
| 6 | Drag anywhere + resizable | ⬜ |
| 7 | Controls hover-reveal, hidden at rest (PiP behavior) | ⬜ |
| 8 | Rounded corners + shadow like PiP | ⬜ |
| 9 | Remembers frame across launches | ⬜ |
| 10 | Quit affordance (hover ✕) | ⬜ |

## Recon findings (instrument notes — later agents read this)
- Site: vanilla HTML+JS, HLS stream `live/playlist.m3u8` via hls.min.js, `<video id="tv">` inside `#tvwrap > #reel > .vcell`.
- Like: `#heartbtn` (fixed pos, retro style) → `heartPress(x,y)` → `likeOnce()` → `POST api/like {seg}` — one like per viewer per segment.
- Hide list: `#sidebar #chat #chattoggle #credit #topleft #livepill #splash`. KEEP `#tsmodal` (Turnstile) + `#namemodal` visible if shown.
- `#mute` button exists — video autoplays muted; keep unmute affordance.

## Rounds log
(append: round N — piece — critic verdict — biggest gap)

### Instrument notes (verified)
- `screencapture -R<region>` UNRELIABLE here (grabbed underlying window). USE `screencapture -x -l<windowID>`.
- Window ID via CGWindowListCopyWindowInfo filtering kCGWindowOwnerName=="SlopWindow".
- Mouse move/click via CGEvent (swift /tmp/mm.swift X Y) works; coords = global top-left origin.

### Round 1 — builder v1 done
Built clean. Screenshot r1_win.png: video plays (AI content), rounded corners, hover controls
(✕ TL, speaker TR, ❤️+count BL). Known candidate gaps for critic: black gutters around video
(site desktop CSS letterboxes 12px sides), speaker icon state mapping, rest-state hiding TBD.

### Round 1 — builder self-checks (pre-critic, evidence on disk)
- r1_win.png: hover state — video + ✕/speaker/❤️9 controls, rounded corners.
- r1_rest2.png: rest state — all controls hidden, clean video ✓
- r1_afterlike.png: after native ❤️ click — site heart-cascade animation fired → likeOnce() POST path ✓
- Drag test: bounds moved (920,542)→(800,610) ✓. Edge-drag resizes (aspect-locked) — PiP-consistent.
- layer=3 (floating) ✓. Clean launch lands 340×605 bottom-right ✓.
- Mystery resolved-ish: earlier size drift = frame autosave + accidental edge-resize during mouse tests.

### Round 1 — CRITIC running (fresh context, own captures critic1_*.png)

### Round 1 — CRITIC VERDICT: **bar wins**
biggest_gap: drag-to-move broken under synthetic events (1/7 drags moved window, none 1:1;
resize dead in test) + video not edge-to-edge (8pt/15pt black matte).
Passes: playback, float, chrome-strip, like (22→23 + burst), hover-reveal/auto-hide,
corners+shadow, frame persistence (1px drift). Evidence: shots/critic1_*.png.

### Round 2 — builder
Root cause: NSView.acceptsFirstMouse=false swallowed first click in non-key panel;
performDrag flaky with synthetic streams. Fix: acceptsFirstMouse=true (overlay+buttons),
manual 1:1 drag (mouseDown offset → mouseDragged setFrameOrigin), 8pt edge passthrough
for system resize, CSS full-bleed (100vw/100vh cover, no transform).

### Round 2 — builder smoke (evidence)
- Cold drag #1 (no prior click): requested (-200,+100) → landed exactly (878,355) ✓ 1:1
- Drag #2: requested (+150,-250) → landed exactly (1028,105) ✓ 1:1
- r2_rest6s.png: video edge-to-edge (matte gone), controls fully hidden at rest ✓
- Auto-hide: control-zone probe max=139 (white ✕ would read ~255) ✓; earlier r2_rest.png
  showed controls only because capture raced the 2.5s hide timer — instrument note: wait ≥5s.

### Round 2 — CRITIC running (fresh context, critic2_*.png)
