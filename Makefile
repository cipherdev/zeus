#
# Nano Top Level Makefile
# Author: HuyLe (anhhuy@live.com)
#

VER:="1.01"
BUILD:="01"
export VER:=$(VER)
export BUILD:=$(BUILD)

LINUX_VER:="3.4.0"

#############################################################################
# To use the toolchain
#############################################################################
export CROSS_COMPILE:=arm-linux-
export PATH:=/home/huyle/nanopc/toolchain/4.9.3/bin:${PATH}
export GCC_COLORS=auto

BUILDBIN=BUILDS
CPUNAME=arm
PLATFORM=zeus

.PHONY: createdir uboot linux dtb

all: clean build

#############################################################################
# Build Target
#############################################################################
clean: 	uboot_clean \
	linux_clean \
	cleandir

build: 	createdir uboot_all linux_all

quick: createdir media_uboot linux

cleandir:
	@echo
	@echo "#################################### Clean Objs ############################"
	rm -rf ${BUILDBIN}

createdir:
	@echo
	@echo "################################# Create folder ############################"
	mkdir -p ${BUILDBIN}/${CPUNAME}

symlinks:
	@echo
	@echo "############################## Symbol Link File ############################"
	./makesymlink

uboot_clean:
	@echo
	@echo "################################## Clean U-Boot ############################"
	cd uboot; make distclean; cd -

uboot_config:
	@echo
	@echo "############################### Configure U-Boot ############################"
	cd uboot; make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} s5p6818_nanopi3_config; cd -

uboot_media:
	@echo
	@echo "################################ Build U-Boot media ##########################"
	cd uboot; make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} ; cd -
	cp -f uboot/u-boot.bin ${BUILDBIN}/${CPUNAME}/zeus_media.bin
	#slimimg -C -f ${UBOOTOBJS}/zeus_media.img -b 512 -s `stat -c %s ${UBOOTOBJS}/u-boot.bin` ${UBOOTOBJS}/u-boot.bin u-boot.bin
	#cp -f ${UBOOTOBJS}/zeus_media.img ${BUILDBIN}/${CPUNAME}


linux_clean:
	@echo
	@echo "################################## Clean Linux ##############################"
	cd linux; make distclean; cd -

linux_config:
	@echo
	@echo "############################## Configure Linux ##############################"
	cd linux; make ARCH=arm nanopi3_linux_defconfig; touch .scmversio; cd -

linux_menuconfig:
	@echo
	@echo "############################# Build linux smp menuconfig ###############################"
	cd linux; make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} menuconfig; cd -

linux_savedefconfig:
	@echo
	@echo "############################# Build linux smp savedefconfig #############################"
	cd linux; make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} savedefconfig; cd -

linux_modules:
	@echo
	@echo "############################# Build linux modules ###############################"
	cd linux; make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} INSTALL_MOD_PATH=../${BUILDBIN}/${CPUNAME}/modules modules modules_install ; cd -
	rm -f ${BUILDBIN}/${CPUNAME}/modules/lib/modules/*/build
	rm -f ${BUILDBIN}/${CPUNAME}/modules/lib/modules/*/source

linux:
	@echo
	@echo "############################# Build linux smp ###############################"
	cd linux; make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} -j 15 uImage; cd -
	#mkimage -A arm -O linux -C none -T kernel -a 0x00080000 -e 0x00080000 -n Linux -d ./arch/arm/boot/Image ./arch/arm/boot/uImage
	cp -f linux/arch/arm/boot/uImage ${BUILDBIN}/${CPUNAME}

dtb_clean:
	@echo
	@echo "############################# Clean Linux dtb ###############################"
	rm -f ${BUILDBIN}/${CPUNAME}/${PLATFORM}_*.dtb

dtb:
	@echo
	@echo "############################# Build Linux dtb ###############################"
	./scripts/dtc/dtc -O dtb -R 16 -o ${LINUXOBJS}/apm-zeus.dtb linux/arch/arm/boot/dts/apm-zeus.dts
	cp -f ${LINUXOBJS}/apm-zeus.dtb ${BUILDBIN}/${CPUNAME}

ramdisks:
	sudo tools/mkrootfs.sh -c uRamdisk -o ${BUILDBIN}/${CPUNAME}/uRamdisk
	file ${BUILDBIN}/${CPUNAME}/uRamdisk

uboot_all: media_uboot

linux_all: linux_config linux linux_modules

media_uboot: uboot_config uboot_media
