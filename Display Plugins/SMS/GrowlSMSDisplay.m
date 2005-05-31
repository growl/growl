//
//  GrowlSMSDisplay.m
//  Growl Display Plugins
//
//  Copyright 2005 Diggory Laycock All rights reserved.
//
#import "GrowlSMSDisplay.h"
#import "GrowlSMSPrefs.h"
#import <GrowlDefinesInternal.h>
#import <GrowlDisplayProtocol.h>
#import <Security/SecKeychain.h>
#import <Security/SecKeychainItem.h>


#define keychainServiceName "GrowlSMS"
#define keychainAccountName "SMSWebServicePassword"

#define accountNameKey			@"SMS - Account Name"
#define accountAPIIDKey			@"SMS - Account API ID"
#define destinationNumberKey	@"SMS - Destination Number"


@implementation GrowlSMSDisplay

- (id) init {
	if ((self = [super init])) {
		commandQueue = [[NSMutableArray alloc] init];
		xmlHoldingStringValue = [[NSMutableString alloc] init];
		waitingForResponse = NO;
		creditBalance = 0;		
	}
	return self;
}


- (void) dealloc {
	[commandQueue release];

	[prefPane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!prefPane) {
		prefPane = [[GrowlSMSPrefs alloc] initWithBundle:[NSBundle bundleForClass:[GrowlSMSPrefs class]]];
	}
	return prefPane;
}

- (void) displayNotificationWithInfo:(NSDictionary *)noteDict {
	
	NSString	*accountNameValue = nil;
	NSString	*apiIDValue = nil;
	NSString	*destinationNumberValue = nil;
	
	READ_GROWL_PREF_VALUE(destinationNumberKey, @"com.Growl.SMS", NSString *, &destinationNumberValue);
	READ_GROWL_PREF_VALUE(accountAPIIDKey, @"com.Growl.SMS", NSString *, &apiIDValue);
	READ_GROWL_PREF_VALUE(accountNameKey, @"com.Growl.SMS", NSString *, &accountNameValue);
	
	if (
		([destinationNumberValue length] == 0) ||
		([apiIDValue length] == 0) ||
		([accountNameValue length] == 0 ))
	{
		NSLog(@"Cannot send SMS - not enough details in preferences.");
		return;
	}
	
	NSString *title = [noteDict objectForKey:GROWL_NOTIFICATION_TITLE];
	NSString *desc = [noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION];

	
	//	Fetch the SMS password from the keychain:
	char *password;
	UInt32 passwordLength;
	OSStatus status;
	status = SecKeychainFindGenericPassword( NULL,
											 strlen(keychainServiceName), keychainServiceName,
											 strlen(keychainAccountName), keychainAccountName,
											 &passwordLength, (void **)&password, NULL );
	
	NSString *passwordString;
	if (status == noErr) {
		passwordString = [NSString stringWithUTF8String:password length:passwordLength];
		SecKeychainItemFreeContent(NULL, password);
	} else {
		if (status != errSecItemNotFound)
			NSLog(@"Failed to retrieve SMS Account password from keychain. Error: %d", status);
		passwordString = @"";
	}
	
	
	
	NSString *smsSendCommand = [NSString stringWithFormat: 
		@"<clickAPI><sendMsg><api_id>%@</api_id><user>%@</user><password>%@</password><to>+%@</to><text>(%@) %@</text><from>Growl</from></sendMsg></clickAPI>", 
		apiIDValue, 
		accountNameValue, 
		passwordString, 
		destinationNumberValue, 
		title, 
		desc ];
	
	NSLog(@"SMS Display...  %@" , smsSendCommand);
	[self sendXMLCommand: smsSendCommand];

	//	Check credit balance.
	NSString *checkBalanceCommand = [NSString stringWithFormat: 
		@"<clickAPI><getBalance><api_id>%@</api_id><user>%@</user><password>%@</password></getBalance></clickAPI>", 
		apiIDValue, 
		accountNameValue, 
		passwordString ];
	
	[self sendXMLCommand:checkBalanceCommand];
	
	[destinationNumberValue release];
	[accountAPIIDKey release];
	[accountNameKey release];
	

	
	id clickContext = [noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
	if (clickContext) {
		NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
			[noteDict objectForKey:@"ClickHandlerEnabled"], @"ClickHandlerEnabled",
			clickContext,                                   GROWL_KEY_CLICKED_CONTEXT,
			[noteDict objectForKey:GROWL_APP_PID],          GROWL_APP_PID,
			nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_TIMED_OUT
															object:[noteDict objectForKey:GROWL_APP_NAME]
														  userInfo:userInfo];
		[userInfo release];
	}

}



