# Milestones and acceptance gates

## M0 · Project foundation ✅ draft
- [x] README, architecture, brand, screen-by-screen UI blueprint
- [x] Original SVG mascot/crown prototypes
- [x] Browser-based interactive UI prototype
- [x] Basic Qt 6/QML shell demo source
- [x] Read-only telemetry CLI and offline unit tests
- [ ] User reviews brand identity / colors / mascot likeness

## M1 · AlmaLinux ARM64 development — development acceptance complete
- [x] Dated AlmaLinux 10.2 aarch64 image downloaded and SHA256 checked
- [x] File-only QEMU lifecycle, cloud-init generation and offline tests implemented
- [x] Exact-Ultra source research and package listing evidence recorded
- [x] Pinned QEMU aarch64 AlmaLinux 10 guest boots with matching firmware
- [x] Boot/login/proxy HTTPS/package manager demonstrated with real log capture
- [x] Qt6/QML and RPM toolchain candidates chosen from official 10.2 aarch64 listings
- [x] Toolchain installation and compilation verified inside AlmaLinux ARM64 QEMU
- [x] CI workflow defined for offline tests and ARM64 AlmaLinux shell compilation
- [x] CI executed remotely and native ARM64 compilation passes

## M2 · Ultra hardware boot (critical path)
- [ ] Capture known-good exact-board boot inventory
- [x] Build disposable test image from board-specific boot assets + AlmaLinux rootfs (offline CI; not board-boot verified)
- [ ] Serial output and HDMI confirm boot; machine identity recorded
- [ ] Basic input/network/storage, no fatal regressions; backup recovery tested

## M3 · Session UX — remote development implementation
- [x] Select Sway for isolated Wayland development; actual board graphics and SDDM login remain pending
- [x] Implement desktop launcher and original login/boot theme sources; authentication and boot execution remain unverified
- [ ] Complete accessibility, shutdown/logout, multi-monitor and service integration acceptance
- [x] Keyboard application launch and real compositor window actions in ARM64 virtual desktop
- [x] Functional app launching and settings persistence in a session prototype (ARM64 X11; not board tested)

## M4 · Tamber modes
- [ ] AI adapter with explicit permission/connection and installed-model listing
- [ ] Game Mode with controller navigation and executable launcher profiles
- [ ] System Center with measured telemetry and provenance
- [ ] Per-feature quality gates and failures/recovery flows

## M5 · Distribution
- [ ] Reproducible RPMs and repo metadata
- [ ] Image build manifests, exact versions, SHA256, SBOM and licenses
- [ ] Update/rollback strategy validated on test media
- [ ] Fresh install and upgrade acceptance tests

## First 20 implementation issues
1. Add VM setup script with SHA256 verification (no host writes).
2. Document AlmaLinux 10 ARM64 QEMU boot and cloud-init.
3. Verify Qt6/SDDM/Plymouth RPM sources on chosen base.
4. Define board boot inventory report format.
5. Add read-only board inventory collector with redaction.
6. Produce boot-chain integration experiment design.
7. Build test image safely on loopback file.
8. Validate image mount/partitions with rootless checks where practical.
9. Boot on disposable test SD; document evidence.
10. Add GPU/Wayland capability matrix.
11. Compile QML shell in VM; test 1280×720.
12. Replace demo navigation with Qt-native responsive pages.
13. Add keyboard focus, Escape, search overlay.
14. Build application metadata discovery + launch safety.
15. Package first `tamber-shell` RPM.
16. Implement Plymouth theme with no vendor asset redistribution.
17. Implement sign-in theme after SDDM availability verified.
18. Replace mock metrics with read-only local service.
19. Integrate optional Ollama connectivity with explicit offline states.
20. Create first versioned pre-alpha installer image + rollback notes.
