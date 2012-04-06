#import "GrowlProwlPreferencePane.h"
#import "GrowlProwlGenerator.h"
#import "GrowlProwlValidator.h"
#import "GrowlProwlWebViewWindowController.h"

@interface GrowlProwlPreferencePane() <GrowlProwlGeneratorDelegate, GrowlProwlValidatorDelegate, GrowlProwlWebViewWindowControllerDelegate>
@property (nonatomic, retain, readwrite) NSMutableArray *apiKeys;
@property (nonatomic, retain) GrowlProwlGenerator *generator; // short-lived
@property (nonatomic, retain) GrowlProwlValidator *validator; // long-lived
@property (nonatomic, retain) GrowlProwlWebViewWindowController *webViewWindowController;
@end

@implementation GrowlProwlPreferencePane
@synthesize webViewWindowController = _webViewWindowController;
@synthesize generateButton = _generateButton;
@synthesize generateProgressIndicator = _generateProgressIndicator;
@synthesize tableView = _tableView;
@synthesize apiKeys = _apiKeys;
@synthesize generator = _generator;
@synthesize validator = _validator;

- (id)initWithBundle:(NSBundle *)bundle
{
    self = [super initWithBundle:bundle];
    if (self) {
        self.validator = [[[GrowlProwlValidator alloc] initWithDelegate:self] autorelease];
    }
    return self;
}

- (void)dealloc
{
	[_apiKeys release];
	[_generator release];
	[_validator release];
    [super dealloc];
}

- (NSString*)mainNibName
{
	return @"ProwlPrefPane";
}

- (NSSet *)bindingKeys
{	
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [[NSSet setWithObjects:
				 PR_SELECTOR(minimumPriority),
				 PR_SELECTOR(minimumPriorityEnabled),
				 PR_SELECTOR(onlyWhenIdle),
				 PR_SELECTOR(prefixEnabled),
				 PR_SELECTOR(prefix),
				 nil] retain];
	});
	return keys;
}

- (void)didSelect
{
	[self validateApiKeys];
}

- (void)updateConfigurationValues
{
	[super updateConfigurationValues];
	self.apiKeys = nil;
	
	[self validateApiKeys];
	[self.tableView reloadData];
}

- (void)validateApiKeys
{
	for(PRAPIKey *apiKey in self.apiKeys) {
		[self.validator validateApiKey:apiKey];
	}
}

- (void)saveApiKeys
{
	NSLog(@"Updated keys: %@", self.apiKeys);
	
	NSData *archivedKeys = [NSKeyedArchiver archivedDataWithRootObject:self.apiKeys];
	
	[self setConfigurationValue:archivedKeys
						 forKey:PRPreferenceKeyAPIKeys];
}

- (void)addApiKey:(PRAPIKey *)apiKey
{
	if([self.apiKeys containsObject:apiKey]) {
		NSLog(@"Not adding API key, contains already: %@", apiKey);
	} else {
		[self.apiKeys addObject:apiKey];
		[self saveApiKeys];
		
		[self.tableView beginUpdates];
		[self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:self.apiKeys.count - 1]
							  withAnimation:NSTableViewAnimationEffectGap];
		[self.tableView endUpdates];
	}
}

- (IBAction)connect:(id)sender
{
	self.generateButton.enabled = NO;
	[self.generateProgressIndicator startAnimation:nil];
	self.generator = [[[GrowlProwlGenerator alloc] initWithProviderKey:PRProviderKey
															  delegate:self] autorelease];
	[self.generator fetchToken];
}

- (IBAction)add:(id)sender
{
	[self addApiKey:[[[PRAPIKey alloc] init] autorelease]];
	
	[self.tableView editColumn:[self.tableView columnWithIdentifier:@"apikey"]
						   row:self.apiKeys.count - 1
					 withEvent:nil
						select:NO];
}

- (IBAction)remove:(id)sender
{
	if(self.tableView.numberOfSelectedRows == 0)
		return;
	
	NSIndexSet *removeSet = self.tableView.selectedRowIndexes;
		
	[self.tableView beginUpdates];
	[self.tableView removeRowsAtIndexes:removeSet
						  withAnimation:NSTableViewAnimationEffectGap];
	[self.tableView endUpdates];
	
	[self.apiKeys removeObjectsAtIndexes:removeSet];
	[self saveApiKeys];
}

#pragma mark - Preferences

- (void)setPrefixEnabled:(BOOL)prefixEnabled
{
	[self setConfigurationValue:[NSNumber numberWithBool:prefixEnabled]
						 forKey:PRPreferenceKeyPrefixEnabled];
}

- (BOOL)prefixEnabled
{
	return [[self.configuration valueForKey:PRPreferenceKeyPrefixEnabled] boolValue];
}

- (void)setPrefix:(NSString *)prefix
{
	[self setConfigurationValue:prefix forKey:PRPreferenceKeyPrefix];
}

- (NSString *)prefix
{
	return [self.configuration valueForKey:PRPreferenceKeyPrefix];
}

- (void)setMinimumPriorityEnabled:(BOOL)minimumPriorityEnabled
{
	[self setConfigurationValue:[NSNumber numberWithBool:minimumPriorityEnabled]
						 forKey:PRPreferenceKeyMinimumPriorityEnabled];
}

- (BOOL)minimumPriorityEnabled
{
	return [[self.configuration valueForKey:PRPreferenceKeyMinimumPriorityEnabled] boolValue];
}

