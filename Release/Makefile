# This is just a trampoline Makefile that asserts that the source tree is in good shape for a release build. The actual targets are in the other Makefile.
#
# If you invoke it without specifying a target, or by specifying the all target, this Makefile will only proceed to the real Makefile when your source tree is totally clean.
# If you specify the all-withlocalchanges target, then you *can* have local changes, just not conflicts. This saves waiting through the long build process only to have it choke on the last file because it's conflicted. Use this sparingly, because release builds with local changes are Very Very Bad. (The main reason to do this is because you've added debug logging.)

.PHONY: all all-withlocalchanges assertnochanges assertnoconflicts

# Front-end targets: Use these on the command line.
all: assertnochanges
all-withlocalchanges: assertnoconflicts

# Back-end targets: Front-end targets should depend on these. Generally not for use on the command line.
assertnochanges:
	if [[ 0 -ne `svn st $(SRC_DIR) | egrep -v '^X' | wc -l` ]]; then \
		echo 'You have local changes. Please do not build releases from an unclean checkout. You must revert the changes, commit them, or check out another working copy and build from that.' 1>&2; \
		exit 1; \
	fi
	$(MAKE) -f Real-Makefile.make
assertnoconflicts:
	if [[ 0 -ne `svn st $(SRC_DIR) | egrep '^[CX]' | wc -l` ]]; then \
		echo 'You have conflicts in your checkout. You will not be able to build until these are resolved. Also, remember that even after you have fixed all conflict marks, you must use "svn resolved"; otherwise, svn will still believe the files are conflicted.' 1>&2; \
		exit 2; \
	fi
	$(MAKE) -f Real-Makefile.make
