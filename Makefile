TWEAK_NAME = DeepEnd
DeepEnd_OBJC_FILES = DeepEnd.m
DeepEnd_FRAMEWORKS = Foundation UIKit CoreMotion

ADDITIONAL_CFLAGS = -std=c99

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
