//
//  FormattedItemViewController.m
//  GrowlTunes
//
//  Created by Travis Tilley on 12/12/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "FormattedItemViewController.h"


@interface FormattedItemViewController ()
-(void)observeSelf;
@property(readwrite, nonatomic, retain) IBOutlet NSImageView* artworkView;
@property(readwrite, nonatomic, retain) IBOutlet NSTextField* titleField;
@property(readwrite, nonatomic, retain) IBOutlet NSTextField* detailsField;
@property(readwrite, nonatomic, retain) IBOutlet NSImage* icon;
@property(readwrite, nonatomic, retain) IBOutlet NSString* title;
@property(readwrite, nonatomic, retain) IBOutlet NSString* details;
@end


@implementation FormattedItemViewController

@synthesize formattedDescription = _formattedDescription;
@synthesize artworkView = _artworkView;
@synthesize titleField = _titleField;
@synthesize detailsField = _detailsField;


- (id)init
{
    self = [super initWithNibName:@"FormattedItem" bundle:[NSBundle mainBundle]];
    if (self) [self observeSelf];
    return self;
}

-(void)awakeFromNib
{
    [self observeSelf];
}

-(void)observeSelf
{
    [self addObserver:self
           forKeyPath:@"formattedDescription"
              options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial) 
              context:NULL];
}

-(void)dealloc
{
    self.formattedDescription = nil;
    [self removeObserver:self forKeyPath:@"formattedDescription"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if (_formattedDescription) {
        self.icon = [_formattedDescription valueForKey:@"icon"];
        self.title = [_formattedDescription valueForKey:@"title"];
        self.details = [_formattedDescription valueForKey:@"description"];
    } else {
        self.icon = nil;
        self.title = nil;
        self.details = nil;
    }
}

-(NSImage*)icon
{
    return self.artworkView.image;
}

-(void)setIcon:(NSImage*)icon
{
    if (!icon) icon = [NSImage imageNamed:@"GrowlTunes"];
    [icon setSize:NSMakeSize(64,64)];
    self.artworkView.image = icon;
    [self.artworkView setNeedsDisplay:YES];
}

-(NSString*)title
{
    return self.titleField.stringValue;
}

-(void)setTitle:(NSString*)title
{
    if (!title) title = @"Title";
    self.titleField.stringValue = title;
    [self.titleField setNeedsDisplay:YES];
}

-(NSString*)details
{
    return self.detailsField.stringValue;
}

-(void)setDetails:(NSString*)text
{
    if (!text) text = @"Description";
    self.detailsField.stringValue = text;
    [self.detailsField setNeedsDisplay:YES];
}

@end
