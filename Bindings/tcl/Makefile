DESTDIR =
PREFIX = /Library/Tcl/growl1.0

CC = gcc
CFLAGS = -fno-common -dynamiclib -install_name $(PREFIX)/$(DYLIB_NAME) -DUSE_TCL_STUBS -ltclstub8.4
FRAMEWORKS = -framework Cocoa -framework Tcl
SRCS = growl.m
DYLIB_NAME = libgrowl.dylib

MKDIR = /bin/mkdir -p -m 0555
RMDIR = /bin/rm -fr
INSTALL = /usr/bin/install -m 0444
TCLSH = /usr/bin/tclsh

all:
	$(MKDIR) ".libs"
	$(CC) -I../.. $(CFLAGS) $(FRAMEWORKS) $(SRCS) -o .libs/$(DYLIB_NAME)

install: all
	$(MKDIR) "$(DESTDIR)$(PREFIX)"
	$(INSTALL) ".libs/$(DYLIB_NAME)" "$(DESTDIR)$(PREFIX)"
	echo pkg_mkIndex "$(DESTDIR)$(PREFIX)" | $(TCLSH)

uninstall:
	$(RMDIR) "$(DESTDIR)$(PREFIX)"

clean:
	$(RMDIR) ".libs"
