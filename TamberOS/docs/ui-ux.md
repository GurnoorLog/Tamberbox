# TamberOS UI/UX blueprint · screen by screen

Breakpoints: 1920×1080 primary; 1280×720 minimum; display scaling 100–200%. Support keyboard navigation, controller navigation in Game Mode, high-contrast focus rings and reduced motion. Use `prototype/index.html` for a clickable **design mock**, not functional hardware UI.

| # | Screen | Signature layout | Primary interactions | V1 build gate |
|---|---|---|---|---|
| 01 | **Boot** | Crown/wordmark on near-black; narrow orange progress mark | None; boot stage status | Plymouth displays after kernel KMS; boot firmware visuals optional |
| 02 | **Sign-in** | Cream typography and subdued orange artwork; password field; switch user | Keyboard input, submit, power actions | SDDM theme usable with verified display stack |
| 03 | **First run** | Llama portrait, four-step setup progress | Locale, Wi-Fi, privacy, features (skip possible) | Opt-in toggles persist; no silent downloads |
| 04 | **Desktop/Home** | Rail navigation, current time, hero panel, recent apps, modes | Launch app, search, quick actions, switch modes | Keyboard navigation + real app discovery |
| 05 | **App launcher** | Search-first grid with categories and recently used apps | Search, pin, launch, close | Parse desktop entries safely, no shell string construction |
| 06 | **AI Studio** | Llama left pane, model state, conversations, input with action chips | Local prompt, cancel, select model, save local history | Ollama endpoint tested; no pretend model/remote access |
| 07 | **Game Mode** | Fullscreen cover carousel/grid, visible controller focus | D-pad navigation, confirm/back, resume last game | Launch configured local apps only; no bundled ROMs |
| 08 | **System Center** | Temperature, CPU, RAM, NVMe, network, GPU/NPU capabilities | Refresh, inspect provenance/units | Sensors discovered & labeled; missing ≠ zero |
| 09 | **Settings** | Left categories and compact form panels | Appearance, audio, connectivity, display, AI, privacy | Read/write only user settings; privileged paths separated |
| 10 | **Files** | Places sidebar, file grid/list, breadcrumb | Browse, open, search, copy | Operate only within permissions of signed-in user |
| 11 | **Quick controls** | Compact overlay from panel | Wi-Fi, audio, battery/power, night mode | If hardware data missing show unavailable |
| 12 | **About / Updates** | Version, hardware info, licensing, update channel | Check updates, view changelog | Signed repositories & tested rollback strategy |

## Navigation model
- Rail: Home / AI / Games / Files / System / Settings; launcher and power controls live in bottom utility area.
- `Super` opens search/launcher, `Esc` closes overlays, tab navigation has visible focus.
- Game Mode can be entered from Home and exited through a clear on-screen action, not a hidden key.
- The launcher must not trap users if the AI service or network is offline.

## Interaction copy
- AI offline: "Local assistant is not configured" plus a setup action, **not** fake conversations.
- NPU unavailable: "NPU driver or runtime not detected" instead of fabricated TOPS usage.
- Updates: label available upgrades distinctly from installed updates; explain reboot requirement.
- Error recovery: "Return to Desktop" always visible in fullscreen experiences.

## Storyboard / route tree

```text
BOOT -> SIGN IN -> [FIRST RUN if new] -> HOME
HOME -> APPS / AI STUDIO / GAME MODE / FILES / SYSTEM / SETTINGS
                                  GAME MODE -> HOME
HOME -> QUICK CONTROLS -> SETTINGS
SETTINGS -> ABOUT + UPDATES
```

## Art direction of each flagship surface
- **Boot:** dark void, crown drawn in orange, small line under wordmark.
- **Login:** calm cinematic gradient, pale rim-light around mascot silhouette but no dense poster typography.
- **Home:** giant “YOUR BOX. YOUR RULES.” editorial line next to a panel with actual system state; warm cream, orange vertical hairlines.
- **AI:** original sunglasses llama at top of pane; clear disclosure local/remote and model context.
- **Games:** big cards, orange active border; no unlicensed cover art in distributed builds.
- **System:** technical, sparse, believable; never show sample numbers as live after prototype.

## Acceptance metrics (targets, not claims)
- Responsive at 1280×720 with no clipped primary navigation.
- A keyboard-only user can use major navigation.
- No more than 200ms UI work blocking the event loop for ordinary screen changes (measure).
- User can disable animation.
- Every feature advertises whether it is mock, beta, available or unsupported.
