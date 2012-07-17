#import "PRAPIKey.h"

@interface PRAPIKey()
@end

@implementation PRAPIKey
@synthesize apiKey = _apiKey;
@synthesize enabled = _enabled;
@synthesize validated = _validated;

- (id)init
{
	self = [super init];
	if(self) {
		self.enabled = YES;
		self.validated = NO;
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
		self.validated = [[decoder decodeObjectForKey:@"validated"] boolValue];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:[NSNumber numberWithBool:self.enabled]
				 forKey:@"enabled"];
	[coder encodeObject:self.apiKey
				 forKey:@"apiKey"];
	[coder encodeObject:[NSNumber numberWithBool:self.validated]
				 forKey:@"validated"];
}

- (BOOL)isEqual:(id)object
{
	if([object isKindOfClass:[PRAPIKey class]]) {
		PRAPIKey *otherApiKey = (PRAPIKey *)object;
		return [otherApiKey.apiKey compare:self.apiKey options:NSCaseInsensitiveSearch] == NSOrderedSame;
	}
	
	return NO;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p; enabled = %d; validated = %d; apiKey = %@>",
			NSStringFromClass([self class]), self, self.enabled, self.validated, self.apiKey];
}

- (void)setApiKey:(NSString *)apiKey
{
	if(_apiKey != apiKey) {
		[_apiKey release];
		_apiKey = [apiKey copy];
		
		self.validated = NO;
	}
}

@end
