//
//  GrowlSafari.h
//  GrowlSafari
//
//  Created by Kevin Ballard on 10/29/04.
//  Copyright 2004 Kevin Ballard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GrowlSafari : NSObject
{
}
+ (NSBundle *)bundle;
@end

@interface NSObject (GrowlSafariPatch)
- (void)mySetDownloadStage:(int)stage;
- (void)myUpdateDiskImageStatus:(NSDictionary *)status;
@end
