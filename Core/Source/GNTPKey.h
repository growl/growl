//
//  GNTPKey.h
//  Growl
//
//  Created by Rudy Richter on 10/10/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlGNTPDefines.h"

NSString *HexEncode(NSData *data);
NSMutableData *HexUnencode(NSString* string);

@interface GNTPKey : NSObject 
{
	GrowlGNTPHashingAlgorithm _hashAlgorithm;
	GrowlGNTPEncryptionAlgorithm _encryptionAlgorithm;
	NSString *_password;
	NSData *_salt;
	NSData *_encryptionKey;
	NSData *_keyHash;

	NSData *_iv;
}

+ (BOOL)isSupportedHashAlgorithm:(NSString*)hash;
+ (BOOL)isSupportedEncryptionAlgorithm:(NSString*)algorithm;
+ (GrowlGNTPEncryptionAlgorithm)encryptionAlgorithmFromString:(NSString*)algorithm;
+ (GrowlGNTPHashingAlgorithm)hashingAlgorithmFromString:(NSString*)algorithm;

- (id)initWithPassword:(NSString*)password hashAlgorithm:(GrowlGNTPHashingAlgorithm)hashAlgorithm encryptionAlgorithm:(GrowlGNTPEncryptionAlgorithm)encryptionAlgorithm;
+ (NSData *)generateSalt:(int)length;
- (void)generateSalt;
- (void)generateKey;
- (NSString*)hashAlgorithmString;
- (NSString*)encryptionAlgorithmString;
- (NSData*)encrypt:(NSData*)bytes;
- (NSData*)decrypt:(NSData*)bytes;

- (NSData*)generateIV;

- (NSString*)key;
- (NSString*)encryption;

@property (assign) GrowlGNTPHashingAlgorithm hashAlgorithm;
@property (assign) GrowlGNTPEncryptionAlgorithm encryptionAlgorithm;
@property (retain) NSData *encryptionKey;
@property (retain) NSData *keyHash;
@property (retain) NSString *password;
@property (retain) NSData *salt;
@property (retain) NSData *IV;

@end
