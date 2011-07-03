//
//  GNTPKey.m
//  Growl
//
//  Created by Rudy Richter on 10/10/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import "GNTPKey.h"
#import <openssl/rand.h>
#import <openssl/md5.h>
#import <openssl/sha.h>
#import <openssl/evp.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

NSData *ComputeHash(NSData *data, GrowlGNTPHashingAlgorithm algorithm);

NSString *HexEncode(NSData *data)
{
    NSMutableString *hex = [NSMutableString string];
	unsigned char *bytes = (unsigned char *)[data bytes];
    char temp[3];
    NSUInteger i = 0;
	
    for (i = 0; i < [data length]; i++) {
        temp[0] = temp[1] = temp[2] = 0;
        (void)sprintf(temp, "%02x", bytes[i]);
        [hex appendString:[NSString stringWithUTF8String:temp]];
    }
	
    return hex;
}

NSMutableData *HexUnencode(NSString* string)
{
	NSMutableData *data = [NSMutableData data];
	
	for(NSUInteger i = 0; i < [string length]; i+=2)
	{
		NSString *substring = [string substringWithRange:NSMakeRange(i, 2)];
		char character = (char)(strtol([substring UTF8String], NULL, 16));
		
		[data appendBytes:&character length:sizeof(char)];
	}
	return data;
}

NSData *ComputeHash(NSData *data, GrowlGNTPHashingAlgorithm algorithm)
{
	NSData *result = nil;
	NSUInteger length = [data length];
	unsigned char *bytes = (unsigned char *)[data bytes];
	static const CC_LONG Growl_CC_LONG_Maximum = ~(CC_LONG)0;
	switch (algorithm)
	{
		case GNTPMD5:
		{
			unsigned char *value = (unsigned char*)calloc(CC_MD5_DIGEST_LENGTH, sizeof(unsigned char));
			if(value)
				MD5(bytes, length, value);
			result = [NSData dataWithBytesNoCopy:value length:CC_MD5_DIGEST_LENGTH freeWhenDone:YES];
			break;
		}
		case GNTPSHA1:
		{	
			unsigned char *value = (unsigned char*)calloc(CC_SHA1_DIGEST_LENGTH, sizeof(unsigned char));
			if(value)
				SHA1(bytes, length, value);
			result = [NSData dataWithBytesNoCopy:value length:CC_SHA1_DIGEST_LENGTH freeWhenDone:YES];
			break;
		}
		case GNTPSHA256:
		{	
			unsigned char *value = (unsigned char*)calloc(CC_SHA256_DIGEST_LENGTH, sizeof(unsigned char));
			if(value) {
				CC_SHA256_CTX context256;
				CC_SHA256_Init(&context256);
				while (length > Growl_CC_LONG_Maximum) {
					CC_SHA256_Update(&context256, bytes, Growl_CC_LONG_Maximum);
					bytes += Growl_CC_LONG_Maximum;
					length -= Growl_CC_LONG_Maximum;
				}
				if (length > 0) {
					//After the previous loop, we know length will be no more than Growl_CC_LONG_Maximum, so this cast is OK.
					CC_SHA256_Update(&context256, bytes, (CC_LONG)length);
				}
				CC_SHA256_Final(value, &context256);
			}
			result = [NSData dataWithBytesNoCopy:value length:CC_SHA256_DIGEST_LENGTH freeWhenDone:YES];
			break;
		}
		case GNTPSHA512:
		{	
			unsigned char *value = (unsigned char*)calloc(CC_SHA512_DIGEST_LENGTH, sizeof(unsigned char));
			if(value) {
				CC_SHA512_CTX context512;
				CC_SHA512_Init(&context512);
				while (length > Growl_CC_LONG_Maximum) {
					CC_SHA512_Update(&context512, bytes, Growl_CC_LONG_Maximum);
					bytes += Growl_CC_LONG_Maximum;
					length -= Growl_CC_LONG_Maximum;
				}
				if (length > 0) {
					//After the previous loop, we know length will be no more than Growl_CC_LONG_Maximum, so this cast is OK.
					CC_SHA512_Update(&context512, bytes, (CC_LONG)length);
				}
				CC_SHA512_Final(value, &context512);
			}
			result = [NSData dataWithBytesNoCopy:value length:CC_SHA512_DIGEST_LENGTH freeWhenDone:YES];
			break;
		}
		case GNTPNone:
		default:
			break;
	}
	return result;
}

