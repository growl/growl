#include "GrowlVersionUtilities.h"

static CFStringRef releaseTypeNames[] = {
	CFSTR(""), CFSTR(" SVN "), CFSTR("d"), CFSTR("a"), CFSTR("b"),
};

#pragma mark Parsing and unparsing

bool parseVersionString(CFStringRef string, struct Version *outVersion) {
	if(!string) return false;

	unsigned myMajor = 0U, myMinor = 0U, myIncremental = 0U, myReleaseType = releaseReleaseType, myDevelopment = 0U;

	CFIndex maxAllocation = getpagesize();
	CFRange range = { 0, CFStringGetLength(string) };
	Boolean canConvert = CFStringGetBytes(string, range,
											  kCFStringEncodingUTF8,
											  /*lossByte*/ 0U,
											  /*isExternalRepresentation*/ false,
											  /*buffer*/ NULL,
											  maxAllocation,
											  &maxAllocation);
	if(!canConvert) return false;

	char *buf = malloc(maxAllocation);
	if(!buf) return false;

	CFIndex length = 0;
	canConvert = CFStringGetBytes(string, range,
								  kCFStringEncodingUTF8,
								  /*lossByte*/ 0U,
								  /*isExternalRepresentation*/ false,
								  buf,
								  maxAllocation,
								  &length);
	if(canConvert) {
		//converted to UTF-8 successfully. parse it.
		CFIndex i = 0;

		//major version
		while(i < length) {
			if(!isdigit(buf[i])) break;
			myMajor *= 10U;
			myMajor += digittoint(buf[i++]);
		}
		if(i >= length) goto end;

		//separator
		if(buf[i] != '.') goto end;
		++i;

		//minor version
		while(i < length) {
			if(!isdigit(buf[i])) break;
			myMinor *= 10U;
			myMinor += digittoint(buf[i++]);
		}
		if(i >= length) goto end;

		//separator
		if(buf[i] == '.') {
			++i;

			//incremental version
			while(i < length) {
				if(!isdigit(buf[i])) break;
				myIncremental *= 10U;
				myIncremental += digittoint(buf[i++]);
			}
			if(i >  length) goto end;
		}

		//release type
		if(i != length) {
			while((i < length) && isspace(buf[i])) ++i;

			if(i < length) {
				char releaseTypeChar = tolower(buf[i++]);
				switch(releaseTypeChar) {
					case 'b':
						myReleaseType = betaReleaseType;
						break;
					case 'a':
						myReleaseType = alphaReleaseType;
						break;
					case 'd':
						myReleaseType = developmentReleaseType;
						break;
					case 's':
						myReleaseType = svnReleaseType;
						if((i < length) && (buf[i] == 'v')) {
							++i;
							if((i < length) && (buf[i] == 'n'))
								++i;
						}
						break;
				}

				while((i < length) && isspace(buf[i])) ++i;
				//for example: "0.6.2 SVN r1558". we want to skip the 'r'.
				if((i < length) && (myReleaseType == svnReleaseType) && (tolower(buf[i]) == 'r'))
					++i;

				//if there's no development version,
				//	default to 0 for releases and svn versions,
				//	and 1 for development versions, alphas, and betas.
				if(i == length)
					myDevelopment = ((myReleaseType != releaseReleaseType) && (myReleaseType != svnReleaseType));
				else {
					//development version
					while(i < length) {
						if(!isdigit(buf[i])) break;
						myDevelopment *= 10U;
						myDevelopment += digittoint(buf[i++]);
					} //while(i < length)
				} //if(++i != length)
			} //if(i < length)
		} //if(i != length)
	} //if(canConvert)

end:
	free(buf);

	if(outVersion) {
		outVersion->major       = myMajor;
		outVersion->minor       = myMinor;
		outVersion->incremental = myIncremental;
		outVersion->releaseType = myReleaseType;
		outVersion->development = myDevelopment;
	}

	return true;
}

CFStringRef createVersionDescription(const struct Version v) {
	/*the struct Version structure contains two u_int16_ts, two u_int8_ts, and one u_int32_t.
	 *the maximum number of decimal digits in an u_int32_t is 10 (UINT_MAX=4294967295).
	 *the maximum number of decimal digits in an u_int16_t is 5 (USHRT_MAX=65535).
	 *the maximum number of decimal digits in an u_int8_t  is 3 (UCHAR_MAX=255).
	 *the maximum length of a release type name (see releaseTypeNames above)
	 *	is 5 (" SVN " including spaces).
	 *thus, the maximum length of a version description is:
	 *	5 + 5 + 3 + 5 + 10 = 28.
	 */
	CFMutableStringRef str = CFStringCreateMutable(kCFAllocatorDefault, /*capacity*/ 28);
	CFStringAppendFormat(CFSTR("%hu.%hu"), /*formatOptions*/ NULL, v.major, v.minor);
	if(v.incremental)
		CFStringAppendFormat(CFSTR("%hhu"), /*formatOptions*/ NULL, v.incremental);
	if(v.releaseType != releaseType_release)
		CFStringAppendFormat(CFSTR("%@%hu"), /*formatOptions*/ NULL, v.development);
	return str;
}

#pragma mark -
#pragma mark Comparison

signed int compareVersions(unsigned major0, unsigned minor0, unsigned incremental0, unsigned releaseType0, unsigned development0, unsigned major1, unsigned minor1, unsigned incremental1, unsigned releaseType1, unsigned development1)
{
	if(major0       <  major1)       return -1;
	if(major0        > major1)       return  1;
	if(minor0       <  minor1)       return -1;
	if(minor0        > minor1)       return  1;
	if(incremental0 <  incremental1) return -1;
	if(incremental0  > incremental1) return  1;

	if(releaseType0 <  releaseType1) return -1;
	if(releaseType0  > releaseType1) return  1;
	if(development0 <  development1) return -1;
	if(development0  > development1) return  1;

	return 0;
}

static signed int compareVersionStrings(CFStringRef a, CFStringRef b) {
	if(a == b)  return  0;
	else if(!a) return  1;
	else if(!b) return -1;

	struct Version v_a, v_b;
	bool parsed_a, parsed_b;

	parsed_a = parseVersionString(a, &v_a);
	parsed_b = parseVersionString(b, &v_b);

	//strings that could not be parsed sort above strings that could.
	if(!parsed_a)
		return parsed_b ? -1 : 0;
	else if(!parsed_b)
		return parsed_a ?  1 : 0;

	return compareVersions(v_a, v_b);
}

//this function is explained in the header.
signed int compareVersionStringsTranslating1_0To0_5(CFStringRef a, CFStringRef b) {
	CFStringRef  one_zero = CFSTR("1.0");
	CFStringRef zero_five = CFSTR("0.5");
	if(CFEqual(a, one_zero)) a = zero_five;
	if(CFEqual(b, one_zero)) b = zero_five;
	return compareVersionStrings(a, b);
}
