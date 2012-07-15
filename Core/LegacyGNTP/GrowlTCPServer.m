#import "GrowlTCPServer.h"
#import "GCDAsyncSocket.h"
#import "NSStringAdditions.h"
#import "GrowlNetworkUtilities.h"
#import "GrowlPreferencesController.h"

/*!
 * @class GrowlTCPServer
 * @brief Class to manage establishing a listening socket and advertising it
 */
@implementation GrowlTCPServer

- (id)init {
   if((self = [super init])){
      [[NSNotificationCenter defaultCenter] addObserver:self 
                                               selector:@selector(preferencesChanged:) 
                                                   name:GrowlPreferencesChanged 
                                                 object:nil];
      running = NO;
   }
   return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stop];
    [domain release];
    [name release];
    [type release];
    [super dealloc];
}

- (id <GrowlTCPServerDelegate>)delegate {
    return delegate;
}

- (void)setDelegate:(id <GrowlTCPServerDelegate>)value {
    delegate = value;
}

- (NSString *)domain {
    return domain;
}

- (void)setDomain:(NSString *)value {
    if (domain != value) {
        [domain release];
        domain = [value copy];
    }
}

- (NSString *)name {
    return name;
}

- (void)setName:(NSString *)value {
    if (name != value) {
        [name release];
        name = [value copy];
    }
}

- (NSString *)type {
    return type;
}

- (void)setType:(NSString *)value {
    if (type != value) {
        [type release];
        type = [value copy];
    }
}

- (uint16_t)port {
    return port;
}

- (void)setPort:(uint16_t)value {
    port = value;
}

- (NSNetService *)netService {
	return netService;
}

- (void)publish
{
   // we can only publish the service if we have a type to publish with
   if (type && running && !netService && [[GrowlPreferencesController sharedController] isGrowlServerEnabled]) {
   NSLog(@"publishing");
      NSString *publishingDomain = domain ? domain : @"";
      NSString *publishingName = nil;
      if (name) {
         publishingName = name;
      } else {
         NSString * thisHostName = [GrowlNetworkUtilities localHostName];
         if ([thisHostName hasSuffix:@".local"]) {
            publishingName = [thisHostName substringToIndex:([thisHostName length] - 6)];
         }else
            publishingName = thisHostName;
      }
      
      netService = [[NSNetService alloc] initWithDomain:publishingDomain type:type name:publishingName port:port];
      NSDictionary * txtRecordDataDictionary = [NSDictionary dictionaryWithObjectsAndKeys: @"1.0", @"version", @"mac", @"platform", nil];
      [netService setTXTRecordData:[NSNetService dataFromTXTRecordDictionary:txtRecordDataDictionary]];
      [netService publish];
   }
}

- (void)unpublish
{
   NSLog(@"unpublishing");
   [netService stop];
   [netService release];
   netService = nil;
}

- (BOOL)start:(NSError **)error {
   if(running)
      return YES;
   
	BOOL success;

	asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self 
														  delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
	success = [asyncSocket acceptOnInterface:@"localhost" port:port error:(error ? error : NULL)];
	NSLog(@"%@ now accepting (%@)", asyncSocket, (error ? *error : NULL));
    if (port == 0) {
        /* Now that the binding was successful, we get the port number if we let
		 * the kernel determine it.
		 */
		port = [asyncSocket localPort];
	}
   
   running = YES;
   
   return success;
}

- (BOOL)stop {
   if(!running)
      return YES;
   
	NSLog(@"Stop %@", asyncSocket);
	
	[asyncSocket disconnect];
	[asyncSocket release]; asyncSocket = nil;
   running = NO;
    
	return YES;
}

#pragma mark -

-(BOOL)startRemoteServer:(NSError**)error {
   BOOL success = YES;
   if(remoteRunning)
      return success;
   
   remoteSocket = [[GCDAsyncSocket alloc] initWithDelegate:self 
															delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
   success = [remoteSocket acceptOnPort:port error:(error ? error : NULL)];
   NSLog(@"%@ now accepting (%@)", remoteSocket, (error ? *error : NULL));
   if (port == 0) {
      /* Now that the binding was successful, we get the port number if we let
       * the kernel determine it.
       */
      port = [remoteSocket localPort];
   }
   if(success){
      [self publish];
      remoteRunning = YES;
   }
   return success;
}

-(BOOL)stopRemoteServer {
   if(!remoteRunning)
      return YES;
   
   GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
   if([preferences isGrowlServerEnabled] || [preferences isSubscriptionAllowed])
      return NO;
   
   [self unpublish];
   NSLog(@"Stop %@", remoteSocket);
	
	[remoteSocket disconnect];
	[remoteSocket release]; remoteSocket = nil;
   remoteRunning = NO;
   
	return YES;
}

-(void)preferencesChanged:(NSNotification*)note
{
   if(![note object] || [[note object] isEqualToString:GrowlStartServerKey] ||
      [[note object] isEqualToString:GrowlSubscriptionEnabledKey])
   {
      if([[GrowlPreferencesController sharedController] isGrowlServerEnabled] ||
         [[GrowlPreferencesController sharedController] isSubscriptionAllowed])
      {
         NSError *error = nil;
         if(![self startRemoteServer:&error]){
            NSLog(@"Error starting remote server");
         }
      }else{
         [self stopRemoteServer];
      }
   }
}

/*!
 * @brief Our listening socket accepted a new socket. Pass it to our delegate (GrowlTCPPathway) for handling
 *
 * This is the only place GrowlTCPServer interacts with the incoming socket; GrowlTCPPathway will take it from here.
 */
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
   if ([[newSocket connectedHost] isLocalHost] ||
       [[GrowlPreferencesController sharedController] isGrowlServerEnabled] ||
       [[GrowlPreferencesController sharedController] isSubscriptionAllowed]) 
   {
      //NSLog (@"Socket %@ accepting connection %@.", sock, newSocket);
      [[self delegate] didAcceptNewSocket:newSocket];
	} else {
		[newSocket disconnect];
	}
}

@end

