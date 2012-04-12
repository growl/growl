#import "PRPreferencePane.h"
#import "PRGenerator.h"
#import "PRValidator.h"
#import "PRWebViewWindowController.h"

@interface PRPreferencePane() <PRGeneratorDelegate, PRValidatorDelegate, PRWebViewWindowControllerDelegate>
@property (nonatomic, retain, readwrite) NSMutableArray *apiKeys;
@property (nonatomic, retain) PRGenerator *generator; // short-lived
@property (nonatomic, retain) PRValidator *validator; // long-lived
@property (nonatomic, retain) PRWebViewWindowController *webViewWindowController;
@end

@implementation PRPreferencePane
@synthesize webViewWindowController = _webViewWindowController;
@synthesize addButton = _addButton;
@synthesize removeButton = _removeButton;
@synthesize generateButton = _generateButton;
@synthesize generateProgressIndicator = _generateProgressIndicator;
@synthesize tableView = _tableView;
@synthesize apiKeysBox = _apiKeysBox;
@synthesize sendingToProwlBox = _sendingToProwlBox;
@synthesize prefixCheckbox = _prefixCheckbox;
@synthesize minimumPriorityCheckbox = _minimumPriorityCheckbox;
@synthesize onlyWhenIdleCheckbox = _onlyWhenIdleCheckbox;
@synthesize apiKeys = _apiKeys;
@synthesize generator = _generator;
@synthesize validator = _validator;

- (id)initWithBundle:(NSBundle *)bundle
{
    self = [super initWithBundle:bundle];
    if (self) {
        self.validator = [[[PRValidator alloc] initWithDelegate:self] autorelease];
    }
    return self;
}

- (void)dealloc
{
	[NSNotificationCenter.defaultCenter removeObserver:self];
	[_apiKeys release];
	[_generator release];
	[_validator release];
    [super dealloc];
}

- (NSString*)mainNibName
{
	return NSStringFromClass([self class]);
}

- (void)mainViewDidLoad
{
	[super mainViewDidLoad];
	[self refreshButtons];
	
	self.apiKeysBox.title = PRLocalizedString(@"API Keys", "The area in the Prowl preferences where the API keys are listed.");
	
	self.generateButton.title = PRLocalizedString(@"Generate", "The title for the button in the Prowl preferences which allows the user to generate (create by talking to the server) a new API key.");
	
	self.sendingToProwlBox.title = PRLocalizedString(@"Sending to Prowl", "The area in the Prowl preferences where the user chooses what options are available for conditionally sending to Prowl.");
	
	self.prefixCheckbox.title = PRLocalizedString(@"Prefix notifications with:", "The option in the Prowl preferences which, when enabled, allows the user to put text at the beginning of a notification.");
	
	self.minimumPriorityCheckbox.title = PRLocalizedString(@"Only when priority is at least:", "The option in the Prowl preferences which, when enabled, allows the user to select the lowest amount of priority that should be sent.");
	
	self.onlyWhenIdleCheckbox.title = PRLocalizedString(@"Only when Mac is idle", "The option in the Prowl preferences which, when enabled, only sends notifications to the Prowl server when Growl determines that the machine is idle.");
	
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(tableViewSelectionDidChange:)
											   name:NSTableViewSelectionDidChangeNotification
											 object:self.tableView];
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

- (void)refreshButtons
{
	self.generateButton.enabled = !self.generator;
	self.removeButton.enabled = !!self.tableView.numberOfSelectedRows;
}

- (void)updateConfigurationValues
{
	[super updateConfigurationValues];
	self.apiKeys = nil;
	
	[self validateApiKeys];
	[self.tableView reloadData];
}

#pragma mark - Validation
- (void)validateApiKey:(PRAPIKey *)apiKey
{
	[self.validator validateApiKey:apiKey];
	[self reloadValidateColumnForApiKey:apiKey];
}

- (void)validateApiKeys
{
	for(PRAPIKey *apiKey in self.apiKeys) {
		[self validateApiKey:apiKey];
	}
}

- (IBAction)didUpdateApiKey:(id)sender
{
	if([sender isKindOfClass:[NSTextField class]]) {
		NSInteger idx = [self.tableView rowForView:sender];
		if(idx != -1) {
			PRAPIKey *apiKey = [self.apiKeys objectAtIndex:idx];
			if(!apiKey.validated) {
				[self validateApiKey:apiKey];
			}
		}
	} else {	
		[self saveApiKeys];
	}
}

