# Gauntlet Loop — SlopWindow (floating infiniteslop.ai player for macOS)

## Goal
Native mac app: floating always-on-top window playing https://infiniteslop.ai video only, with like (❤️) ability.

## Bar
**macOS native Picture-in-Picture window** (Safari/QuickTime PiP): borderless rounded window, shadow,
hover-reveal controls, hidden-at-rest chrome, drag anywhere, floats over everything incl. fullscreen apps.
Plus mechanical checklist:

| # | Check | Status |
|---|-------|--------|
| 1 | Builds clean via swiftc, zero warnings | ✅ |
| 2 | Video plays (screenshot shows live frame) | ✅ |
| 3 | Floats above other apps + fullscreen (level/collectionBehavior) | ✅ |
| 4 | Video-only: no sidebar/chat/queue/credits visible | ✅ |
| 5 | Like works: heart visible, click POSTs api/like, count shown | ✅ |
| 6 | Drag anywhere + resizable | ✅ |
| 7 | Controls hover-reveal, hidden at rest (PiP behavior) | ✅ |
| 8 | Rounded corners + shadow like PiP | ✅ |
| 9 | Remembers frame across launches | ✅ |
| 10 | Quit affordance (hover ✕) | ✅ |

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

### Round 2 — CRITIC VERDICT: **bar wins** (closer)
Passes 8/9: playback, float, chrome, like (0→1+burst), edge-to-edge (0px L/R; ~2pt
top/bottom ring, marginal pass), hover/auto-hide, corners+shadow, persistence (exact).
biggest_gap: stability — 1/5 drags over-tracked (-120,+40 → -165,+49) then +129,-87
UNCOMMANDED drift; later process died silently mid-session (no .ips, log clean);
crash-path relaunch lost size (340×604 → 239×425). Evidence: shots/critic2_*.png.

### Round 3 — builder triage queue
1. Uncommanded drift + over-track: suspect stale dragOffset (mouseUp missed under synthetic
   streams / drift = later mouseDragged with stale offset). Fix: derive drag from event
   deltaX/deltaY or clear offset on any non-dragged event; guard with pressedMouseButtons.
2. Silent death: no crash log → likely killed? or WebKit GPU process issue. Add minimal
   stderr logging + NSSetUncaughtExceptionHandler; reproduce via long-run soak.
3. Crash lost size: autosave writes on move/resize normally — crash between resize+write?
   Persist explicitly on frame change.

### Round 3 — builder
Fixes: (a) drag coords now event-derived globals (locationInWindow + frame origin) — kills
cursor-poll race behind over-track; (b) mouseDragged guards NSEvent.pressedMouseButtons,
clears stale offset — kills uncommanded drift after missed mouseUp; (c) explicit
saveFrame on mouseUp — crash can't lose frame; (d) webViewWebContentProcessDidTerminate
→ auto-reload; (e) NSSetUncaughtExceptionHandler → NSLog; app soak-run with stderr→soak.log.
Smoke: 3/3 drags pixel-exact incl. cold-first (1045,426 / 1245,366 / 1165,246). soak.log 0 bytes.

### Round 3 — CRITIC running (fresh context, critic3_*.png, 10-item checklist incl. stability)

### Round 3 — CRITIC VERDICT: **bar wins** (one defect left)
9/10 pass: playback, float, chrome, drag (8/8 idle-gated drags 0px error 0 drift incl.
cold + 4s slow), edge-to-edge 0.0pt, hover/auto-hide, corners+shadow, persistence exact,
stability (alive start+end, soak.log empty).
FAIL #4 like: app's heartPress() call leaves site holdTimer running → count self-inflates
(719→824 in 12.3s, ~8.5/s) + permanent heart rain over video.
INSTRUMENT CORRECTION (equal prominence, per gauntlet rule): round-2's "over-track,
uncommanded drift" findings were CONTAMINATED by the live human cursor at this Mac —
critic-3 sampled cursor during "zero input" and matched every jump 1:1 to external cursor
deltas. Round-2 drift finding retracted; round-3 idle-gated table is authoritative.
Round-2 "silent death" remains unexplained but unreproduced across 2 long sessions.

### Round 4 — builder
Fix: append stopHold() right after heartPress() in like() JS (Sources/main.swift:228).
Site's heartPress starts a 140ms setInterval shower only pointer-up clears; we have no
pointer-up in the page, so we clear it explicitly.

### Round 4 — CRITIC VERDICT: **OURS WINS** 🏁
All pass: like-leak fixed (0 hearts at t+10/25/40s, count 0→1→per-clip reset, burst <2s),
like registers, drags 0px error, rest-hide, playback, stability (soak.log 0 bytes).
Evidence: shots/critic4_*.png.

## Run summary
4 rounds, 4 fresh-context critics, bar = native macOS PiP + 10-item mechanical checklist.
R1 gap: drag broken + matte → fixed (acceptsFirstMouse, manual 1:1 drag, full-bleed CSS).
R2 gap: drift/over-track + silent death → drift later RETRACTED as live-human-cursor
contamination (critic-3 proved it); hardening kept (event-derived coords, saveFrame,
webcontent auto-reload, exception logging). Death never reproduced across 3 long sessions.
R3 gap: like hold-timer leak → fixed (stopHold()).
R4: ours beats bar on all measured checks. Note: over-fullscreen-app float set via
fullScreenAuxiliary but not explicitly exercised by a critic.
Most reusable artifact: instrument notes (screencapture -l only, fresh bounds every query,
idle-gate against live human cursor).
