//
//  GNTPPacket.m
//  GNTPTestServer
//
//  Created by Daniel Siemer on 7/2/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GNTPPacket.h"
#import "GNTPKey.h"
#import "GCDAsyncSocket.h"
#import "NSStringAdditions.h"

@implementation GNTPPacket

@synthesize key;
@synthesize connectedHost;
@synthesize gntpDictionary = _gntpDictionary;
@synthesize growlDictionary = _growlDictionary;

+(BOOL)isValidKey:(GNTPKey*)key
		forPassword:(NSString*)password
{
   GNTPKey *remoteKey = [[[GNTPKey alloc] initWithPassword:password
															hashAlgorithm:[key hashAlgorithm]
													encryptionAlgorithm:[key encryptionAlgorithm]] autorelease];
   [remoteKey setSalt:[key salt]];
   NSData *IV = [key IV];
   [remoteKey generateKey];
   if(IV)
      [remoteKey setIV:IV];
   
   if ([HexEncode([key keyHash]) caseInsensitiveCompare:HexEncode([remoteKey keyHash])] == NSOrderedSame)
      return YES;
   return NO;
}

+ (BOOL)isAuthorizedPacketType:(NSString*)action
							  withKey:(GNTPKey*)key
							forSocket:(GCDAsyncSocket*)socket
							errorCode:(GrowlGNTPErrorCode*)errCode
						 description:(NSString**)errDescription
{
   NSString *conHost = nil;
   if([socket connectedHost])
      conHost = [socket connectedHost];
   else{
      NSLog(@"We dont know what host sent this (will show as missing hash string error)");
      *errCode = GrowlGNTPInternalServerErrorErrorCode;
      *errDescription = NSLocalizedString(@"We encountered an error parsing the packet, we don't know where it came from", @"GNTP error");
      return NO;
   }
   
   //GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
   
   if(![conHost isLocalHost])
   {
      /* These two cases are for if the socket has to be open for subscription, but not remote notes/registration, or vice versa */
      if(!YES/*[preferences isGrowlServerEnabled]*/ && ([action caseInsensitiveCompare:GrowlGNTPNotificationMessageType] == NSOrderedSame ||
																		  [action caseInsensitiveCompare:GrowlGNTPRegisterMessageType] == NSOrderedSame))
      {
         *errCode = GrowlGNTPUnauthorizedErrorCode;
         *errDescription = NSLocalizedString(@"Incoming remote notifications and registrations have been disabled by the user", @"GNTP unauthorized packet error message");
         return NO;
      }
      
      if(!YES/*[preferences isSubscriptionAllowed]*/ && [action caseInsensitiveCompare:GrowlGNTPSubscribeMessageType] == NSOrderedSame) {
         *errCode = GrowlGNTPUnauthorizedErrorCode;
         *errDescription = NSLocalizedString(@"Incoming subscription requests have been disabled by the user", @"GNTP unathorized packet error message");
         return NO;
      }
   }
   
   //There are a number of cases in which a password isn't required, some are optional
   BOOL passwordRequired = YES;
//   BOOL isResponseType = ([action caseInsensitiveCompare:GrowlGNTPErrorResponseType] == NSOrderedSame || 
//                          [action caseInsensitiveCompare:GrowlGNTPOKResponseType] == NSOrderedSame ||
//                          [action caseInsensitiveCompare:GrowlGNTPCallbackTypeHeader] == NSOrderedSame);
   
   if([conHost isLocalHost] && [key hashAlgorithm] == GNTPNoHash && [key encryptionAlgorithm] == GNTPNone)
      return YES;
   
   //This is mainly for future reference, responses are supposed to have security by spec, but it isn't implemented in GfW or Growl.app
//   if(!NO/*[[GrowlPreferencesController sharedController] boolForKey:@"RequireSecureGNTPResponses"]*/ && isResponseType){
//      passwordRequired = NO;
//   }
   
   //New setting to allow no encryption when password is empty
   NSString *remotePassword = @"TESTING"/*[preferences remotePassword]*/;
   if(!NO/*[preferences boolForKey:@"RequireGNTPSecurityWhenPasswordEmpty"]*/) {
      if(!remotePassword || [remotePassword isEqualToString:@""])
         passwordRequired = NO;
   }
   
   //Despite all the above, if we have an encryption algorithm, we require a password setup to decrypt
   if([key encryptionAlgorithm] != GNTPNone)
      passwordRequired = YES;
   
   //If we dont have a hash algorithm, and we require password, we dont have what we need
   if([key hashAlgorithm] == GNTPNoHash && passwordRequired)
      return NO;
   
   //We dont need a password, we dont have a hash algorithm, and we dont have encryption
   if(!passwordRequired && [key hashAlgorithm] == GNTPNoHash)
      return YES;
   
   //At this point, we know we need a password, for decryption, or just authorization
//   if(isResponseType){
//      //check hash against the origin packet, regardless of subscription or not, this should be valid
//		/*      if ([HexEncode([[[self originPacket] key] keyHash]) caseInsensitiveCompare:HexEncode([key keyHash])] == NSOrderedSame)*/
//		return YES;
//   }else{
      //Try our remote password
		if([GNTPPacket isValidKey:key
						  forPassword:remotePassword])
			return YES;
		
		//If we've gotten here, we are going to assume its a subscription passworded REGISTER or SUBSCRIBE
		NSString *subscriptionPassword = @"SUBSCRIPTION"/*[[GNTPSubscriptionController sharedController] passwordForLocalSubscriber:conHost]*/;
		if(subscriptionPassword &&
			![subscriptionPassword isEqualToString:@""] &&
			[GNTPPacket isValidKey:key
						  forPassword:subscriptionPassword]) {
				return YES;
			}
//   }
   
   return NO;
}