- (void)reloadValidateColumnForApiKey:(PRAPIKey *)apiKey
{
	NSUInteger idx = [self.apiKeys indexOfObjectIdenticalTo:apiKey];
	if(idx != NSNotFound) {
		[self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:idx]
								  columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfColumns)]];
	}
}

#pragma mark - Key management

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
		
		[self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:self.apiKeys.count - 1]
							  withAnimation:NSTableViewAnimationEffectGap];
	}
}

#pragma mark - Actions

- (IBAction)generate:(id)sender
{
	[self.generateProgressIndicator startAnimation:nil];
	self.generator = [[[PRGenerator alloc] initWithProviderKey:PRProviderKey
															  delegate:self] autorelease];
	[self.generator fetchToken];
	[self refreshButtons];
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
		
	[self.tableView removeRowsAtIndexes:removeSet
						  withAnimation:NSTableViewAnimationEffectGap];
	
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

- (NSMutableArray *)apiKeys
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

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	PRAPIKey *apiKey = [self.apiKeys objectAtIndex:row];
	
	if([tableColumn.identifier isEqualToString:@"validated"]) {
		if([self.validator isValidatingApiKey:apiKey]) {
			NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"validatedProgressIndicator"
											   owner:self];
			return cellView;
		} else {
			NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"validatedImage"
											   owner:self];
			return cellView;
		}
	}
	
	return [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	PRAPIKey *apiKey = [self.apiKeys objectAtIndex:row];
	
	if([tableColumn.identifier isEqualToString:@"enabled"]) {
		return apiKey;
	} else if([tableColumn.identifier isEqualToString:@"apikey"]) {
		return apiKey;
	} else if([tableColumn.identifier isEqualToString:@"validated"]) {
		if([self.validator isValidatingApiKey:apiKey]) {
			return [NSNumber numberWithBool:YES];
		} else if(apiKey.validated) {
            return [[NSBundle bundleForClass:[self class]] imageForResource:@"checkmark"];
		} else {
            return [[NSBundle bundleForClass:[self class]] imageForResource:@"anticheckmark"];
		}
	}
	
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self refreshButtons];
}

#pragma mark - PRValidatorDelegate
- (void)validator:(PRValidator *)validator didValidateApiKey:(PRAPIKey *)apiKey
{
	NSLog(@"Validated apiKey: %@", apiKey);
	apiKey.validated = YES;
	[self saveApiKeys];
	[self reloadValidateColumnForApiKey:apiKey];
}

- (void)validator:(PRValidator *)validator didInvalidateApiKey:(PRAPIKey *)apiKey
{
	NSLog(@"Invalidated apiKey: %@", apiKey);
	apiKey.validated = NO;
	[self saveApiKeys];
	[self reloadValidateColumnForApiKey:apiKey];
}

- (void)validator:(PRValidator *)validator didFailWithError:(NSError *)error forApiKey:(PRAPIKey *)apiKey
{
	if(!apiKey.validated) {
		// Don't annoy the user if we error on something valid already.
		[[NSAlert alertWithError:error] runModal];
	}
	
	[self reloadValidateColumnForApiKey:apiKey];
}

#pragma mark - PRGeneratorDelegate
- (void)finishGenerator
{
	self.generator = nil;
	[self.generateProgressIndicator stopAnimation:nil];
	[self refreshButtons];
}

- (void)generator:(PRGenerator *)generator didFetchTokenURL:(NSString *)retrieveURL
{
	NSLog(@"Got retrieve URL: %@", retrieveURL);

	self.webViewWindowController = [[[PRWebViewWindowController alloc] initWithURL:retrieveURL
																				  delegate:self] autorelease];
	
	[self.webViewWindowController showWindow:nil];
}

- (void)generator:(PRGenerator *)generator didFetchApiKey:(PRAPIKey *)apiKey
{
	NSLog(@"Got API key: %@", apiKey);
	
	[self addApiKey:apiKey];	
	[self finishGenerator];
}

- (void)generator:(PRGenerator *)generator didFailWithError:(NSError *)error
{
	[[NSAlert alertWithError:error] runModal];
	[self finishGenerator];
}

#pragma mark - PRWebKitWindowControllerDelegate
- (void)webView:(PRWebViewWindowController *)webView didFailWithError:(NSError *)error
{
	[[NSAlert alertWithError:error] runModal];
	
	[webView close];
	self.webViewWindowController = nil;
	[self finishGenerator];
}

- (void)webViewDidSucceed:(PRWebViewWindowController *)webView
{
	self.webViewWindowController = nil;
	[self.generator fetchApiKey];
}

- (void)webViewDidCancel:(PRWebViewWindowController *)webView
{
	self.webViewWindowController = nil;
	[self finishGenerator];
}

@end