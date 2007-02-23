#
#  $Id$
#
#  Copyright 2007 The Growl Project. All rights reserved.
#
# This file is under the BSD License, refer to license.txt for details

i386_SDK_PATH = /Developer/xulrunner/mozilla/obj-xulrunner/dist/sdk
i386_XULRUNNER_BIN = /Developer/xulrunner/mozilla/obj-xulrunner/dist/bin
GROWL_FRAMEWORK_PATH = /Users/sdwilsh/growl/branches/growl-0.7/build/Development
XPIDL_PATH = /Developer/xulrunner/mozilla/obj-xulrunner/xpcom/typelib/xpidl
COMPONENTS_DIR = /Users/sdwilsh/growl/branches/moz-extension/trunk/components
PPC_SDK_PATH = /Developer/gecko-sdk

INCLUDES = \
  -I$(COMPONENTS_DIR)/headers \
  -I$(i386_SDK_PATH)/include \
  -F$(GROWL_FRAMEWORK_PATH)

XPIDL_INCLUDES = \
  -I$(i386_SDK_PATH)/idl

LINK_FLAGS = \
  -F$(GROWL_FRAMEWORK_PATH) \
  -lxpcomglue_s \
  -lxpcom \
  -lnspr4 \
  -framework Growl \
  -framework Cocoa

PPC_LINK_FLAGS = \
  -L$(PPC_SDK_PATH)/lib \
  -L$(PPC_SDK_PATH)/bin \
	-Wl,-executable_path,$(PPC_SDK_PATH)/lib \
  $(LINK_FLAGS)

i386_LINK_FLAGS = \
  -L$(i386_SDK_PATH)/lib \
  -L$(i386_XULRUNNER_BIN) \
  -Wl,-executable_path,$(i386_XULRUNNER_BIN) \
  $(LINK_FLAGS)

DEFINES = \
  -DXP_MACOSX
