# Building BlueprintOS (core distro setup)

## Host requirements
- Debian/Ubuntu host
- sudo/root access
- ~20GB free disk

## Build flow
1. `make kernel`
2. `make rootfs`
3. `make iso`

## Notes
- `build-kernel.sh` expects Linux source at `workdir/linux` (or set `KERNEL_SRC`)
- `build-rootfs.sh` uses debootstrap (bookworm)
- `build-iso.sh` currently uses rootfs squashfs as initrd placeholder
