//
//  GrowlLocalizedStringsController.h
//  Growl
//
//  Created by Rudy Richter on 10/30/12.
//
//

#import <Foundation/Foundation.h>

@interface GrowlLocalizedStringsController : NSObject
{
    NSBundle *_bundle;
    NSString *_table;
}

- (id)valueForUndefinedKey:(NSString *)key;
- (NSString*)stringForKey:(NSString*)key;

@property (nonatomic, assign) NSBundle *bundle;
@property (nonatomic, retain) NSString *table;

@end
