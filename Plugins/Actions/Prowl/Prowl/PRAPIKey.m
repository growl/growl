#import "PRAPIKey.h"

@implementation PRAPIKey
@synthesize apiKey = _apiKey;
@synthesize enabled = _enabled;

- (id)init
{
	self = [super init];
	if(self) {
		self.enabled = YES;
		self.apiKey = @"";
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if(self) {
		self.apiKey = [decoder decodeObjectForKey:@"apiKey"];
		self.enabled = [[decoder decodeObjectForKey:@"enabled"] boolValue];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:[NSNumber numberWithBool:self.enabled]
				 forKey:@"enabled"];
	[coder encodeObject:self.apiKey
				 forKey:@"apiKey"];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p; enabled = %d; apiKey = %@>",
			NSStringFromClass([self class]), self, self.enabled, self.apiKey];
}

@end
