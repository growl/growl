FRAMEWORKS = -framework Cocoa -framework Tcl
SRCS = growl.m
DESTDIR =
PREFIX = /Library/Tcl/growl1.0
DYLIB_NAME = libgrowl.dylib
DYLIB_FLAGS = -dynamiclib -install_name ${PREFIX}/${DYLIB_NAME} -compatibility_version 1 -current_version 1
CFLAGS = -fno-common

all:
	mkdir -p .libs
	gcc -I../.. ${CFLAGS} ${DYLIB_FLAGS} ${FRAMEWORKS} ${SRCS} -o .libs/${DYLIB_NAME}

install: all
	mkdir -p ${DESTDIR}${PREFIX}
	install -m 444 .libs/${DYLIB_NAME} ${DESTDIR}${PREFIX}
	echo pkg_mkIndex ${DESTDIR}${PREFIX} | tclsh

distclean:
	rm -r .libs
