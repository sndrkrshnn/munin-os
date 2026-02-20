SHELL := /bin/bash

.PHONY: all bins models kernel rootfs validate iso qemu smoke ci ci-smoke clean

all: bins rootfs validate iso

bins:
	bash distro/scripts/build-munin-binaries.sh

models:
	bash distro/scripts/model-manager.sh

kernel:
	bash distro/scripts/build-kernel.sh

rootfs:
	bash distro/scripts/build-rootfs.sh

validate:
	bash distro/scripts/validate-image.sh

iso: validate
	bash distro/scripts/build-iso.sh

qemu:
	bash distro/scripts/run-qemu.sh

smoke:
	bash distro/scripts/qemu-smoke-test.sh

ci:
	bash distro/scripts/ci-build.sh

ci-smoke:
	bash distro/scripts/ci-boot-smoke.sh

clean:
	rm -rf build workdir/iso