@implementation GNTPKey

@synthesize hashAlgorithm = _hashAlgorithm;
@synthesize encryptionAlgorithm = _encryptionAlgorithm;
@synthesize encryptionKey = _encryptionKey;
@synthesize keyHash = _keyHash;
@synthesize password = _password;
@synthesize salt = _salt;
@synthesize IV = _iv;

+ (BOOL)isSupportedHashAlgorithm:(NSString*)algorithm
{
	BOOL result = NO;
	NSArray *encryptionAlgorithms = [NSArray arrayWithObjects:
									 GrowlGNTPNone, 
									 GrowlGNTPMD5, 
									 GrowlGNTPSHA1, 
									 GrowlGNTPSHA256, 
									 GrowlGNTPSHA512, 
									 nil];
	for(NSString *encryptionAlgorithm in encryptionAlgorithms)
		if([encryptionAlgorithm caseInsensitiveCompare:algorithm] == NSOrderedSame)
		{
			result = YES;
			break;
		}
	return result;	
}

+ (BOOL)isSupportedEncryptionAlgorithm:(NSString*)algorithm
{
	BOOL result = NO;
	NSArray *encryptionAlgorithms = [NSArray arrayWithObjects:
									 GrowlGNTPNone, 
									 /*GrowlGNTPAES, 
									 GrowlGNTPDES, 
									 GrowlGNTP3DES,*/ 
									 nil];
	for(NSString *encryptionAlgorithm in encryptionAlgorithms)
		if([encryptionAlgorithm caseInsensitiveCompare:algorithm] == NSOrderedSame)
		{
			result = YES;
			break;
		}
	return result;
}

+ (GrowlGNTPEncryptionAlgorithm)encryptionAlgorithmFromString:(NSString*)algorithm
{
	GrowlGNTPEncryptionAlgorithm result = GNTPNone;
	if([GNTPKey isSupportedEncryptionAlgorithm:algorithm])
	{
		if([algorithm isEqualToString:GrowlGNTPAES])
			result = GNTPAES;
		else if ([algorithm isEqualToString:GrowlGNTPDES])
			result = GNTPDES;
		else if ([algorithm isEqualToString:GrowlGNTP3DES])
			result = GNTP3DES;
	}
	return result;	
}

+ (GrowlGNTPHashingAlgorithm)hashingAlgorithmFromString:(NSString*)algorithm
{
	GrowlGNTPHashingAlgorithm result = GNTPNoHash;
	if([GNTPKey isSupportedHashAlgorithm:algorithm])
	{
		if([algorithm isEqualToString:GrowlGNTPMD5])
			result = GNTPMD5;
		else if ([algorithm isEqualToString:GrowlGNTPSHA1])
			result = GNTPSHA1;
		else if ([algorithm isEqualToString:GrowlGNTPSHA256])
			result = GNTPSHA256;
		else if ([algorithm isEqualToString:GrowlGNTPSHA512])
			result = GNTPSHA512;
	}
	return result;	
}

- (id)initWithPassword:(NSString*)password hashAlgorithm:(GrowlGNTPHashingAlgorithm)hashAlgorithm encryptionAlgorithm:(GrowlGNTPEncryptionAlgorithm)encryptionAlgorithm
{
	if((self = [super init]))
	{
		[self setPassword:password];
		[self setHashAlgorithm:hashAlgorithm];
		[self setEncryptionAlgorithm:encryptionAlgorithm];
	}
	return self;
}

+ (NSData *)generateSalt:(int)length
{
    unsigned char *buffer;
    
    buffer = (unsigned char *)calloc(length, sizeof(unsigned char));
    NSAssert((buffer != NULL), @"Cannot calloc memory for buffer.");
    
    RAND_bytes(buffer, length);
    
    return [NSData dataWithBytesNoCopy:buffer length:length freeWhenDone:YES];;
}

- (void)generateSalt
{
	NSData *salt = [GNTPKey generateSalt:16];
	[self setSalt:salt];
}

- (void)generateKey
{
	NSMutableData *keyBasis = [NSMutableData dataWithData:[[self password] dataUsingEncoding:NSUTF8StringEncoding]];
	[keyBasis appendData:[self salt]];
	NSData *keyBytes = ComputeHash(keyBasis, [self hashAlgorithm]);
	[self setEncryptionKey:keyBytes];
	NSData *keyHashBytes = ComputeHash(keyBytes, [self hashAlgorithm]);
	
	[self setKeyHash:keyHashBytes];
	[self setIV:[self generateIV]];
}

