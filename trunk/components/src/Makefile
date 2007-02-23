#
#  $Id$
#
#  Copyright 2007 The Growl Project. All rights reserved.
#
# This file is under the BSD License, refer to license.txt for details

include ../conf.mk

CMMSRCS = \
  mozGrowlDelegate.mm \
  nsAlertsImageLoadListener.mm \
  nsAlertsServiceMac.mm

CPPSRCS = \
  module.cpp

CMMOBJS = $(sort $(patsubst %.mm,$(ARCH)/%.o, $(CMMSRCS)))
CPPOBJS = $(sort $(patsubst %.cpp,$(ARCH)/%.o, $(CPPSRCS)))

all: build link

build: setup $(CMMOBJS) $(CPPOBJS)

$(CPPOBJS): $(ARCH)/%.o: %.cpp
	@@echo $<
	g++ -o $@ -c $< $(DEFINES) $(INCLUDES) -arch $(ARCH)

$(CMMOBJS): $(ARCH)/%.o: %.mm
	@@echo $<
	g++ -o $@ -c $< $(DEFINES) $(INCLUDES) -arch $(ARCH)

link:
	g++ -o $(ARCH)/nsIAlertsService.dylib $(CMMOBJS) $(CPPOBJS) $(LINK_FLAGS) -arch $(ARCH) -dynamiclib

setup:
	@@mkdir -p ppc
	@@mkdir -p i386

clean:
	rm -rf ppc
	rm -rf i386
