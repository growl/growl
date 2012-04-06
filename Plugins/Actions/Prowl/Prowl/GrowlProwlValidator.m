#import "GrowlProwlValidator.h"
#import "PRServerError.h"

@interface GrowlProwlValidator()
@property (nonatomic, assign, readwrite) id<GrowlProwlValidatorDelegate> delegate;
@end

@implementation GrowlProwlValidator
@synthesize delegate = _delegate;

- (id)initWithDelegate:(id<GrowlProwlValidatorDelegate>)delegate
{
	self = [super init];
	if(self) {
		self.delegate = delegate;
	}
	return self;
}

- (void)dealloc
{
    
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

- (void)validateApiKey:(PRAPIKey *)apiKey
{
	NSMutableString *fetchURLString = [NSMutableString stringWithString:@"https://api.prowlapp.com/publicapi/verify"];
	[fetchURLString appendFormat:@"?apikey=%@", [self encodedStringForString:apiKey.apiKey]];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fetchURLString]
														   cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
													   timeoutInterval:300.0f];
	
	request.HTTPMethod = @"GET";
	
	[NSURLConnection sendAsynchronousRequest:request
									   queue:[NSOperationQueue mainQueue]
						   completionHandler:^(NSURLResponse *response,
											   NSData *data,
											   NSError *error) {
							   NSLog(@"Response: %@", response);
							   
							   if(!data) {
								   [self.delegate validator:self
										   didFailWithError:error
												  forApiKey:apiKey];
								   return;
							   }
							   
							   NSLog(@"Got back XML: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
							   
							   NSXMLDocument *document = [[[NSXMLDocument alloc] initWithData:data options:0 error:&error] autorelease];
							   
							   if(!document) {
								   [self.delegate validator:self
										   didFailWithError:error
												  forApiKey:apiKey];
							   }
							   
							   NSXMLElement *successElement = [[document.rootElement elementsForName:@"success"] lastObject];
							   if(successElement) {
								   [self.delegate validator:self
										  didValidateApiKey:apiKey];
							   } else {
								   NSXMLElement *errorElement = [[document.rootElement elementsForName:@"error"] lastObject];
								   if(errorElement) {
									   NSInteger errorCode = [[[errorElement attributeForName:@"code"] stringValue] integerValue];
									   if(errorCode == 401) {
										   [self.delegate validator:self
												didInvalidateApiKey:apiKey];
									   } else {
										   [self.delegate validator:self
												   didFailWithError:[PRServerError serverErrorWithStatusCode:errorCode]
														  forApiKey:apiKey];
									   }
								   } else {
									   [self.delegate validator:self
											   didFailWithError:[PRServerError serverErrorWithStatusCode:-1]
													  forApiKey:apiKey];
								   }
							   }
						   }];
}

@end
