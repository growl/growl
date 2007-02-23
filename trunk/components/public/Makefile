#
#  $Id$
#
#  Copyright 2007 The Growl Project. All rights reserved.
#
# This file is under the BSD License, refer to license.txt for details

include ../conf.mk

XPIDLSRCS = \
	nsIAlertsService.idl

HEADERSRCS = \
	nsIAlertsService.idl \
  nsIStreamLoader.idl

HEADEROBJS = $(sort $(patsubst %.idl,%.h, $(HEADERSRCS)))
XPIDLOBJS  = $(sort $(patsubst %.idl,%.xpt, $(XPIDLSRCS)))

build: setup $(HEADEROBJS) $(XPIDLOBJS)

$(HEADEROBJS): %.h: %.idl
	@@echo $<
	$(XPIDL_PATH)/xpidl -m header -w $(XPIDL_INCLUDES) -e ../headers/$@ $< 

$(XPIDLOBJS): %.xpt: %.idl
	@@echo $<
	$(XPIDL_PATH)/xpidl -m typelib -w $(XPIDL_INCLUDES) -e ../xpt/$@ $< 

setup:
	@mkdir -p ../headers
	@mkdir -p ../xpt

clean:
	rm -rf ../headers
	rm -rf ../xpt
