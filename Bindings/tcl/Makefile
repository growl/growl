DESTDIR =
PREFIX = /Library/Tcl/growl1.0

CC = gcc
CFLAGS = -fno-common -dynamiclib -install_name $(PREFIX)/$(DYLIB_NAME)
FRAMEWORKS = -framework Cocoa -framework Tcl
SRCS = growl.m
DYLIB_NAME = libgrowl.dylib

all:
	mkdir -p .libs
	$(CC) -I../.. $(CFLAGS) $(FRAMEWORKS) $(SRCS) -o .libs/$(DYLIB_NAME)

install: all
	mkdir -p $(DESTDIR)$(PREFIX)
	install -m 444 .libs/$(DYLIB_NAME) $(DESTDIR)$(PREFIX)
	echo pkg_mkIndex $(DESTDIR)$(PREFIX) | tclsh

clean:
	rm -r .libs
