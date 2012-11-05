//
//  GrowlWebSocketProxy.m
//  Growl
//
//  Created by Daniel Siemer on 11/4/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlWebSocketProxy.h"
#import "GCDAsyncSocket.h"
#import "GNTPUtilities.h"
#import "GNTPPacket.h"

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

#define MAX_WEBSOCKET_BUFFER_SIZE 5242880 //5 MB, maybe too large

#define PARSE_HTTP_TAG 100
#define FRAME_START_TAG 101
#define LENGTH_READ_TAG 102
#define MASK_READ_TAG 103
#define DATA_READ_TAG 104

#define FIN_BYTE_MORE 0x00
#define FIN_BYTE_FINAL 0x80
#define OPCODE_BYTE_CONTINUATION 0x00
#define OPCODE_BYTE_TEXT 0x01
#define OPCODE_BYTE_BINARY 0x02
#define OPCODE_BYTE_CLOSE 0x08
#define OPCODE_BYTE_PING 0x09
#define OPCODE_BYTE_PONG 0x0A
#define MASK_BYTE_NO 0x00
#define MASK_BYTE_YES 0x80
#define LENGTH_BYTE_7 0x7D
#define LENGTH_BYTE_16 0x7E
#define LENGTH_BYTE_64 0x7F

@interface NSData (GrowlWebSocketUtilities)

-(NSData*)sha1Hashed;
-(NSString*)encodedAsBase64;

@end

@implementation NSData (GrowlWebSocketUtilities)

-(NSData*)sha1Hashed {
	NSData *result = nil;
	NSUInteger length = [self length];
	unsigned char *bytes = (unsigned char *)[self bytes];
	unsigned char *value = (unsigned char*)calloc(CC_SHA1_DIGEST_LENGTH, sizeof(unsigned char));
	if(value)
		CC_SHA1(bytes, (unsigned int)length, value);
	result = [NSData dataWithBytesNoCopy:value length:CC_SHA1_DIGEST_LENGTH freeWhenDone:YES];
	return result;
}
-(NSString*)encodedAsBase64 {
	static const char base64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	if ([self length] == 0)
		return @"";
	
	char *characters = (char*)malloc((([self length] + 2) / 3) * 4);
	if (characters == NULL)
		return nil;
	NSUInteger length = 0;
	
	NSUInteger i = 0;
	while (i < [self length])
	{
		char buffer[3] = {0,0,0};
		short bufferLength = 0;
		while (bufferLength < 3 && i < [self length])
			buffer[bufferLength++] = ((char *)[self bytes])[i++];
		
		//  Encode the bytes in the buffer to four characters, including padding "=" characters if necessary.
		characters[length++] = base64EncodingTable[(buffer[0] & 0xFC) >> 2];
		characters[length++] = base64EncodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
		if (bufferLength > 1)
			characters[length++] = base64EncodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
		else characters[length++] = '=';
		if (bufferLength > 2)
			characters[length++] = base64EncodingTable[buffer[2] & 0x3F];
		else characters[length++] = '=';
	}
	
	return [[[NSString alloc] initWithBytesNoCopy:characters
														length:length
													 encoding:NSASCIIStringEncoding
												freeWhenDone:YES] autorelease];
}

@end

@interface GrowlWebSocketRead : NSObject

@property (nonatomic, retain) NSData *readToData;
@property (nonatomic, assign) NSUInteger readToLength;
@property (nonatomic, assign) long tag;

@end

@implementation GrowlWebSocketRead

-(void)dealloc {
	[_readToData release];
	_readToData = nil;
	[super dealloc];
}

@end

@interface GrowlWebSocketProxy ()

@property (nonatomic, retain) NSDictionary *startHeaders;
@property (nonatomic, retain) NSMutableArray *scheduledReads;
@property (nonatomic, retain) NSMutableData *dataBuffer;

@property (nonatomic, assign) BOOL masked;
@property (nonatomic, assign) NSInteger remainingPayload;
@property (nonatomic, retain) NSData *mask;

@end

@implementation GrowlWebSocketProxy
static dispatch_queue_t bufferQueue = NULL;

+(void)initialize {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		bufferQueue = dispatch_queue_create("com.Growl.GrowlHelperApp.WebSocket.BufferQueue", DISPATCH_QUEUE_SERIAL);
	});
}