+(GNTPKey*)keyForSecurityHeaders:(NSArray*)headers 
							  errorCode:(GrowlGNTPErrorCode*)errCode
							description:(NSString**)errDescription
{
	GNTPKey *key = [[[GNTPKey alloc] init] autorelease];
	
	NSArray *encryptionSubstrings = [[headers objectAtIndex:2] componentsSeparatedByString:@":"];
	NSString *packetEncryptionAlgorithm = [[encryptionSubstrings objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	GrowlGNTPEncryptionAlgorithm algorithm = [GNTPKey encryptionAlgorithmFromString:packetEncryptionAlgorithm];
	[key setEncryptionAlgorithm:algorithm]; //this should be None if there is only one item
	if([GNTPKey isSupportedEncryptionAlgorithm:packetEncryptionAlgorithm])
	{
		if([encryptionSubstrings count] == 2)
			[key setIV:HexUnencode([encryptionSubstrings objectAtIndex:1])];
		else {
			if ([key encryptionAlgorithm] != GNTPNone) {
				*errCode = GrowlGNTPUnauthorizedErrorCode;
				*errDescription = NSLocalizedString(@"Missing initialization vector for encryption", /*comment*/ @"GNTP packet parsing error");
				key = nil;
			}
		}
	}else{
		*errCode = GrowlGNTPUnauthorizedErrorCode;
		*errDescription = [NSString stringWithFormat:NSLocalizedString(@"Unsupported encryption type, %@", @"GNTP packet with an unsupported encryption algorithm"), packetEncryptionAlgorithm];
		key = nil;
	}
	
	if(!errDescription && errCode == 0 && key != nil)
	{
		BOOL hashStringError = NO;
		if([headers count] == 4)
		{
			NSString *item4 = [[headers objectAtIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if([item4 caseInsensitiveCompare:@""] == NSOrderedSame){
				NSLog(@"Empty item 4, possibly a flaw in the GNTP sender, ignoring");
			} else {
				NSArray *keySubstrings = [item4 componentsSeparatedByString:@":"];
				NSString *keyHashAlgorithm = [keySubstrings objectAtIndex:0];
				if([GNTPKey isSupportedHashAlgorithm:keyHashAlgorithm]) {
					[key setHashAlgorithm:[GNTPKey hashingAlgorithmFromString:keyHashAlgorithm]];
					if([keySubstrings count] == 2) {
						NSArray *keyHashStrings = [[keySubstrings objectAtIndex:1] componentsSeparatedByString:@"."];
						if([keyHashStrings count] == 2) {
							[key setKeyHash:HexUnencode([keyHashStrings objectAtIndex:0])];
							[key setSalt:HexUnencode([[keyHashStrings objectAtIndex:1] substringWithRange:NSMakeRange(0, [[keyHashStrings objectAtIndex:1] length])])];
							//we will do actual check of all this in isAuthorizedPacket
						}
						else 
							hashStringError = YES;
					}
					else
						hashStringError = YES;
				}
				else
					hashStringError = YES;
			}
		}
		
		
		if(hashStringError)
		{
			if(!errDescription && errCode == 0)
			{
				NSLog(@"There was a missing <hashalgorithm>:<keyHash>.<keySalt> with encryption or remote, set error and return appropriately");
				*errCode = GrowlGNTPUnauthorizedErrorCode;
				*errDescription = NSLocalizedString(@"Missing, malformed, or invalid key hash string", @"GNTP packet parsing error");
				key = nil;
			}
		}
	}
	return key;
}

-(id)init {
	if((self = [super init])){
		_gntpDictionary = [[NSMutableDictionary alloc] init];
		_growlDictionary = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(void)dealloc {
	self.gntpDictionary = nil;
	self.growlDictionary = nil;
	[super dealloc];
}

-(BOOL)validate {
	return YES;
}

-(void)parseDataBlock:(NSData *)data {
	
}

@end
