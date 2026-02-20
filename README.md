# BlueprintOS

BlueprintOS is now a **Linux distribution project** (not just an app layer).

## What changed
- Own distro structure (`distro/`)
- Custom Linux kernel config (`distro/kernel/configs/blueprint_defconfig`)
- Root filesystem build pipeline (Debian base via `debootstrap`)
- Bootable ISO pipeline (GRUB + xorriso)
- First-party installer/bootstrap scripts

## Goal
Build a bootable, voice-first, agentic Linux distro with:
- Custom kernel tuning for low-latency audio + AI workloads
- Native speech-to-speech runtime
- Visual shell/dashboard
- Deterministic image build process

## Current repo layout

```text
blueprintos/
├── distro/
│   ├── kernel/
│   │   ├── configs/blueprint_defconfig
│   │   └── patches/
│   ├── rootfs/
│   │   ├── overlay/
│   │   │   ├── etc/blueprintos-release
│   │   │   └── usr/local/bin/blueprint-firstboot
│   │   └── packages/base.txt
│   ├── iso/
│   │   └── grub/grub.cfg
│   └── scripts/
│       ├── build-kernel.sh
│       ├── build-rootfs.sh
│       └── build-iso.sh
├── blueprint-core/
├── blueprint-sts/
├── blueprint-ui/
└── Makefile
```

## Core setup (today)

### 1) Install build dependencies (Ubuntu/Debian host)
```bash
sudo apt update
sudo apt install -y build-essential git bc bison flex libssl-dev libelf-dev \
  debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools \
  rsync cpio dosfstools
```

### 2) Build kernel + rootfs + ISO
```bash
make kernel
make rootfs
make iso
```

Output artifacts:
- `build/kernel/bzImage`
- `build/rootfs.squashfs`
- `build/blueprintos-dev.iso`

## Notes
- This is **core distro scaffolding** for day-1.
- Kernel and ISO scripts are production-oriented stubs and can now be iterated.
- Next milestone: boot test in QEMU + firstboot service wiring + STS daemon in init system.

## License
MIT
