# it is needed for ndk-r5
APP_PLATFORM := android-10
APP_STL := c++_static
APP_CPPFLAGS := -frtti -std=c++11 -fsigned-char -Wno-extern-c-compat
APP_LDFLAGS := -latomic
#APP_MODULES := PluginProtocolStatic
APP_ABI := armeabi-v7a
APP_SHORT_COMMANDS := true
#APP_ABI :=x86
#APP_ABI :=mips mips-r2 mips-r2-sf armeabi