- (NSString*)hashAlgorithmString
{
	NSString *result = nil;
	switch ([self hashAlgorithm])
	{
		case GNTPMD5:
			result = GrowlGNTPMD5;
			break;
		case GNTPSHA1:
			result = GrowlGNTPSHA1;
			break;
		case GNTPSHA256:
			result = GrowlGNTPSHA256;
			break;
		case GNTPSHA512:
			result = GrowlGNTPSHA512;
			break;
		case GNTPNone:
		default:
			result = GrowlGNTPNone;
			break;
	}
	return result;
}

- (NSString*)encryptionAlgorithmString
{
	NSString *result = nil;
	switch ([self encryptionAlgorithm])
	{
		case GNTPAES:
			result = GrowlGNTPAES;
			break;
		case GNTPDES:
			result = GrowlGNTPDES;
			break;
		case GNTP3DES:
			result = GrowlGNTP3DES;
			break;
		case GNTPNone:
		default:
			result = GrowlGNTPNone;
			break;
	}
	return result;	
}

- (NSData*)encrypt:(NSData*)bytes
{
	NSData *result = nil;
	
	NSUInteger keySize = -1;
	NSUInteger ivSize = -1;
	SEL algorithm = nil;
	
	switch([self encryptionAlgorithm])
	{
      case GNTPNone:
         result = bytes;
         break;
		default:
         return result;
			break;
	}
	
	if([[self keyHash] length] > keySize)
	{
		if(![self IV] || [[self IV] length] < ivSize)
			[self setIV:[self generateIV]];

		result = [self performSelector:algorithm withObject:bytes];
	}
	return result;
}

- (NSData*)decrypt:(NSData*)bytes
{
	NSData *result = nil;
	
	NSUInteger keySize = -1;
	NSUInteger ivSize = -1;
	SEL algorithm = nil;
	
	switch([self encryptionAlgorithm])
	{
      case GNTPNone:
         result = bytes;
         break;
		default:
			return result;
			break;
	}
	
	if([[self keyHash] length] > keySize)
	{
		if(![self IV] || [[self IV] length] < ivSize)
			[self setIV:[self generateIV]];
		
		result = [self performSelector:algorithm withObject:bytes];
		//NSLog(@"%@ %@ %@", [self keyHash], [self IV], [self salt], HexUnencode(HexEncode(result)));
	}
	return result;
}

- (NSData*)generateIV
{
	NSData *ivData = nil;

	const 
	EVP_CIPHER *cipher = nil;
	NSInteger blockSize = 0;
	switch ([self encryptionAlgorithm])
	{
		case GNTPNone:
		default:
			break;
	}
	unsigned char *iv = (unsigned char *)calloc(blockSize, sizeof(unsigned char));
	if (iv) {
		bzero(iv, blockSize * sizeof(unsigned char));
		unsigned char evpKey[EVP_MAX_KEY_LENGTH] = {"\0"};
		if (cipher) {
			//Cast explanation: EVP_BytesToKey takes an int for the length, but NSData's length method returns NSUInteger. As long as encryption keys are created by hashing strings, they are not likely to ever be large enough for their lengths to exceed the range of an int.
			EVP_BytesToKey(cipher, EVP_md5(), NULL, (const unsigned char*)[[self encryptionKey] bytes], (int)[[self encryptionKey] length], 1, evpKey, iv);
		}

		ivData = [NSData dataWithBytesNoCopy:iv length:blockSize freeWhenDone:YES];
	}

	return ivData;
}

- (NSString*)key
{
	NSString *algorithm = [self hashAlgorithmString];
	NSString *keyHash = HexEncode([self keyHash]);
	NSString *salt = HexEncode([self salt]);
	return [NSString stringWithFormat:@"%@:%@.%@", algorithm, keyHash, salt];
}

- (NSString*)encryption
{
	NSString *encryptionAlgorithm = [self encryptionAlgorithmString];
	//if(![self IV])
	//	[self setIV:[self generateIV]];
	NSString *initializationValue = HexEncode([self IV]);
	return [NSString stringWithFormat:@"%@%@", encryptionAlgorithm, ([encryptionAlgorithm isEqual:GrowlGNTPNone] ? @"" : [NSString stringWithFormat:@":%@", initializationValue])];
}

@end
