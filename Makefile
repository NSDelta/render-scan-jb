TARGET = iphone:clang:latest:14.0
ARCHS = arm64

# Dopamine 是 rootless 越狱, 必须用 rootless 打包 scheme
export THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RenderTraceTweak

RenderTraceTweak_FILES = Tweak.x
RenderTraceTweak_CFLAGS = -fobjc-arc
RenderTraceTweak_LDFLAGS = -Wl,-U,_objc_msgSend -Wl,-U,_hookf

include $(THEOS_MAKE_PATH)/tweak.mk