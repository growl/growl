#import "GrowlProwlGenerator.h"
#import "PRServerError.h"

@interface GrowlProwlGenerator()
@property (nonatomic, copy, readwrite) NSString *providerKey;
@property (nonatomic, assign, readwrite) id<GrowlProwlGeneratorDelegate> delegate;
@property (nonatomic, copy, readwrite) NSString *token;
@property (nonatomic, copy, readwrite) NSString *tokenURL;
@property (nonatomic, retain, readwrite) PRAPIKey *apiKey;
@end

@implementation GrowlProwlGenerator
@synthesize providerKey = _providerKey;
@synthesize delegate = _delegate;
@synthesize token = _token;
@synthesize tokenURL = _tokenURL;
@synthesize apiKey = _apiKey;

- (id)initWithProviderKey:(NSString *)providerKey
				 delegate:(id<GrowlProwlGeneratorDelegate>)delegate
{
	self = [super init];
	if(self) {
		self.providerKey = providerKey;
		self.delegate = delegate;
	}
	return self;
}

- (void)dealloc
{
    [_providerKey release];
	[_token release];
	[_tokenURL release];
	[_apiKey release];
    [super dealloc];
}

- (NSString *)encodedStringForString:(NSString *)string
{
	NSString *encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
																				  (CFStringRef)string, 
																				  NULL,
																				  (CFStringRef)@";/?:@&=+$",
																				  kCFStringEncodingUTF8);
	
	return [encodedString autorelease];
}

- (NSXMLElement *)retrieveElementFromData:(NSData *)data error:(NSError **)error
{
	NSXMLElement *retrieveElement = nil;
	NSError *xmlError = nil;
	NSXMLDocument *document = [[[NSXMLDocument alloc] initWithData:data options:0 error:&xmlError] autorelease];
	if(document) {
		NSArray *retrieveElements = [document.rootElement elementsForName:@"retrieve"];
		if(!retrieveElements.count) {
			if(error)
				*error = [NSError errorWithDomain:@"GrowlProwlGenerator" code:-1 userInfo:nil];
		} else {
			retrieveElement = retrieveElements.lastObject;
		}
	} else {
		if(error)
			*error = xmlError;
	}
	return retrieveElement;
}

- (void)fetchToken
{
	NSMutableString *fetchURLString = [NSMutableString stringWithString:@"https://api.prowlapp.com/publicapi/retrieve/token"];
	[fetchURLString appendFormat:@"?providerkey=%@", [self encodedStringForString:self.providerKey]];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fetchURLString]
														   cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
													   timeoutInterval:300.0f];
	
	request.HTTPMethod = @"GET";
	
	[NSURLConnection sendAsynchronousRequest:request
									   queue:[NSOperationQueue mainQueue]
						   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
							   if(!data) {
								   [self.delegate generator:self didFailWithError:error];
								   return;
							   }
							   
							   NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
							   
							   NSLog(@"Got back XML: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
							   
							   if(statusCode == 200) {
								   NSXMLElement *retrieveElement = [self retrieveElementFromData:data error:&error];
								   if(retrieveElement) {
									   NSXMLNode *tokenNode = [retrieveElement attributeForName:@"token"];
									   NSXMLNode *urlNode = [retrieveElement attributeForName:@"url"];
									   
									   self.token = tokenNode.stringValue;
									   [self.delegate generator:self didFetchTokenURL:urlNode.stringValue];
								   } else {
									   [self.delegate generator:self didFailWithError:error];
								   }
							   } else {
								   [self.delegate generator:self didFailWithError:[PRServerError serverErrorWithStatusCode:statusCode]];
							   }
						   }];
}

- (void)fetchApiKey
{
	NSMutableString *fetchURLString = [NSMutableString stringWithString:@"https://api.prowlapp.com/publicapi/retrieve/apikey"];
	[fetchURLString appendFormat:@"?providerkey=%@", [self encodedStringForString:self.providerKey]];
	[fetchURLString appendFormat:@"&token=%@", [self encodedStringForString:self.token]];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fetchURLString]
														   cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
													   timeoutInterval:300.0f];
	
	request.HTTPMethod = @"GET";
	
	[NSURLConnection sendAsynchronousRequest:request
									   queue:[NSOperationQueue mainQueue]
						   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
							   if(!data) {
								   [self.delegate generator:self didFailWithError:error];
								   return;
							   }
							   
							   NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
							   
							   NSLog(@"Got back XML: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
							   
							   if(statusCode == 200) {
								   NSXMLElement *retrieveElement = [self retrieveElementFromData:data error:&error];
								   if(retrieveElement) {
									   NSXMLNode *apikeyNode = [retrieveElement attributeForName:@"apikey"];
									   
									   self.apiKey = [[[PRAPIKey alloc] init] autorelease];
									   self.apiKey.enabled = YES;
									   self.apiKey.apiKey = apikeyNode.stringValue;
									   self.apiKey.validated = YES; // after so the change doesn't reset it
									   
									   [self.delegate generator:self didFetchApiKey:self.apiKey];
								   } else {
									   [self.delegate generator:self didFailWithError:error];
								   }
							   } else {
								   [self.delegate generator:self didFailWithError:[PRServerError serverErrorWithStatusCode:statusCode]];
							   }
						   }];
}

@end