- (void)setMinimumPriority:(NSInteger)minimumPriority
{
	[self setConfigurationValue:[NSNumber numberWithInteger:minimumPriority]
						 forKey:PRPreferenceKeyMinimumPriority];
}

- (NSInteger)minimumPriority
{
	return [[self.configuration valueForKey:PRPreferenceKeyMinimumPriority] integerValue];
}

- (void)setOnlyWhenIdle:(BOOL)onlyWhenIdle
{
	[self setConfigurationValue:[NSNumber numberWithBool:onlyWhenIdle]
						 forKey:PRPreferenceKeyOnlyWhenIdle];
}

- (BOOL)onlyWhenIdle
{
	return [[self.configuration valueForKey:PRPreferenceKeyOnlyWhenIdle] boolValue];	
}

- (NSArray *)apiKeys
{
	if(!_apiKeys) {
		NSData *keyData = [self.configuration valueForKey:PRPreferenceKeyAPIKeys];
		if(keyData) {
			NSArray *keys = [NSKeyedUnarchiver unarchiveObjectWithData:keyData];
			_apiKeys = [[NSMutableArray arrayWithArray:keys] retain];
		}
		
		if(!_apiKeys) {
			_apiKeys = [[NSMutableArray array] retain];
		}
	}
	
	return _apiKeys;
}

#pragma mark - NSTableView
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return self.apiKeys.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	PRAPIKey *apiKey = [self.apiKeys objectAtIndex:row];
	
	if([tableColumn.identifier isEqualToString:@"enabled"]) {
		return [NSNumber numberWithBool:apiKey.enabled];
	} else if([tableColumn.identifier isEqualToString:@"apikey"]) {
		return apiKey.apiKey;
	} else if([tableColumn.identifier isEqualToString:@"validated"]) {
		if(apiKey.validated) {
			return [[NSBundle bundleForClass:[self class]] imageForResource:@"checkmark"];
		} else {
			return [[NSBundle bundleForClass:[self class]] imageForResource:@"anticheckmark"];
		}
	} else {
		return nil;
	}
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	PRAPIKey *apiKey = [self.apiKeys objectAtIndex:row];
	
	if([tableColumn.identifier isEqualToString:@"enabled"]) {
		[apiKey setEnabled:[object boolValue]];
	} else if([tableColumn.identifier isEqualToString:@"apikey"]) {
		[apiKey setApiKey:object];
		[self.validator validateApiKey:apiKey];
	}
	
	[self saveApiKeys];
}

#pragma mark - GrowlProwlValidatorDelegate
- (void)reloadValidateColumnForApiKey:(PRAPIKey *)apiKey
{
	NSUInteger idx = [self.apiKeys indexOfObject:apiKey];
	if(idx != NSNotFound) {
		[self.tableView beginUpdates];
		[self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:idx]
								  columnIndexes:[NSIndexSet indexSetWithIndex:[self.tableView columnWithIdentifier:@"validated"]]];
		[self.tableView endUpdates];
	}
}

- (void)validator:(GrowlProwlValidator *)validator didValidateApiKey:(PRAPIKey *)apiKey
{
	NSLog(@"Validated apiKey: %@", apiKey);
	apiKey.validated = YES;
	[self saveApiKeys];
	[self reloadValidateColumnForApiKey:apiKey];
}

- (void)validator:(GrowlProwlValidator *)validator didInvalidateApiKey:(PRAPIKey *)apiKey
{
	NSLog(@"Invalidated apiKey: %@", apiKey);
	apiKey.validated = NO;
	[self saveApiKeys];
	[self reloadValidateColumnForApiKey:apiKey];
}

- (void)validator:(GrowlProwlValidator *)validator didFailWithError:(NSError *)error forApiKey:(PRAPIKey *)apiKey
{
	[[NSAlert alertWithError:error] runModal];
}

#pragma mark - GrowlProwlGeneratorDelegate
- (void)finishGenerator
{
	self.generateButton.enabled = YES;
	self.generator = nil;
	[self.generateProgressIndicator stopAnimation:nil];
}

- (void)generator:(GrowlProwlGenerator *)generator didFetchTokenURL:(NSString *)retrieveURL
{
	NSLog(@"Got retrieve URL: %@", retrieveURL);

	self.webViewWindowController = [[[GrowlProwlWebViewWindowController alloc] initWithURL:retrieveURL
																				  delegate:self] autorelease];
	
	[self.webViewWindowController showWindow:nil];
}

- (void)generator:(GrowlProwlGenerator *)generator didFetchApiKey:(PRAPIKey *)apiKey
{
	NSLog(@"Got API key: %@", apiKey);
	
	[self addApiKey:apiKey];	
	[self finishGenerator];
}

- (void)generator:(GrowlProwlGenerator *)generator didFailWithError:(NSError *)error
{
	[[NSAlert alertWithError:error] runModal];
	[self finishGenerator];
}

#pragma mark - GrowlProwlWebKitWindowControllerDelegate
- (void)webView:(GrowlProwlWebViewWindowController *)webView didFailWithError:(NSError *)error
{
	[[NSAlert alertWithError:error] runModal];
	
	[webView close];
	self.webViewWindowController = nil;
	[self finishGenerator];
}

- (void)webViewDidSucceed:(GrowlProwlWebViewWindowController *)webView
{
	self.webViewWindowController = nil;
	[self.generator fetchApiKey];
}

- (void)webViewDidCancel:(GrowlProwlWebViewWindowController *)webView
{
	self.webViewWindowController = nil;
	[self finishGenerator];
}

@end