- (id)initWithSocket:(GCDAsyncSocket*)socket {
	if((self = [super init])){
		self.socket = socket;
		self.delegate = [socket delegate];
		[self.socket synchronouslySetDelegate:self];
		
		self.scheduledReads = [NSMutableArray array];
		self.dataBuffer = [NSMutableData data];
		_remainingPayload = 0;
		_masked = NO;
		
		//Go ahead and set up our next read now directly
		[self.socket readDataToData:[GNTPUtilities doubleCRLF]
							 withTimeout:5.0
										tag:PARSE_HTTP_TAG];
	}
	return self;
}

- (void)dealloc {
	[_socket synchronouslySetDelegate:nil];
	[_socket disconnect];
	[_socket release];
	_socket = nil;
	_delegate = nil;
	[_mask release];
	_mask = nil;
	[_startHeaders release];
	_startHeaders = nil;
	[_scheduledReads release];
	_scheduledReads = nil;
	[_dataBuffer release];
	_dataBuffer = nil;
	[super dealloc];
}

-(void)maybeDequeueRead {
	__block GrowlWebSocketProxy *blockSelf = self;
	__block NSArray *reads = nil;
	reads = [[[blockSelf scheduledReads] copy] autorelease];
	[reads enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if([obj isKindOfClass:[GrowlWebSocketRead class]]){
			NSData *readData = nil;
			if([obj readToLength] > 0){
				if([[blockSelf dataBuffer] length] > [obj readToLength]){
					NSRange byteRange = NSMakeRange(0, [obj readToLength]);
					readData = [[blockSelf dataBuffer] subdataWithRange:byteRange];
					[[blockSelf dataBuffer] replaceBytesInRange:byteRange withBytes:NULL length:0];
				}else
					*stop = YES;
			}else {
				NSRange findRange = [[blockSelf dataBuffer] rangeOfData:[obj readToData] options:0 range:NSMakeRange(0, [[blockSelf dataBuffer] length])];
				if(findRange.location != NSNotFound){
					NSRange byteRange = NSMakeRange(0, findRange.location + findRange.length);
					readData = [[blockSelf dataBuffer] subdataWithRange:byteRange];
					[[blockSelf dataBuffer] replaceBytesInRange:byteRange withBytes:NULL length:0];
				}else
					*stop = YES;
			}
			if(readData){
				[[blockSelf scheduledReads] removeObject:obj];
				//NSLog(@"Passing read data to delegate:\n%@", [[[NSString alloc] initWithData:readData encoding:NSUTF8StringEncoding] autorelease]);
				if([[blockSelf delegate] respondsToSelector:@selector(socket:didReadData:withTag:)]){
					[[blockSelf delegate] socket:(GCDAsyncSocket*)blockSelf didReadData:readData withTag:[obj tag]];
				}
			}
		}
	}];
}

#pragma mark GCDAsyncSocket proxying methods

- (void)disconnect {
	[_socket disconnect];
}

- (NSString *)connectedHost {
	return [_socket connectedHost];
}
- (NSData *)connectedAddress {
	return [_socket connectedAddress];
}

- (id)userData {
	return [_socket userData];
}
- (void)setUserData:(id)userData {
	[_socket setUserData:userData];
}

- (void)readDataToData:(NSData *)data
				withLength:(NSUInteger)length
			  withTimeout:(NSTimeInterval)timeout
						 tag:(long)tag
{
	if(!data && length == 0){
		NSLog(@"Cannot read to length 0 data (null)");
		return;
	}
	//Build a read, queue it, then fire the dequeue check
	GrowlWebSocketRead *read = [[[GrowlWebSocketRead alloc] init] autorelease];
	[read setReadToData:data];
	[read setReadToLength:length];
	[read setTag:tag];
	
	dispatch_async(bufferQueue, ^{
		[self.scheduledReads addObject:read];
		[self maybeDequeueRead];
	});
}

