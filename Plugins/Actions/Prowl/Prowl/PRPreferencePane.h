#import <GrowlPlugins/GrowlPluginPreferencePane.h>
#import "PRDefines.h"
#import "PRAPIKey.h"

@interface PRPreferencePane : GrowlPluginPreferencePane
@property (nonatomic, retain, readonly) NSMutableArray *apiKeys; // array of PRAPIKey
@property (assign) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet NSBox *apiKeysBox;

@property (assign) IBOutlet NSBox *sendingToProwlBox;
@property (assign) IBOutlet NSButton *prefixCheckbox;
@property (assign) IBOutlet NSButton *minimumPriorityCheckbox;
@property (assign) IBOutlet NSButton *onlyWhenIdleCheckbox;

@property (nonatomic, assign) BOOL onlyWhenIdle;
@property (nonatomic, assign) BOOL minimumPriorityEnabled;
@property (nonatomic, assign) NSInteger minimumPriority;
@property (nonatomic, assign) BOOL prefixEnabled;
@property (nonatomic, copy) NSString *prefix;

@property (assign) IBOutlet NSButton *addButton;
@property (assign) IBOutlet NSButton *removeButton;
@property (assign) IBOutlet NSButton *generateButton;
@property (assign) IBOutlet NSProgressIndicator *generateProgressIndicator;

- (IBAction)generate:(id)sender;
- (IBAction)add:(id)sender;
- (IBAction)remove:(id)sender;
@end