#pragma mark -
#pragma mark Accessors

- (NSData *) responseData
{
	return responseData;
}

- (void) setResponseData:(NSData *)newResponseData
{
	[newResponseData retain];
	[responseData release];
	responseData = newResponseData;
	
	NSLog(@"we set the responseData:  %@", responseData);
}


#pragma mark -
#pragma mark Instance Methods


/*
 <clickAPI> 
	 <sendMsg> 
		 <api_id>your_api_id</api_id> 
		 <user>your_user_name</user> 
		 <password>your_pass</password> 			
		 <to>+12343455667</to> 
		 <text>Test text message.</text> 
		 <from>Growl</from> 
	 </sendMsg>
 </clickAPI> 

 
 API URL:
 ==========
 https://api.clickatell.com/xml/xml
 <input name="data" type="text" value="<clickAPI>$your_xml_data</clickAPI>">  
 
 //	To do - use the unicode option - when needed - although, it halves the length of SMS we can send.
 
 */


 - (void) sendXMLCommand: (NSString*) commandString
{
	NSData					*postData = [[NSString stringWithFormat: @"data=%@", commandString] dataUsingEncoding: NSUTF8StringEncoding];
	NSURL					*clickatelURL = [NSURL URLWithString:@"https://api.clickatell.com/xml/xml"]; 
	NSMutableURLRequest		*post = [NSMutableURLRequest requestWithURL: clickatelURL]; 
	
	[post addValue: [NSString  stringWithFormat: @"%u" , [postData length]] forHTTPHeaderField: @"Content-Length"]; 
	[post setHTTPMethod: @"POST"]; 
	[post setHTTPBody: postData];
	NSLog(@"Sending data: %@", postData);
	
	[commandQueue addObject: post];
	[self processQueue];
	
}


 - (void) processQueue
{
	NSLog(@"Processing HTTP Command Queue");
	if ([commandQueue count] == 0) {
		NSLog(@"Queue is empty...");
		return;	
	}
	
	if (!waitingForResponse) {
		waitingForResponse = YES;
		NSLog(@"Beginning Command Request Connection...");
		[NSURLConnection connectionWithRequest: [commandQueue objectAtIndex: 0] delegate: self];
	} else {
		NSLog(@"Can't process queue  - we are waiting on an existing command's resonse..");
	}
}


 - (void) connectionDidRespond
{
	NSLog(@"Request/Response transaction complete...");
	waitingForResponse = NO;
	[commandQueue removeObjectAtIndex: 0];
	[self processQueue];
}

 - (void) handleResponse
{
	bool success;
	if (responseParser) 
		[responseParser release];
	responseParser = [[NSXMLParser alloc] initWithData: [self responseData]];
	[responseParser setDelegate:self];
	[responseParser setShouldResolveExternalEntities:YES];
	success = [responseParser parse]; // return value not used
									  // if not successful, delegate is informed of error}
}



