//
//  FormattedItemViewController.m
//  GrowlTunes
//
//  Created by Travis Tilley on 12/12/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "FormattedItemViewController.h"
#import "macros.h"


@interface FormattedItemViewController ()
-(void)observeSelf;
-(void)calculateSize;
@property(readwrite, nonatomic, STRONG) IBOutlet NSImageView* artworkView;
@property(readwrite, nonatomic, STRONG) IBOutlet NSTextField* titleField;
@property(readwrite, nonatomic, STRONG) IBOutlet NSTextField* detailsField;
@property(readwrite, nonatomic, STRONG) IBOutlet NSImage* icon;
@property(readwrite, nonatomic, STRONG) IBOutlet NSString* title;
@property(readwrite, nonatomic, STRONG) IBOutlet NSString* details;
@end


@implementation FormattedItemViewController

@synthesize formattedDescription = _formattedDescription;
@synthesize artworkView = _artworkView;
@synthesize titleField = _titleField;
@synthesize detailsField = _detailsField;

static int ddLogLevel = DDNS_LOG_LEVEL_DEFAULT;

+ (int)ddLogLevel
{
    return ddLogLevel;
}

+ (void)ddSetLogLevel:(int)logLevel
{
    ddLogLevel = logLevel;
}

+ (void)initialize
{
    if (self == [FormattedItemViewController class]) {
        NSNumber *logLevel = [[NSUserDefaults standardUserDefaults] objectForKey:
                              [NSString stringWithFormat:@"%@LogLevel", [self class]]];
        if (logLevel)
            ddLogLevel = [logLevel intValue];
    }
}

- (id)init
{
    self = [super initWithNibName:@"FormattedItem" bundle:[NSBundle mainBundle]];
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
              options:(NSKeyValueObservingOptionInitial) 
              context:NULL];
}

-(void)dealloc
{
    self.formattedDescription = nil;
    [self removeObserver:self forKeyPath:@"formattedDescription"];
    RELEASE(_artworkView);
    RELEASE(_titleField);
    RELEASE(_detailsField);
    RELEASE(_formattedDescription);
    SUPER_DEALLOC;
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if (!_titleField || !_detailsField) return;
    
    if (_formattedDescription) {
        self.icon = [[NSImage alloc] initWithData:[_formattedDescription valueForKey:@"icon"]];
        self.title = [_formattedDescription valueForKey:@"title"];
        self.details = [_formattedDescription valueForKey:@"description"];
    } else {
        self.icon = nil;
        self.title = nil;
        self.details = nil;
    }
    
//    [self calculateSize];
}

-(NSImage*)icon
{
    return _artworkView.image;
}

-(void)setIcon:(NSImage*)icon
{
    if (!icon) icon = [NSImage imageNamed:@"GrowlTunes"];
    [icon setSize:NSMakeSize(64, 64)];
    _artworkView.image = icon;
    [_artworkView setNeedsDisplay:YES];
}

-(NSString*)title
{
    return _titleField.stringValue;
}

-(void)setTitle:(NSString*)title
{
    if (!title) title = @"Title";
    _titleField.stringValue = title;
    [_titleField setNeedsDisplay:YES];
}

-(NSString*)details
{
    return _detailsField.stringValue;
}

-(void)setDetails:(NSString*)text
{
    if (!text) text = @"Description";
    _detailsField.stringValue = text;
    [_detailsField setNeedsDisplay:YES];
}

// doesn't quite work as it should
-(void)calculateSize
{
    if (!_titleField || !_detailsField) return;
    
    NSAttributedString* title = _titleField.attributedStringValue;
    NSAttributedString* details = _detailsField.attributedStringValue;
    
    if (!title || !details) return;
    
    CGFloat oneLineHeight = 14.0;
    CGFloat minWidth = 120.0;
    CGFloat maxWidth = 300.0;
    
    NSStringDrawingOptions titleOptions =
        NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading | NSStringDrawingDisableScreenFontSubstitution;
    NSStringDrawingOptions detailsOptions =
        NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading | NSStringDrawingDisableScreenFontSubstitution;
    
    NSRect rsTitle = [title boundingRectWithSize:NSMakeSize(0, oneLineHeight) options:titleOptions];
    
    NSSize ctSize = rsTitle.size;
    if (ctSize.width < minWidth) ctSize.width = minWidth;
    if (ctSize.width > maxWidth) ctSize.width = maxWidth;
    if (ctSize.height < oneLineHeight) ctSize.height = oneLineHeight;
    
    NSRect rsDetails = [details boundingRectWithSize:NSMakeSize(maxWidth, 0) options:detailsOptions];
    
    NSSize cdSize = rsDetails.size;
    if (cdSize.width < minWidth) cdSize.width = minWidth;
    if (cdSize.width > maxWidth) cdSize.width = maxWidth;
    if (cdSize.height < oneLineHeight) cdSize.height = oneLineHeight;
        
    [_titleField setFrameSize:ctSize];
    [_detailsField setFrameSize:cdSize];
    
    [self.view setNeedsLayout:YES];
}

@end
