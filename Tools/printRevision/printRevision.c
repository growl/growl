//Note: hgRevision.h must be included on the command line. The Makefile does this when run by generateHgRevision.sh.
#include <stdio.h>

int main(void) {
	return !printf("%s\n", HG_REVISION_STRING);
}
