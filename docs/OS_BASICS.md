# MuninOS Basics (from first principles)

## 1) What is an Operating System?
An OS is the software layer between hardware and applications.

It provides:
- process management (run programs)
- memory management (RAM allocation)
- file systems (read/write files)
- networking
- device access (audio, display, keyboard, mic)
- security and permissions

## 2) What is a kernel?
The kernel is the core of the OS.

In Linux, the kernel:
- schedules CPU time
- handles interrupts from hardware
- manages virtual memory
- loads device drivers
- enforces process isolation

Without a kernel, user apps cannot safely/usefully access hardware.

## 3) What is a Linux distribution?
A distro = Linux kernel + user-space tools + package manager + init system + defaults.

For MuninOS that means:
- Linux kernel (boot payload)
- root filesystem (Debian-based userspace)
- systemd services (`munin-core`, `munin-sts`, `munin-ui`)
- bootable ISO tooling

## 4) What is architecture (arm64)?
Architecture is CPU instruction set.

- `arm64` (AArch64): Apple Silicon, many phones/embedded/server devices
- `amd64` (x86_64): Intel/AMD desktops/servers

Binaries compiled for one architecture usually do not run natively on the other.

## 5) What is boot flow?
Typical flow:
1. Firmware (UEFI/BIOS) starts
2. Bootloader (GRUB) loads kernel + initramfs
3. Kernel initializes hardware
4. `systemd` (PID 1) starts
5. systemd launches services/apps

## 6) What is initramfs?
A minimal temporary filesystem loaded in RAM at early boot.
It helps kernel mount the real root filesystem and continue startup.

## 7) What is rootfs?
The real OS filesystem tree (`/etc`, `/usr`, `/var`, `/home`, ...).
MuninOS builds this using debootstrap + overlays.

## 8) Why MuninOS services?
- `munin-sts`: speech I/O runtime
- `munin-core`: decision/planning/tool-call brain
- `munin-ui`: visual shell/status interface

These are the agentic layer on top of Linux fundamentals.
