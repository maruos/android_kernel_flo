# Modified from original AndroidKernel.mk for Maru OS

#Android makefile to build kernel as a part of Android Build
PERL		= perl

KERNEL_LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_PREBUILT_KERNEL),)

# flo requires arm-eabi-4.8 toolchain, which is not included in PATH by
# default so we use an absolute path
KERNEL_CROSS_COMPILE := $(ANDROID_BUILD_TOP)/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-

KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
KERNEL_CONFIG := $(KERNEL_OUT)/.config
TARGET_PREBUILT_INT_KERNEL := $(KERNEL_OUT)/arch/arm/boot/zImage
KERNEL_HEADERS_INSTALL := $(KERNEL_OUT)/usr
KERNEL_IMG=$(KERNEL_OUT)/arch/arm/boot/Image

ifeq ($(TARGET_USES_UNCOMPRESSED_KERNEL),true)
$(info Using uncompressed kernel)
TARGET_PREBUILT_KERNEL := $(KERNEL_OUT)/piggy
else
TARGET_PREBUILT_KERNEL := $(TARGET_PREBUILT_INT_KERNEL)
endif

$(KERNEL_OUT):
	mkdir -p $(KERNEL_OUT)

$(KERNEL_CONFIG): $(KERNEL_OUT)
	$(MAKE) -C $(KERNEL_LOCAL_PATH) O=../../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) $(KERNEL_DEFCONFIG)

$(KERNEL_OUT)/piggy : $(TARGET_PREBUILT_INT_KERNEL)
	$(hide) gunzip -c $(KERNEL_OUT)/arch/arm/boot/compressed/piggy.gzip > $(KERNEL_OUT)/piggy

$(TARGET_PREBUILT_INT_KERNEL): $(KERNEL_OUT) $(KERNEL_CONFIG) $(KERNEL_HEADERS_INSTALL)
	$(MAKE) -C $(KERNEL_LOCAL_PATH) O=../../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_CROSS_COMPILE)

$(KERNEL_HEADERS_INSTALL): $(KERNEL_OUT) $(KERNEL_CONFIG)
	$(MAKE) -C $(KERNEL_LOCAL_PATH) O=../../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) headers_install

kerneltags: $(KERNEL_OUT) $(KERNEL_CONFIG)
	$(MAKE) -C $(KERNEL_LOCAL_PATH) O=../../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) tags

kernelconfig: $(KERNEL_OUT) $(KERNEL_CONFIG)
	env KCONFIG_NOTIMESTAMP=true \
	     $(MAKE) -C $(KERNEL_LOCAL_PATH) O=../../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) menuconfig
	env KCONFIG_NOTIMESTAMP=true \
	     $(MAKE) -C $(KERNEL_LOCAL_PATH) O=../../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) savedefconfig
	cp $(KERNEL_OUT)/defconfig kernel/arch/arm/configs/$(KERNEL_DEFCONFIG)

endif

kernelclean:
	$(MAKE) -C $(KERNEL_LOCAL_PATH) O=../../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) clean
	$(RM) -r $(KERNEL_CONFIG)
	$(RM) -r $(KERNEL_HEADERS_INSTALL)
