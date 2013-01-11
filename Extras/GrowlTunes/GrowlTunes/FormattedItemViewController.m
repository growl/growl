//
//  FormattedItemViewController.m
//  GrowlTunes
//
//  Created by Travis Tilley on 12/12/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "FormattedItemViewController.h"
#import "macros.h"

@implementation FormattedItemViewController

@synthesize formattedDescription = _formattedDescription;

@synthesize icon = _icon;
@synthesize title = _mediaTitle;
@synthesize details = _details;

- (id)init
{
	if((self = [super initWithNibName:@"FormattedItem" bundle:[NSBundle mainBundle]])){
		
	}
	return self;
}

-(void)dealloc
{
	RELEASE(_formattedDescription); _formattedDescription = nil;
	RELEASE(_icon); _icon = nil;
	RELEASE(_mediaTitle); _mediaTitle = nil;
	RELEASE(_details); _details = nil;
	SUPER_DEALLOC;
}

-(void)awakeFromNib {
	[self updateItems];
}

-(void)updateItems {
	if (_formattedDescription) {
		self.icon = [[NSImage alloc] initWithData:[_formattedDescription valueForKey:@"icon"]];
		self.title = [_formattedDescription valueForKey:@"title"];
		self.details = [_formattedDescription valueForKey:@"description"];
	} else {
		self.icon = nil;
		self.title = nil;
		self.details = nil;
	}
}

-(void)setFormattedDescription:(NSDictionary *)newDescription {
	if(_formattedDescription){
		RELEASE(_formattedDescription);
	}
	_formattedDescription = RETAIN(newDescription);
	[self updateItems];
}

-(void)setIcon:(NSImage*)icon
{
	if (!icon)
		icon = [NSImage imageNamed:NSImageNameApplicationIcon];
	[icon setSize:NSMakeSize(64, 64)];
	
	if(_icon){
		RELEASE(_icon);
	}
	_icon = RETAIN(icon);
}

@end
