#
#  $Id$
#
#  Copyright 2007 The Growl Project. All rights reserved.
#
# This file is under the BSD License, refer to license.txt for details

include conf.mk

all: build link

build:
	@@cd public; $(MAKE) build
#	@@cd src; $(MAKE) build ARCH="ppc"
	@@cd src; $(MAKE) build ARCH="i386"

link:
#	@@cd src; $(MAKE) link ARCH="ppc" LINK_FLAGS="$(PPC_LINK_FLAGS)"
	@@cd src; $(MAKE) link ARCH="i386" LINK_FLAGS="$(i386_LINK_FLAGS)"

package: setup
#	@@cp src/ppc/*.dylib ../platform/Darwin_ppc-gcc3/
	@@cp src/i386/*.dylib ../platform/Darwin_x86-gcc3/
	@@cp xpt/*.xpt .

setup:
	@@mkdir -p ../platform/Darwin_ppc-gcc3
	@@mkdir -p ../platform/Darwin_x86-gcc3

clean:
	@@cd public; make clean 
	@@cd src; make clean
	rm -rf ../platform/Darwin_ppc-gcc3
	rm -rf ../platform/Darwin_x86-gcc3
	rm -f *.xpt
