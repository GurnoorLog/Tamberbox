# TamberOS final UI concept references

The 9-screen concept image was generated in the project conversation after the original starter kit. Each numbered crop is a **visual reference**, not a native bootloader theme or a real application screenshot.

Key concept: `01-bootloader-concept.png` — black canvas; orange crown; cream `TAMBER` + orange `OS`; sunglasses llama on the right; readable boot menu on the left.

Do not rasterize the entire bootloader illustration into a functional interactive menu. Boot behavior is board- and boot-stage-dependent:

1. RK3588 boot ROM and U-Boot are board-specific; do not assume GRUB exists.
2. First verify what output is possible in the device's actual bootloader and resolution.
3. If a graphical boot menu is supported, build an original graphical theme using licensed assets; preserve a plain-text recovery path.
4. Implement the smooth animated splash in Plymouth **after** the kernel starts and before the login manager; do not confuse it with the bootloader.
5. The login screen and desktop should reimplement the concepts using QML/SDDM/compositor as validated, not treat these screenshots as production UI.

## Existing editable assets

- `../../branding/tamber-crown.svg`
- `../../branding/tamber-logo.svg`
- `../../branding/tamber-llama.svg`

These are original starter-kit vectors; they are simplified placeholders, **not** the detailed mascot art shown in the generated concept image. Recreate original scalable mascot artwork before final production use. Avoid implying endorsement by the Ollama project.

## How to use these in Codex

Read `01-bootloader-concept.png`, the full montage, `docs/branding.md`, `docs/ui-ux.md`, and `prompts/04_BRAND_BOOT.md`. Write a staged implementation plan and a preview for bootloader, Plymouth, and SDDM **separately**, with clear notes on verified board support. Never overwrite the working TamberBox boot media.
