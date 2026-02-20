SHELL := /bin/bash

.PHONY: all kernel rootfs iso clean

all: kernel rootfs iso

kernel:
	bash distro/scripts/build-kernel.sh

rootfs:
	bash distro/scripts/build-rootfs.sh

iso:
	bash distro/scripts/build-iso.sh

clean:
	rm -rf build workdir
