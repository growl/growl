#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>

NSString * const TCPServerErrorDomain;

typedef enum {
    kTCPServerCouldNotBindToIPv4Address = 1,
    kTCPServerCouldNotBindToIPv6Address = 2,
    kTCPServerNoSocketsAvailable = 3,
} TCPServerErrorCode;

@class GCDAsyncSocket;

@protocol GrowlTCPServerDelegate
- (void)didAcceptNewSocket:(GCDAsyncSocket *)sock;
@end

@interface GrowlTCPServer : NSObject {
@private
    id <GrowlTCPServerDelegate> delegate;
    NSString *domain;
    NSString *name;
    NSString *type;
    uint16_t port;
    NSNetService *netService;
   
   BOOL running;
   BOOL remoteRunning;
	
	GCDAsyncSocket *asyncSocket;
   GCDAsyncSocket *remoteSocket;
}

- (id <GrowlTCPServerDelegate>)delegate;
- (void)setDelegate:(id <GrowlTCPServerDelegate>)value;

- (NSString *)domain;
- (void)setDomain:(NSString *)value;

- (NSString *)name;
- (void)setName:(NSString *)value;

- (NSString *)type;
- (void)setType:(NSString *)value;

- (uint16_t)port;
- (void)setPort:(uint16_t)value;

- (NSNetService *)netService;

- (void)publish;
- (void)unpublish;

- (BOOL)start:(NSError **)error;
- (BOOL)stop;

-(void)preferencesChanged:(NSNotification*)note;

@end
