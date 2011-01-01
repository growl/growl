//
//  SynergyIconSource.h
//  GrowlTunes-Synergy
//
//  Created by Peter Hosey on 08/31/2004.
//

#import <Cocoa/Cocoa.h>
#import "GrowlTunesPlugin.h"

@interface SynergyIconSource: NSObject <GrowlTunesPlugin>
{
	NSString *synergySubPath;
}
@end
