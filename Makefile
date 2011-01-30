TWEAK_NAME = DeepEnd
DeepEnd_OBJC_FILES = DeepEnd.m
DeepEnd_FRAMEWORKS = Foundation UIKit CoreMotion QuartzCore

ADDITIONAL_CFLAGS = -std=c99

LOCALIZATION_PROJECT_NAME = DeepEnd
LOCALIZATION_DEST_PATH = /Library/PreferenceLoader/Preferences/DeepEnd/

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
include Localization/makefiles/common.mk
