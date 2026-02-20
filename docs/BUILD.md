# Building MuninOS (distro core)

## Host requirements (Debian/Ubuntu)
```bash
sudo apt update
sudo apt install -y build-essential git bc bison flex libssl-dev libelf-dev \
  debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools \
  rsync cpio dosfstools qemu-system-x86
```

## Build flow (Apple Silicon)
```bash
ARCH=arm64 make bins
ARCH=arm64 make rootfs
ARCH=arm64 make validate
ARCH=arm64 make iso
ARCH=arm64 make qemu
```

Optional user override:
```bash
ARCH=arm64 DEFAULT_USER=munin DEFAULT_PASS=munin make rootfs
```

Or run end-to-end in one shot:
```bash
make ci
```

With boot smoke test included:
```bash
make ci-smoke
```

`make bins` compiles:
- `munin-core`
- `munin-sts`
- `munin-brain`
- `munin-audio`
- `munin-ui` (from `munin-ui-service`)

and stages them into `build/munin-bin/` for rootfs embedding.

Artifacts:
- `build/live/vmlinuz`
- `build/live/initrd.img`
- `build/live/filesystem.squashfs`
- `build/muninos-arm64-dev.iso` (or `muninos-amd64-dev.iso` for x86 builds)

## Optional custom kernel
```bash
make kernel
make rootfs
make iso
```
If `build/kernel/bzImage` exists, ISO build prefers it.

## Validation checks
`make validate` ensures rootfs contains:
- `/opt/muninos/bin/munin-core`
- `/opt/muninos/bin/munin-sts`
- `/opt/muninos/bin/munin-ui`
- systemd units: `munin-core/sts/ui/firstboot.service`
- UI assets at `/opt/muninos/ui/index.html`
- `/etc/default/munin-sts`

## QEMU smoke test
`make smoke` boots the ISO headless and checks serial logs for Linux/systemd boot markers.

Artifacts:
- `build/smoke/serial.log`

Tune timeout if needed:
```bash
TIMEOUT_SECS=180 make smoke
```

## First boot behavior
- default login user is created during rootfs build (`munin/munin` by default)
- `munin-firstboot.service` runs `munin-firstboot-wizard` once
- captures hostname/timezone and writes `/etc/muninos/setup.env`
- enables `munin-core`, `munin-sts`, `munin-ui`

## STS key at runtime
Set in image/host:
- `/etc/default/munin-sts`
- `QWEN_API_KEY=...`
