# Building BlueprintOS (distro core)

## Host requirements (Debian/Ubuntu)
```bash
sudo apt update
sudo apt install -y build-essential git bc bison flex libssl-dev libelf-dev \
  debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools \
  rsync cpio dosfstools qemu-system-x86
```

## Build flow
```bash
make rootfs
make iso
make qemu
```

Artifacts:
- `build/live/vmlinuz`
- `build/live/initrd.img`
- `build/live/filesystem.squashfs`
- `build/blueprintos-dev.iso`

## Custom kernel path
Custom kernel scaffolding remains at:
- `distro/kernel/configs/blueprint_defconfig`
- `distro/scripts/build-kernel.sh`

Current live ISO path uses Debian kernel+initramfs from rootfs for reliable bring-up. Next iteration can switch ISO to custom kernel once initramfs integration is complete.
