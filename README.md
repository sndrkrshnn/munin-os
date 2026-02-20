# MuninOS

MuninOS is a **standalone Linux distribution** project (not an app inside another OS).

## Core direction
- Own distro tree (`distro/`)
- Custom kernel config (`distro/kernel/configs/munin_defconfig`)
- Rootfs pipeline (`debootstrap`) + bootable ISO pipeline (`grub-mkrescue`)
- Native services on boot: `munin-core`, `munin-sts`, `munin-ui`
- First-boot wizard (`munin-firstboot-wizard`) for initial host setup

## Build quickstart (Debian/Ubuntu host)
```bash
sudo apt update
sudo apt install -y build-essential git bc bison flex libssl-dev libelf-dev \
  debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools \
  rsync cpio dosfstools qemu-system-x86

make rootfs
make iso
make qemu
```

Artifacts:
- `build/live/vmlinuz`
- `build/live/initrd.img`
- `build/live/filesystem.squashfs`
- `build/muninos-dev.iso`

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

## Status
This push focuses on boot-first distro bring-up and native service wiring.
Next: replace wrapper placeholders with compiled Munin binaries in `/opt/muninos/bin` by default image build.
