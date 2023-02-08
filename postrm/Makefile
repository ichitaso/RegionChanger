TARGET := iphone:clang:15.5:13.0
MIN_IOS_SDK_VERSION = 11.0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = postrm

postrm_FILES = main.m
postrm_CFLAGS = -fobjc-arc
postrm_CODESIGN_FLAGS = -Sentitlements.plist
postrm_INSTALL_PATH = /DEBIAN

include $(THEOS_MAKE_PATH)/tool.mk
