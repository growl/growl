#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <CoreFoundation/CoreFoundation.h>
#include "GrowlDefinesCarbon.h"

#define MakeCFString(x) CFStringCreateWithCString(kCFAllocatorDefault, x, kCFStringEncodingASCII)
#define ArrayRefOK(x) (SvROK(x) && (SvTYPE(SvRV(x)) == SVt_PVAV) && av_len((AV*)SvRV(x)) >= 0)

/*Create a CFArray from a perl array of strings*/
CFArrayRef CFArrayFromSV(AV * array)
{
	I32 len = av_len(array);
	CFMutableArrayRef arr = CFArrayCreateMutable(kCFAllocatorDefault, len+1, NULL);
	int i;
	STRLEN l;

	for(i = 0;i <= len; i++)
	{
		CFArrayAppendValue(arr,MakeCFString(SvPV(*av_fetch(array,i,0),l)));
	}
	return arr;
}

MODULE = Mac::Growl		PACKAGE = Mac::Growl

void
RegisterNotifications(app, all, def)
		const char * app
		SV * all
		SV * def
	INIT:
		CFArrayRef allArray, defArray;
		CFStringRef appName;
		
		if(!ArrayRefOK(all) || !ArrayRefOK(def))
		{
			XSRETURN_UNDEF;
		}
		
		CFNotificationCenterRef distCenter = CFNotificationCenterGetDistributedCenter();
		CFMutableDictionaryRef note = CFDictionaryCreateMutable(
											kCFAllocatorDefault,
											3,
											NULL, NULL);
	CODE:
		allArray = CFArrayFromSV((AV *)SvRV(all));
		defArray = CFArrayFromSV((AV *)SvRV(def));
		appName = MakeCFString(app);

		CFDictionaryAddValue(note,GROWL_APP_NAME,appName);
		CFDictionaryAddValue(note,GROWL_NOTIFICATIONS_ALL,allArray);
		CFDictionaryAddValue(note,GROWL_NOTIFICATIONS_DEFAULT,defArray);

		CFNotificationCenterPostNotification(distCenter, GROWL_APP_REGISTRATION, NULL, note, FALSE);

		/*CFRelease(allArray);
		CFRelease(defArray);
		CFRelease(appName);
		CFRelease(note);*/
		
void PostNotification(app, noteName, title, description)
		const char * app
		const char * noteName
		const char * title
		const char * description
	INIT:
		CFNotificationCenterRef distCenter = CFNotificationCenterGetDistributedCenter();
		CFMutableDictionaryRef note = CFDictionaryCreateMutable(
											kCFAllocatorDefault,
											4,
											NULL, NULL);
		
	CODE:
		CFDictionaryAddValue(note, GROWL_NOTIFICATION_TITLE,MakeCFString(title));
		CFDictionaryAddValue(note, GROWL_NOTIFICATION_DESCRIPTION, MakeCFString(description));
		CFDictionaryAddValue(note, GROWL_APP_NAME, MakeCFString(app));
		CFNotificationCenterPostNotification(distCenter, MakeCFString(noteName), NULL, note, TRUE);
		
		/*CFRelease(note);*/

