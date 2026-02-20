# BlueprintOS — Distro-first Plan

## Direction
BlueprintOS is now a **standalone Linux distribution** with a custom kernel and build pipeline.

## Phase 0 (Today) — Core distro setup ✅
- [x] Distro directory structure
- [x] Kernel config baseline (`blueprint_defconfig`)
- [x] Rootfs package manifest + overlay
- [x] ISO boot config (GRUB)
- [x] Build scripts (`build-kernel.sh`, `build-rootfs.sh`, `build-iso.sh`)
- [x] Top-level `Makefile`

## Phase 1 — Bootable dev image
- Build kernel + initramfs reliably
- Produce bootable ISO
- Validate boot in QEMU/VMware/VirtualBox

## Phase 2 — Blueprint services as native OS components
- STS daemon as system service
- Blueprint core orchestration service
- Visual shell launcher at boot

## Phase 3 — Installer + hardware bring-up
- Disk installer
- Audio stack tuning
- GPU/accelerator support profiles

## Success criteria for current push
- Repo reflects true distro architecture
- Scripts run on a Linux build host with expected dependencies
- Artifacts are produced under `build/`
