//
//  NSObject+DRYDescription.h
//  growltunes
//
//  Created by Travis Tilley on 11/4/11.
//

#import <Foundation/Foundation.h>

@interface NSObject (DRYDescription)

- (NSArray*)sortedPropertyNames;
- (NSArray*)sortedInstanceVariableNames;
- (NSMutableDictionary*)dictionaryForKVCKeys:(NSArray*)keys;
- (NSString*)dryDescriptionForProperties;
- (NSString*)dryDescriptionForIVars;

@end
