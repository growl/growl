#import <GrowlPlugins/GrowlPluginPreferencePane.h>

@class PRPreferences;
@interface GrowlProwlPreferencePane : GrowlPluginPreferencePane
@property (nonatomic, retain) PRPreferences *preferences;

@property (nonatomic, retain, readonly) NSMutableArray *apiKeys; // array of PRAPIKey
@property (assign) IBOutlet NSTableView *tableView;

@property (nonatomic, assign) BOOL onlyWhenIdle;

@property (nonatomic, assign) BOOL minimumPriorityEnabled;
@property (nonatomic, assign) NSInteger minimumPriority;

@property (nonatomic, assign) BOOL prefixEnabled;
@property (nonatomic, copy) NSString *prefix;

- (IBAction)connect:(id)sender;
- (IBAction)add:(id)sender;
- (IBAction)remove:(id)sender;
@end
