//  This class represents your plugin's preference pane.  There will be only one instance, but possibly many configurations
//  In order to access a configuration values, use the NSMutableDictionary *configuration for getting them. 
//  In order to change configuration values, use [self setConfigurationValue:forKey:]
//  This ensures that the configuration gets saved into the database properly.

#import "GrowlProwlPreferencePane.h"
#import "PRDefines.h"
#import "PRAPIKey.h"

@interface GrowlProwlPreferencePane()
@property (nonatomic, retain, readwrite) NSMutableArray *apiKeys;
@end

@implementation GrowlProwlPreferencePane
@synthesize tableView = _tableView;
@synthesize apiKeys = _apiKeys;

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

- (IBAction)connect:(id)sender
{
	
}

- (IBAction)add:(id)sender
{
	[self.apiKeys addObject:[[[PRAPIKey alloc] init] autorelease]];
	[self updateAPIKeys];
	
	[self.tableView beginUpdates];
	[self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:self.apiKeys.count]
						  withAnimation:NSTableViewAnimationEffectGap];
	[self.tableView endUpdates];
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

@end