#pragma mark -
#pragma mark NSXMLParser Delegate methods:

 - (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	
    if ( [elementName isEqualToString:@"clickAPI"]) {
//		NSLog(@"Found the clickAPI element in the repsonse.  That means we got the HTTP part right.");
        return;
    }
	if ( [elementName isEqualToString:@"xmlErrorResp"] ) {
		NSLog(@"Oh Noes! we got an error back from clickatell - we passed them a bad XML request...");
		return;
	}
	
	if ( [elementName isEqualToString:@"fault"] ) {
		NSLog(@"Here comes the fault:...");
		return;
	}
	
	if ( [elementName isEqualToString:@"getBalanceResp"] ) {
//		NSLog(@"Here comes the Balance response:...");
		inBalanceResponseElement = YES;
		return;
	}
	
	
	if ( [elementName isEqualToString:@"ok"] ) {
//		NSLog(@"Command Success."); 
		if (inBalanceResponseElement) {
//			NSLog(@"Here comes the Balance value:...");			
		}
		return;
	}
	
	if ( [elementName isEqualToString:@"sendMsgResp"] ) {
//		NSLog(@"Here comes the Message Send response:...");
		inMessageSendResponseElement = YES;
		return;
	}
	
}


 - (void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (xmlHoldingStringValue == nil) {
        xmlHoldingStringValue = [[NSMutableString alloc] initWithCapacity:50];
    }
    [xmlHoldingStringValue appendString:string];
}




 - (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {

    if (	( [elementName isEqualToString:@"clickAPI"]		)	||
			( [elementName isEqualToString:@"xmlErrorResp"] )	) return;
	
	if ( [elementName isEqualToString:@"getBalanceResp"] ) {
		inBalanceResponseElement = NO;
	}
	if ( [elementName isEqualToString:@"sendMsgResp"] ) {
		inMessageSendResponseElement = NO;
	}
	
	
    if ( [elementName isEqualToString:@"fault"] ) {
		NSLog(@"The fault was: %@" , [xmlHoldingStringValue stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] );
		[xmlHoldingStringValue release];
		xmlHoldingStringValue = nil;
        return;
    }
	
	if ( [elementName isEqualToString:@"ok"] ) {
		if (inBalanceResponseElement) {
			creditBalance = [[xmlHoldingStringValue stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] floatValue];
			NSLog(@"Your Balance is: %4.1f 'credits'" , creditBalance);	
			[xmlHoldingStringValue release];
			xmlHoldingStringValue = nil;
		}
        return;
    }
	
	if ( [elementName isEqualToString:@"apiMsgId"] ) {
		if (inMessageSendResponseElement) {
			NSLog(@"SMS Message Sent (messageId: %@)" , [xmlHoldingStringValue stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]);
			[xmlHoldingStringValue release];
			xmlHoldingStringValue = nil;
		}
        return;
    }
	
    [xmlHoldingStringValue release];
    xmlHoldingStringValue = nil;
}




 - (void) parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	
	NSLog(@"Error Parsing XML response from SMS Gateway - %i, Description: %@, Line: %i, Column: %i",	[parseError code], 
		  [[parser parserError] localizedDescription], 
		  [parser lineNumber],
		  [parser columnNumber]);
}



#pragma mark -
#pragma mark NSURLConnection Delegate methods:


/*
	The delegate receives this message if connection has cancelled the authentication challenge specified by challenge.
 */
 - (void) connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	NSLog(@"didCancelAuthenticationChallenge:");
	[self connectionDidRespond];
}


/*
	The delegate receives this message if connection has failed to load the request successfully. The details of the failure are specified in error.
	Once the delegate receives this message, it will receive no further messages for connection.
 */
 - (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"Connection to SMS Web API failed: (%@)" ,[error localizedDescription]);
	
	[self connectionDidRespond];
}



