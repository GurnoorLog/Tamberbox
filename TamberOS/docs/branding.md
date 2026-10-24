# TamberOS visual identity

Reference: `references/tamberbox-poster.png` (user-supplied design reference). Reuse its mood, not its typography or layouts verbatim.

## Palette

| Token | Hex | Purpose |
|---|---|---|
| `ink` | `#0C0C0E` | immersive surfaces, background |
| `panel` | `#181A1E` | cards, overlays |
| `raised` | `#24262B` | hover, selected fills |
| `orange` | `#FF5A1F` | accent, active indicator |
| `orange-soft` | `#FF9255` | highlights |
| `cream` | `#F2EEE5` | main text |
| `muted` | `#AAA7A4` | secondary text |
| `line` | `#323337` | hairline border |
| `success` | `#80DBA3` | verified available only |

Color does *not* convey status alone. Default contrast must meet WCAG AA for text; lighter orange can be used for smaller text.

## Type and grid
- Display: condensed heavy uppercase style (fallback `Arial Narrow`, `Impact`). Do **not** distribute proprietary font binaries.
- UI: `Inter`, `Noto Sans` or system sans-serif **when installed**; bundle nothing without a license audit.
- Spacing: 4px system, major cards 20–28px internal; corners 12–20px.
- Motion: 180–300ms ease-out transitions; reduced motion setting must disable nonessential animation.
- Decorations: diagonal hatching, a few orange slash marks, segmented section labels; avoid full-page comic texture during routine work.

## Marks
- Original `branding/tamber-crown.svg`: compact monoline crown; simple secondary mark.
- Original `branding/tamber-llama.svg`: sunglasses llama identity. A **design placeholder**, not the Ollama logo. Keep identifiable without text; add variants after review.
- `TAMBEROS` wordmark: all-caps, orange `OS`; `TAMBERBOX` is hardware naming, distinct from OS.

## Usage hierarchy
1. **Boot:** crown and TamberOS, minimal, no flashy claims.
2. **Sign-in:** logo + restrained ambient illustrations.
3. **Desktop:** system typography + orange focus; mascot rarely intrudes.
4. **AI Studio / Welcome:** mascot is prominent; playful expression allowed.
5. **Games:** media-forward visuals with controller-friendly focus states.

## Asset/legal notes
The poster is a private visual reference in this scaffold. Confirm redistribution rights before publishing it. Avoid calling the original mascot an official Ollama trademark or implying endorsement.
