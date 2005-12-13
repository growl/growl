/*
 
 BSD License
 
 Copyright (c) 2005, Jesper <wootest@gmail.com>
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 * Neither the name of Gmail+Growl or Jesper, nor the names of Gmail+Growl's contributors 
 may be used to endorse or promote products derived from this software without
 specific prior written permission.
 
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
 
 The name Gmail is owned by Google, Inc. Growl is owned by the Growl Development Team.
 Likewise, the logos of those services are owned and copyrighted to their owners.
 No ownership of any of these is assumed or implied, and no infringement is intended.
 
 For more info on this products or on the technologies on which it builds: 
				Growl: <http://growl.info/>
                Gmail: <http://gmail.com>
       Gmail Notifier: <http://toolbar.google.com/gmail-helper/index.html>
 
		  Gmail+Growl: <http://wootest.net/gmailgrowl/>
 
 */

//
//  GMNGrowlController.h
//  GMNGrowl
//
//  Created by Jesper on 2005-09-02.
//  Copyright 2005 Jesper. All rights reserved.
//  Contact: <wootest@gmail.com>.
//

#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>

@protocol GGPluginProtocol;

@interface GMNGrowlController : NSObject <GGPluginProtocol> {
	NSData *defIcon;
}
- (NSDictionary *)normalizeMessageDict:(NSDictionary *)di;
- (NSData *)iconDataBasedOnSender:(NSString *)email;
@end
