//
//  GrowlLocalizedStringsController.h
//  Growl
//
//  Created by Rudy Richter on 10/30/12.
//
//

#import "GrowlLocalizedStringsController.h"

@implementation GrowlLocalizedStringsController
@synthesize bundle = _bundle;
@synthesize table = _table;

- (id)init
{
    self = [super init];
    if(self)
    {
        _bundle = [NSBundle mainBundle];
    }
    return self;
}

- (void)dealloc
{
    [_table release];
    _table = nil;
    
    [super dealloc];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    NSString *result = [self stringForKey:key];
    return result;
}

- (NSString*)stringForKey:(NSString*)key
{
    NSString *result = nil;
    NSString *unlocalized = [NSString stringWithFormat:@"UNLOCALIZED(%@)", key];

    result = [self.bundle localizedStringForKey:key value:unlocalized table:self.table];
    
    return result;
}

@end
