/*
 Copyright (c) The Growl Project, 2004-2005
 All rights reserved.


 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:


 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. Neither the name of Growl nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.


 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WAR
RANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. I
N NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, IN
DIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, O
R PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILIT
Y, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERW
ISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE P
OSSIBILITY OF SUCH DAMAGE.

 */

//
//  GrowlCode.h
//  GrowlCode
//

#import <Foundation/Foundation.h>

@interface GrowlCode : NSObject
{
}
+ (NSBundle*)bundle;
+ (NSString*)applicationNameForGrowl;
+ (NSData*)applicationIconDataForGrowl;
+ (NSDictionary*)registrationDictionaryForGrowl;
@end

@interface NSObject (XCBuildOperation)
- (id)project;
- (NSString*)configurationName;
- (NSString*)buildAction;
- (int)totalNumberOfWarnings;
- (int)totalNumberOfErrors;
@end

@interface NSObject (PBXProject)
- (NSString*)name;
@end

@interface NSObject (GrowlCodePatch)
- (id)gcInitWithProject:(id)project buildAction:(id)buildAction configurationName:(id)configName
                                    overridingProperties:(id)override buildables:(id)buildables;
- (void)gcBuildOperationDidStop:(NSNotification*)theNotification;
@end
