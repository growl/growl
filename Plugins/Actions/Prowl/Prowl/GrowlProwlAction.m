#import "GrowlProwlAction.h"
#import "GrowlProwlPreferencePane.h"
#import <GrowlPlugins/GrowlDefines.h>
#import <GrowlPlugins/GrowlIdleStatusObserver.h>
#import <GrowlPlugins/GrowlKeychainUtilities.h>

NSString *const PRPreferenceKeyAPIKeys = @"PRPreferenceKeyAPIKeys";
NSString *const PRPreferenceKeyOnlyWhenIdle = @"PRPreferenceKeyOnlyWhenIdle";
NSString *const PRPreferenceKeyMinimumPriority = @"PRPreferenceKeyMinimumPriority";
NSString *const PRPreferenceKeyMinimumPriorityEnabled = @"PRPreferenceKeyMinimumPriorityEnabled";
NSString *const PRPreferenceKeyPrefix = @"PRPreferenceKeyPrefix";
NSString *const PRPreferenceKeyPrefixEnabled = @"PRPreferenceKeyPrefixEnabled";

@implementation GrowlProwlAction

- (id)init
{
    self = [super init];
    if (self) {

    }
    return self;
}


- (GrowlPluginPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlProwlPreferencePane alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.prowlapp.growl.Prowl"]];
	
	return preferencePane;
}

- (void)dispatchNotification:(NSDictionary *)notification
		  withConfiguration:(NSDictionary *)configuration
{
	NSString *event = [notification objectForKey:GROWL_NOTIFICATION_TITLE];
	NSString *application = [notification valueForKey:GROWL_APP_NAME];
	NSString *description = [notification objectForKey:GROWL_NOTIFICATION_DESCRIPTION];
	NSInteger priority = [[notification valueForKey:GROWL_NOTIFICATION_PRIORITY] intValue];
	BOOL isPreview = ([application isEqualToString:@"Growl"] && [event isEqualToString:@"Preview"]);
	
	if(!isPreview) {
		BOOL onlyWhenIdle = [[configuration valueForKey:PRPreferenceKeyOnlyWhenIdle] boolValue];
		
		BOOL minimumPriorityEnabled = [[configuration valueForKey:PRPreferenceKeyMinimumPriorityEnabled] boolValue];
		NSInteger minimumPriority = [[configuration valueForKey:PRPreferenceKeyMinimumPriority] integerValue];
				
		if(minimumPriorityEnabled && priority < minimumPriority) {
			return;
		}
		
		if(onlyWhenIdle && ![[GrowlIdleStatusObserver sharedObserver] isIdle]) {
			return;
		}
	}
	
	NSData *apiKeysData = [configuration valueForKey:PRPreferenceKeyAPIKeys];
	NSString *apiKeys = nil;
	if(apiKeysData) {
		NSArray *apiKeysArray = [NSKeyedUnarchiver unarchiveObjectWithData:apiKeysData];
		if(apiKeysArray.count) {
			apiKeys = [self apiKeysStringForApiKeys:apiKeysArray];
		}
	}
	
	if(!apiKeys.length) {
		return;
	}
			
	BOOL prefixEnabled = [[configuration valueForKey:PRPreferenceKeyPrefixEnabled] boolValue];
	NSString *prefix = [configuration valueForKey:PRPreferenceKeyPrefix];
	if(prefixEnabled && prefix.length) {
		description = [NSString stringWithFormat:@"%@: %@", prefix, description];
	}
	
	NSURL *postURL = [NSURL URLWithString:@"https://api.prowlapp.com/publicapi/add"];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:postURL 
														   cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
													   timeoutInterval:300.0f];
	request.HTTPMethod = @"POST";
	request.HTTPBody = [self bodyWithApiKeys:apiKeys
								 application:application
									   event:event
								 description:description
									priority:priority];
	
	[NSURLConnection sendAsynchronousRequest:request
									   queue:[NSOperationQueue mainQueue]
						   completionHandler:^(NSURLResponse *response,
											   NSData *data,
											   NSError *error) {
							   if(!data && error) {
								   NSLog(@"Got error: %@", error);
								   return;
							   }
							   
							   NSLog(@"Got data: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
							   
							   NSInteger statusCode = 0;
							   if([response respondsToSelector:@selector(statusCode)]) {
								   statusCode = [(id)response statusCode];
							   }
							   
							   if(statusCode == 200) {
								   NSLog(@"Posted notification!");
							   } else {
								   NSLog(@"Error response: %@ %@", response, [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
							   }
						   }];
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

- (NSString *)apiKeysStringForApiKeys:(NSArray *)apiKeys
{
	NSMutableArray *stringArray = [NSMutableArray array];
	for(PRAPIKey *key in apiKeys) {
		if(key.enabled) {// && key.validated) {
			[stringArray addObject:key.apiKey];
		}
	}
	return [stringArray componentsJoinedByString:@","];
}

- (NSData *)bodyWithApiKeys:(NSString *)apiKeys
				application:(NSString *)application
					  event:(NSString *)event
				description:(NSString *)description
				   priority:(NSInteger)priority
{
	NSMutableString *bodyString = [NSMutableString string];
	[bodyString appendFormat:@"apikey=%@", [self encodedStringForString:apiKeys]];
	[bodyString appendFormat:@"&application=%@", [self encodedStringForString:application]];
	[bodyString appendFormat:@"&event=%@", [self encodedStringForString:event]];
	[bodyString appendFormat:@"&description=%@", [self encodedStringForString:description]];
	[bodyString appendFormat:@"&priority=%d", priority];
	return [bodyString dataUsingEncoding:NSUTF8StringEncoding];
}

@end
