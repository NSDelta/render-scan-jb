TARGET = iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RenderTraceTweak

RenderTraceTweak_FILES = Tweak.x
RenderTraceTweak_CFLAGS = -fobjc-arc
RenderTraceTweak_LDFLAGS = -Wl,-U,_objc_msgSend -Wl,-U,_hookf

include $(THEOS_MAKE_PATH)/tweak.mk