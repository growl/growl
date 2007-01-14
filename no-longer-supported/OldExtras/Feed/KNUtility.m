/*

BSD License

Copyright (c) 2004, Keith Anderson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

*	Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
*	Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.
*	Neither the name of keeto.net or Keith Anderson nor the names of its
	contributors may be used to endorse or promote products derived
	from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


*/

#import "KNUtility.h"
#import "Prefs.h"
#import <stdarg.h>
#import "NSNumber+KNRandom.h"
#import <SystemConfiguration/SCNetworkReachability.h>

void KNDebug(NSString *format,...){
	if( [PREFS debugging] ){
		va_list argPtr;
		va_start( argPtr, format );
		NSLogv(format, argPtr);
		va_end(argPtr);
	}
}

#define KEYSPACEBASE 65
#define KEYSPACESIZE 26
NSString *KNUniqueKeyWithLength(int keyLength){
	int				i;
	char			key[256];
	
	if( keyLength > 255 ){ keyLength = 255; }
	for(i=0;i<keyLength;i++){
		key[i] = (char) (KEYSPACEBASE + (int)([NSNumber randomFloat] * KEYSPACESIZE));
	}
	key[i] = '\0';
	return [NSString stringWithCString: key];
}


BOOL KNNetworkReachablePolitely(NSString * hostName){
	BOOL						result = NO;
	SCNetworkConnectionFlags	flags;
	
	if( SCNetworkCheckReachabilityByName( (const char *)[hostName cString], &flags ) ){
		result = !(flags & kSCNetworkFlagsConnectionRequired) && (flags & kSCNetworkFlagsReachable);
	}
	return result;
}