- (void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag {
	[self readDataToData:nil withLength:length withTimeout:timeout tag:tag];
}
- (void)readDataToData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag {
	[self readDataToData:data withLength:0 withTimeout:timeout tag:tag];
}

- (void)writeData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag {
	//Frame data before sending it
	NSMutableData *buildData = [NSMutableData data];
	//Frame control
	char frameControl = FIN_BYTE_FINAL + OPCODE_BYTE_TEXT;
	[buildData appendBytes:&frameControl length:1];
	
	// Mask and length
	NSUInteger length = [data length];
	if (length > INT16_MAX) {
		char byteLength = LENGTH_BYTE_64;
		int64_t length64 = (int64_t)length;
		[buildData appendBytes:&byteLength length:1];
		[buildData appendBytes:&length64 length:8];
	}else if (length > (int)LENGTH_BYTE_7) {
		char byteLength = LENGTH_BYTE_16;
		int16_t length16 = (int16_t)length;
		[buildData appendBytes:&byteLength length:1];
		[buildData appendBytes:&length16 length:2];
	}else {
		int8_t length8 = (int8_t)length;
		[buildData appendBytes:&length8 length:1];
	}
	
	// actual GNTP bytes
	[buildData appendData:data];
	
	[self.socket writeData:buildData withTimeout:timeout tag:tag];
}

#pragma mark GCDAsyncSocket Delegate Methods

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	if(tag == PARSE_HTTP_TAG){
		//Parse the HTTP headers, build our response, and send it, or disconnect the socket if we dont conform to what it sends
		NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		//NSLog(@"read websocket headers:\n%@", string);
		NSMutableDictionary *headerDict = [NSMutableDictionary dictionary];
		[GNTPUtilities enumerateHeaders:string
									 withBlock:^BOOL(NSString *headerKey, NSString *headerValue) {
										 [headerDict setValue:headerValue forKey:headerKey];
										 return NO;
									 }];
		self.startHeaders = headerDict;
		NSInteger version = [[self.startHeaders valueForKey:@"Sec-WebSocket-Version"] integerValue];
		BOOL disconnect = NO;
		if(version == 13){
			//Start building our return string
			NSString *socketKey = [self.startHeaders valueForKey:@"Sec-WebSocket-Key"];
			NSString *combinedKey = [socketKey stringByAppendingString:@"258EAFA5-E914-47DA-95CA-C5AB0DC85B11"];
			NSData *hashedData = [[combinedKey dataUsingEncoding:NSUTF8StringEncoding] sha1Hashed]; //Hash this
			NSString *returnKeyEncoded = [hashedData encodedAsBase64];

			NSString *protocolList = [self.startHeaders valueForKey:@"Sec-WebSocket-Protocol"];
			__block BOOL found = NO;
			__block NSString *protocolToUse = nil;
			__block BOOL fallbackFound = NO;
			if(protocolList){
				NSArray *protocols = [protocolList componentsSeparatedByString:@", "];
				[protocols enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
					if([obj caseInsensitiveCompare:@"GNTP"] == NSOrderedSame){
						if(protocolToUse)
							[protocolToUse release];
						protocolToUse = [obj retain];
						found = YES;
						*stop = YES;
					}else if([obj caseInsensitiveCompare:@"chat"] == NSOrderedSame){
						fallbackFound = YES;
						protocolToUse = [obj retain];
					}
				}];
			}
			NSMutableString *responseString = [NSMutableString stringWithFormat:@"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Version: 13\r\nSec-WebSocket-Accept: %@\r\n", returnKeyEncoded];
			if(protocolToUse){
				[responseString appendFormat:@"Sec-WebSocket-Protocol: %@\r\n", protocolToUse];
				[protocolToUse release];
			}
			[responseString appendString:@"\r\n"];
			//NSLog(@"Writing reply:\n%@", responseString);
			[self.socket writeData:[responseString dataUsingEncoding:NSUTF8StringEncoding]
						  withTimeout:5.0
									 tag:100];
			
			//Regardless of scheduled reads from our owner the server, go ahead and start buffering frames
			[self.socket readDataToLength:2 withTimeout:5.0 tag:FRAME_START_TAG];
		}else{
			disconnect = YES;
		}
		
		if(disconnect)
			[self disconnect];
	}else{
		NSUInteger readLength = 0;
		long nextTag = 0;
		char *rawBytes = (char*)[data bytes];
		if(tag == FRAME_START_TAG){
			const char frameControl = rawBytes[0];
			const char dataControl = rawBytes[1];
			
			BOOL isFinal = (frameControl & FIN_BYTE_FINAL) == FIN_BYTE_FINAL;
			if(!isFinal){
				NSLog(@"they are fragmenting the message on us");
			}
			
			if ((frameControl & OPCODE_BYTE_PING) == OPCODE_BYTE_PING) {
				//TODO: send ping
			}else if ((frameControl & OPCODE_BYTE_CLOSE) == OPCODE_BYTE_CLOSE) {
				[self.socket disconnect];
			}
			
			_masked = (dataControl & MASK_BYTE_YES) == MASK_BYTE_YES;
			int8_t length = (int8_t)(dataControl & ~MASK_BYTE_YES);
			if ((dataControl & LENGTH_BYTE_16) == LENGTH_BYTE_16) {
				// read next two bytes for length
				readLength = 2;
				nextTag = LENGTH_READ_TAG;
			}else if ((dataControl & LENGTH_BYTE_64) == LENGTH_BYTE_64) {
				// read next 8 bytes for length
				readLength = 8;
				nextTag = LENGTH_READ_TAG;
			}else {
				if (_masked) {
					// read 4 byte masking key
					readLength = 4;
					nextTag = MASK_READ_TAG;
					_remainingPayload = length;
				}else {
					readLength = length;
					nextTag = DATA_READ_TAG;
					_remainingPayload = 0;
					
					// handle zero-length payload
					if (readLength == 0) {
						readLength = 2;
						nextTag = FRAME_START_TAG;
					}
				}
			}
		}else if (tag == LENGTH_READ_TAG) {
			NSUInteger length = 0;
			if ([data length] == 2) {
				uint16_t s;
				[data getBytes:&s length:[data length]];
				NTOHS(s);
				length = (NSUInteger)s;
			}else if ([data length] == 8) {
				uint64_t l;
				[data getBytes:&l length:[data length]];
/* see: http://stackoverflow.com/questions/809902/64-bit-ntohl-in-c/875505#875505 */
				union { unsigned long lv[2]; unsigned long long llv; } u;
				u.lv[0] = htonl(l >> 32);
				u.lv[1] = htonl(l & 0xFFFFFFFFULL);
				l = u.llv;
				length = (NSUInteger)l;
			}
			
			if (_masked) {
				// read 4 byte masking key
				readLength = 4;
				nextTag = MASK_READ_TAG;
				_remainingPayload = length;
			}else {
				if (length > INT_MAX) {
					readLength = INT_MAX;
					_remainingPayload = length - readLength;
				}else {
					readLength = length;
					_remainingPayload = 0;
				}
				nextTag = DATA_READ_TAG;
				
				// handle zero-length payload
				if (readLength == 0) {
					readLength = 2;
					nextTag = FRAME_START_TAG;
				}
			}
		}else if (tag == MASK_READ_TAG) {
			self.mask = data;
			
			if (_remainingPayload > INT_MAX) {
				readLength = INT_MAX;
				_remainingPayload -= readLength;
			}else {
				readLength = (NSUInteger)_remainingPayload;
				_remainingPayload = 0;
			}
			nextTag = DATA_READ_TAG;
			
			// handle zero-length payload
			if (readLength == 0) {
				readLength = 2;
				nextTag = FRAME_START_TAG;
			}
		}else if (tag == DATA_READ_TAG) {
			char *unmaskedBytes = NULL;
			if (_masked) {
				const char *mask = [self.mask bytes];
				unmaskedBytes = malloc([data length]);
				for(NSUInteger i = 0; i < [data length]; i++) {
					int b = i % 4;
					char unmaskedByte = (rawBytes[i] ^ mask[b]);
					unmaskedBytes[i] = unmaskedByte;
				}
			}else {
				unmaskedBytes = rawBytes;
			}
			NSData *unmaskedData = [NSData dataWithBytes:unmaskedBytes length:[data length]];
			//NSLog(@"Read message:\n%@", [[[NSString alloc] initWithBytes:unmaskedBytes length:[data length] encoding:NSUTF8StringEncoding] autorelease]);
			//Add to our main mutable data buffer
			dispatch_async(bufferQueue, ^{
				[self.dataBuffer appendData:unmaskedData];
				[self maybeDequeueRead];
			});
			
			readLength = 2;
			nextTag = FRAME_START_TAG;
		}else {
			//Bad joojoo
			[sock disconnect];
		}
		
		if(readLength > 0)
			[self.socket readDataToLength:readLength withTimeout:5.0 tag:nextTag];
	}
}
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
	[_delegate socket:sock didWriteDataWithTag:tag];
}
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock
shouldTimeoutReadWithTag:(long)tag
					  elapsed:(NSTimeInterval)elapsed
					bytesDone:(NSUInteger)length
{
	return [_delegate socket:sock shouldTimeoutReadWithTag:tag elapsed:elapsed bytesDone:length];
}
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock
shouldTimeoutWriteWithTag:(long)tag
					  elapsed:(NSTimeInterval)elapsed
					bytesDone:(NSUInteger)length
{
	return [_delegate socket:sock shouldTimeoutWriteWithTag:tag elapsed:elapsed bytesDone:length];
}
- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {
	//We might want to know about this
	//Check if the packet we have is finishable at its present point (ie, did we simply miss a binary block?)
}
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock
						withError:(NSError *)err
{
	[_delegate socketDidDisconnect:sock withError:err];
}

@end
