//
//  GrowlApplicationAdditions.m
//  Growl
//
//  Created by Evan Schoenberg on 11/5/08.
//

#import "GrowlApplicationAdditions.h"

void GrowlGetSystemVersion(NSUInteger *outMajor, NSUInteger *outMinor,NSUInteger *outIncremental)
{
    OSErr err;
    SInt32 systemVersion, versionMajor, versionMinor, versionBugFix;
    if ((err = Gestalt(gestaltSystemVersion, &systemVersion)) != noErr) goto fail;
    if (systemVersion < 0x1040)
    {
        if (outMajor) *outMajor = ((systemVersion & 0xF000) >> 12) * 10 +
            ((systemVersion & 0x0F00) >> 8);
        if (outMinor) *outMinor = (systemVersion & 0x00F0) >> 4;
        if (outIncremental) *outIncremental = (systemVersion & 0x000F);
    }
    else
    {
        if ((err = Gestalt(gestaltSystemVersionMajor, &versionMajor)) != noErr) goto fail;
        if ((err = Gestalt(gestaltSystemVersionMinor, &versionMinor)) != noErr) goto fail;
        if ((err = Gestalt(gestaltSystemVersionBugFix, &versionBugFix)) != noErr) goto fail;
        if (outMajor) *outMajor = versionMajor;
        if (outMinor) *outMinor = versionMinor;
        if (outIncremental) *outIncremental = versionBugFix;
    }
    
    return;
    
fail:
    NSLog(@"Unable to obtain system version: %ld", (long)err);
    if (outMajor) *outMajor = 10;
    if (outMinor) *outMinor = 0;
    if (outIncremental) *outIncremental = 0;
}
