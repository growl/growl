#import "GrowlProwlPreferencePane.h"
#import "GrowlProwlGenerator.h"

@interface GrowlProwlPreferencePane() <GrowlProwlGeneratorDelegate>
@property (nonatomic, retain, readwrite) NSMutableArray *apiKeys;
@property (nonatomic, retain) GrowlProwlGenerator *generator;
@end

@implementation GrowlProwlPreferencePane
@synthesize generateButton = _generateButton;
@synthesize tableView = _tableView;
@synthesize apiKeys = _apiKeys;
@synthesize generator = _generator;

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)dealloc
{
	[_apiKeys release];
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

- (void)updateConfigurationValues
{
	[super updateConfigurationValues];
	self.apiKeys = nil;
	
	[self.tableView reloadData];
}

- (void)updateAPIKeys
{
	NSLog(@"Updated keys: %@", self.apiKeys);
	
	NSData *archivedKeys = [NSKeyedArchiver archivedDataWithRootObject:self.apiKeys];
	
	[self setConfigurationValue:archivedKeys
						 forKey:PRPreferenceKeyAPIKeys];
}

- (void)addApiKey:(PRAPIKey *)apiKey
{
	[self.apiKeys addObject:apiKey];
	[self updateAPIKeys];
	
	[self.tableView beginUpdates];
	[self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:self.apiKeys.count - 1]
						  withAnimation:NSTableViewAnimationEffectGap];
	[self.tableView endUpdates];
}

- (IBAction)connect:(id)sender
{
//		self.generateButton.enabled = NO;
	if(self.generator) {
		[self.generator fetchApiKey];
	} else {
		self.generator = [[[GrowlProwlGenerator alloc] initWithProviderKey:PRProviderKey
																  delegate:self] autorelease];
		[self.generator fetchToken];
	}	
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
	[self updateAPIKeys];
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
	if([tableColumn.identifier isEqualToString:@"enabled"]) {
		[[self.apiKeys objectAtIndex:row] setEnabled:[object boolValue]];
	} else if([tableColumn.identifier isEqualToString:@"apikey"]) {
		[[self.apiKeys objectAtIndex:row] setApiKey:object];
	}
	
	[self updateAPIKeys];
}

#pragma mark - GrowlProwlGeneratorDelegate
- (void)generator:(GrowlProwlGenerator *)generator didFetchTokenURL:(NSString *)retrieveURL
{
	NSLog(@"Got retrieve URL: %@", retrieveURL);
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:retrieveURL]];
}

- (void)generator:(GrowlProwlGenerator *)generator didFetchApiKey:(PRAPIKey *)apiKey
{
	NSLog(@"Got API key: %@", apiKey);
	
	self.generateButton.enabled = YES;
	[self addApiKey:apiKey];	
	self.generator = nil;
}

- (void)generator:(GrowlProwlGenerator *)generator didFailWithError:(NSError *)error
{
	NSLog(@"Generator failed with error: %@", error);
	self.generateButton.enabled = YES;
	self.generator = nil;
}

@end
