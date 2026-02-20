SHELL := /bin/bash

.PHONY: all kernel rootfs iso qemu clean

all: rootfs iso

kernel:
	bash distro/scripts/build-kernel.sh

rootfs:
	bash distro/scripts/build-rootfs.sh

iso:
	bash distro/scripts/build-iso.sh

qemu:
	bash distro/scripts/run-qemu.sh

clean:
	rm -rf build workdir/iso
