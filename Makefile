THEOS_DEVICE_IP = 10.0.1.6

SYSROOT = /var/SDKS/iPhoneOS$(SDKVERSION).sdk

SDKVERSION = 4.0

TWEAK_NAME = DeepEnd
DeepEnd_OBJC_FILES = DeepEnd.m
DeepEnd_FRAMEWORKS = Foundation UIKit CoreMotion QuartzCore

ADDITIONAL_CFLAGS = -std=c99

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