/*	
The delegate receives this message when connection must authenticate challenge in order to download the request. This method gives the delegate the opportunity to determine the course of action taken for the challenge: provide credentials, continue without providing credentials or cancel the authentication challenge and the download.
 The delegate can determine the number of previous authentication challenges by sending the message previousFailureCount to challenge.
 
 If the previous failure count is 0 and the value returned by proposedCredential is nil, the delegate can create a new NSURLCredential object, providing a user name and password, and send a useCredential:forAuthenticationChallenge: message to [challenge sender], passing the credential and challenge as parameters. If proposedCredential is not nil, the value is a credential from the URL or the shared credential storage that can be provided to the user as feedback.
 The delegate may decide to abandon further attempts at authentication at any time by sending [challenge sender] a continueWithoutCredentialForAuthenticationChallenge: or a cancelAuthenticationChallenge: message. The specific action will be implementation dependent.
 
 If the delegate implements this method, the download will suspend until [challenge sender] is sent one of the following messages: useCredential:forAuthenticationChallenge:, continueWithoutCredentialForAuthenticationChallenge: or cancelAuthenticationChallenge:.
 If the delegate does not implement this method the default implementation is used. If a valid credential for the request is provided as part of the URL, or is available from the NSURLCredentialStorage the [challenge sender] is sent a useCredential:forAuthenticationChallenge: with the credential. If the challenge has no credential or the credentials fail to authorize access, then continueWithoutCredentialForAuthenticationChallenge: is sent to [challenge sender] instead.
 
 See Also: – cancelAuthenticationChallenge:, – continueWithoutCredentialForAuthenticationChallenge:, – useCredential:forAuthenticationChallenge:
 */
 - (void) connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	NSLog(@"didReceiveAuthenticationChallenge: %@" ,challenge);
	//	It doesn't need web auth currently - so we're not going to handle this case. 
	[connection cancel];
	//	[self connectionDidRespond];
}


/*
	The delegate receives this message as connection loads data incrementally. The delegate should concatenate the contents of each data object delivered to build up the complete data for a URL load.
	This method provides the only way for an asynchronous delegate to retrieve the loaded data. It is the responsibility of the delegate to retain or copy this data as it is delivered.
 */
 - (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	//	NSLog(@"didReceiveData:  %@", data);
	[self setResponseData: data];
	[self handleResponse];
}


/*
	The delegate receives this message when the URL loading system has received sufficient load data for connection to construct the NSURLResponse object, response. 
 The response is immutable and will not be modified by the URL loading system once it is presented to the delegate.
 
 In rare cases, for example in the case of a HTTP load where the content type of the load data is multipart/x-mixed-replace, the delegate will receive more than one connection:didReceiveResponse: message. 
 In the event this occurs, delegates should discard all data previously delivered by connection:didReceiveData:, and should be prepared to handle the, potentially different, MIME type reported by the NSURLResponse.
 
 Note that the only case where this message is not sent to the delegate is when the protocol implementation encounters an error before a response could be created.
 
 */

 - (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
//	NSLog(@"didReceiveResponse:  URL(%@) expectedDataLength:(%d)", [response URL], [response expectedContentLength]  );
	
	//	NSLog(@" MIME:(%@)" , [response MIMEType]);
	//	NSLog(@" textEncoding:(%@)" , [response textEncodingName]);
	
}


 - (NSCachedURLResponse *) connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	//	No Caching please...  Since we're using HTTPS none should occur - but no harm in being cautious.
	return nil;
}


/*
 
 The delegate receives this message when connection determines that it must change URLs in order to continue loading a request. 
 The delegate should inspect the redirected request specified by request and copy and modify request as necessary to change its attributes, or return request unmodified. 
 The NSURLResponse that caused the redirect is specified by redirectResponse. 
 The redirectResponse will be nil in cases where this method is not being sent as a result of involving the delegate in redirect processing.
 If the delegate wishes to cancel the redirect, it should call the connection object’s cancel method. 
 Alternatively, the delegate method can return nil to cancel the redirect, and the connection will continue to process. 
 This has special relevance in the case where redirectResponse is not nil. 
 In this case, any data that is loaded for the connection will be sent to the delegate, and the delegate will receive a connectionDidFinishLoading or connection:didFailLoadingWithError: message, as appropriate.
 
 The delegate can receive this message as a result of transforming a request’s URL to its canonical form, or for protocol-specific reasons, such as an HTTP redirect. 
 The delegate implementation should be prepared to receive this message multiple times.
 
 */	

 - (NSURLRequest *) connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
	NSLog(@"redirectResponse:");	
	[connection cancel];
	return nil;
}


// This delegate method is called when connection has finished loading successfully. The delegate will receive no further messages for connection.
 - (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSLog(@"connectionDidFinishLoading:");
	[self connectionDidRespond];
	
}


@end
