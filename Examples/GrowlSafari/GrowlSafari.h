//
//  GrowlSafari.h
//  GrowlSafari
//
//  Created by Kevin Ballard on 10/29/04.
//  Copyright 2004 Kevin Ballard. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GrowlSafari : NSObject {

}

@end

@interface NSObject (GrowlSafariPatch)
- (void) mySetDownloadStage:(int)stage;
- (void)myUpdateDiskImageStatus:(id)fp8;
@end
