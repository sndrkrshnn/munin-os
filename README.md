# MuninOS

MuninOS is a **standalone Linux distribution** project (not an app inside another OS).

## Core direction
- Own distro tree (`distro/`)
- Custom kernel config (`distro/kernel/configs/munin_defconfig`)
- Rootfs pipeline (`debootstrap`) + bootable ISO pipeline (`grub-mkrescue`)
- Native services on boot: `munin-core`, `munin-sts`, `munin-ui` (all binary-first)
- First-boot wizard (`munin-firstboot-wizard`) for initial host setup

## Build quickstart (Debian/Ubuntu host)
```bash
sudo apt update
sudo apt install -y build-essential git bc bison flex libssl-dev libelf-dev \
  debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools \
  rsync cpio dosfstools qemu-system-x86

ARCH=arm64 make bins      # builds munin-core, munin-sts, munin-ui, munin-brain, munin-audio
TIER=Tier1Mobile make models   # download only selected preset model
ARCH=arm64 make rootfs
ARCH=arm64 make validate  # verifies binaries/units/assets inside rootfs
ARCH=arm64 make iso
ARCH=arm64 make smoke     # headless QEMU boot log smoke test
ARCH=arm64 make qemu
```

Artifacts:
- `build/live/vmlinuz`
- `build/live/initrd.img`
- `build/live/filesystem.squashfs`
- `build/muninos-<arch>-dev.iso` (e.g., `build/muninos-arm64-dev.iso`)

Default login for generated ISO:
- user: `munin`
- pass: `munin`
(override at build time with `DEFAULT_USER` and `DEFAULT_PASS`)

## Custom kernel path
If `build/kernel/bzImage` exists (from `make kernel`), ISO build automatically prefers it.

## Native service scaffolding (in image)
- `/etc/systemd/system/munin-core.service`
- `/etc/systemd/system/munin-sts.service`
- `/etc/systemd/system/munin-ui.service`
- `/etc/systemd/system/munin-firstboot.service`

Wrappers:
- `/usr/local/bin/munin-core`
- `/usr/local/bin/munin-sts`
- `/usr/local/bin/munin-ui`
- `/usr/local/bin/munin-firstboot-wizard`

## Agentic runtime (Phase 2 kickoff)
- `munin-audio`: low-latency audio runtime scaffold (driver-coupled loop path)
- `munin-brain`: adaptive decision engine (auto model tiering, llama.cpp-first backend strategy)
- `munin-core`: tool router + policy engine + approval queue
- `munin-core api` exposes transcript + approval endpoints
- `munin-ui` polls pending approvals and can approve/deny tool calls
- risky actions are marked for confirmation unless `--auto-approve` is used
- local-only mode: no external model API key required for core decisioning

### Default on-device model presets (llama.cpp)
- Tier0 (tiny): `munin-tiny-1b-instruct-q4.gguf`
- Tier1 (mobile): `munin-mobile-3b-instruct-q4.gguf`
- Tier2 (balanced): `munin-balanced-7b-instruct-q4.gguf`
- Tier3 (performance): `munin-performance-13b-instruct-q5.gguf`

Expected model directory: `/opt/muninos/models/`

Download only the model you need:
```bash
# explicit tier
TIER=Tier1Mobile bash distro/scripts/model-manager.sh

# or auto-select tier from host profile
TIER=auto bash distro/scripts/model-manager.sh
```

## Learning docs
- `docs/OS_BASICS.md`
- `docs/AGENTIC_ARCHITECTURE.md`

## Status
Boot-first distro bring-up is in place, and build pipeline now supports compiling + embedding Munin binaries into `/opt/muninos/bin` during image creation.
