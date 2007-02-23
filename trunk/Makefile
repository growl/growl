#
#  $Id$
#
#  Copyright 2007 The Growl Project. All rights reserved.
#
# This file is under the BSD License, refer to license.txt for details

include conf.mk
include files.mk
include content/files.mk
include components/files.mk
include platform/files.mk

FILES = $(ROOT_FILES)
FILES += $(patsubst %,content/%, $(CONTENT_FILES))
FILES += $(patsubst %,components/%, $(COMPONENT_FILES))
FILES += $(patsubst %,platform/%, $(PLATFORM_FILES))
FILES += Growl.framework/*

all: build package

build:
	@@cd components; $(MAKE)

package: build copy
	@@cd components; $(MAKE) package
	zip growl.xpi $(FILES)

copy:
	cp -rf $(GROWL_FRAMEWORK_LOCATION) .

clean:
	@@cd components; $(MAKE) clean
	rm -rf Growl.framework
	rm -f growl.xpi
