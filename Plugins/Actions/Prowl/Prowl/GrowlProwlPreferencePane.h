#import <GrowlPlugins/GrowlPluginPreferencePane.h>
#import "PRDefines.h"
#import "PRAPIKey.h"

@interface GrowlProwlPreferencePane : GrowlPluginPreferencePane
@property (nonatomic, retain, readonly) NSMutableArray *apiKeys; // array of PRAPIKey
@property (assign) IBOutlet NSTableView *tableView;

@property (nonatomic, assign) BOOL onlyWhenIdle;

@property (nonatomic, assign) BOOL minimumPriorityEnabled;
@property (nonatomic, assign) NSInteger minimumPriority;

@property (nonatomic, assign) BOOL prefixEnabled;
@property (nonatomic, copy) NSString *prefix;

@property (assign) IBOutlet NSButton *generateButton;
- (IBAction)connect:(id)sender;
- (IBAction)add:(id)sender;
- (IBAction)remove:(id)sender;
@end
