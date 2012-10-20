//
//  QIBackgroundColorSelector.m
//  QuoteIt
//
//  Created by Stephen Poletto on 4/7/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "UIDevice+DETweetComposeViewController.h"
#import "QIBackgroundColorSelector.h"
#import "QIUtilities.h"

@interface QIBackgroundColorSelector ()

@end

@implementation QIBackgroundColorSelector
@synthesize editorBackgroundView;
@synthesize colorsScrollView;
@synthesize titleView;
@synthesize titleBarLabel;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Background Color";
        
        CGFloat shiftDownByHeight = ([UIDevice de_isIOS5]) ? 15.0 : 0.0;
        UIBarButtonItem *backItem = [UIBarButtonItem barItemWithImage:[UIImage imageNamed:@"sheet_btn_back_static"] highlightedImage:[UIImage imageNamed:@"sheet_btn_back_active"] title:nil target:self action:@selector(back:) shiftedDownByHeight:shiftDownByHeight];
        self.navigationItem.leftBarButtonItem = backItem;
        
        UIBarButtonItem *doneItem = [UIBarButtonItem barItemWithImage:[UIImage imageNamed:@"sheet_btn_done_static"] highlightedImage:[UIImage imageNamed:@"sheet_btn_done_press"] title:nil target:self action:@selector(done:) shiftedDownByHeight:shiftDownByHeight];
        self.navigationItem.rightBarButtonItem = doneItem;
    }
    return self;
}

static NSArray *QIColorSelectorColors;
- (NSArray *)colors {
    if (!QIColorSelectorColors) {
        QIColorSelectorColors = [[NSArray alloc] initWithObjects:[UIColor blackColor],
                                 [UIColor whiteColor], nil];
    }
    return QIColorSelectorColors;
}

- (void)back:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)done:(id)sender {
    if (delegate && [delegate respondsToSelector:@selector(backgroundColorSelectorIsDone:)]) {
        [delegate backgroundColorSelectorIsDone:self];
	}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Set the frame size
    CGRect frame = self.view.frame;
    
    // This constant must be the height of the view containing the controls + 44.
    frame.size.height = self.editorBackgroundView.frame.size.height + 44;
    self.view.frame = frame;
}

- (void)colorSelected:(UIButton *)sender {
    NSInteger colorIndex = sender.tag;
    UIColor *selectedColor = nil;
    if (colorIndex >= 0) {
        selectedColor = [[self colors] objectAtIndex:colorIndex];
    }
    
    if (delegate && [delegate respondsToSelector:@selector(backgroundColorSelctor:userSelectedTextColor:)]) {
        [delegate backgroundColorSelctor:self userSelectedTextColor:selectedColor];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleView.backgroundColor = [UIColor clearColor];
    
    if (![UIDevice de_isIOS5]) {
        CGRect titleFrame = self.titleBarLabel.frame;
        titleFrame.origin.y -= 8;
        self.titleBarLabel.frame = titleFrame;
    }
    
    self.navigationItem.titleView = self.titleView;
    self.titleBarLabel.text = self.title;
    self.titleBarLabel.textColor = [QIUtilities textEditorHeaderLabelColor];
    
    self.colorsScrollView.backgroundColor = [UIColor clearColor];
    
    // Add the "No Background Color" swatch first.
    UILabel *swatch = [[UILabel alloc] initWithFrame:CGRectMake(5.0, 35.0, 100.0, 103.0)];
    swatch.backgroundColor = [QIUtilities textEditorFontSelectorBackgroundColor];
    swatch.numberOfLines = 0;
    swatch.font = [UIFont fontWithName:@"Georgia" size:16.0];
    swatch.text = @"No Background";
    swatch.textAlignment = UITextAlignmentCenter;
    swatch.layer.cornerRadius = 4.0;
    swatch.layer.borderWidth = 1.0;
    swatch.layer.borderColor = [QIUtilities avatarBorderColor].CGColor;
    swatch.layer.masksToBounds = YES;
    UIButton *noBackgroundButton = [[UIButton alloc] initWithFrame:swatch.frame];
    noBackgroundButton.tag = -1;
    [noBackgroundButton addTarget:self action:@selector(colorSelected:) forControlEvents:UIControlEventTouchUpInside];
    [self.colorsScrollView addSubview:swatch];
    [self.colorsScrollView addSubview:noBackgroundButton];
    [noBackgroundButton release];
    [swatch release];
    
    CGFloat xOffset = 110.0;
    for (NSInteger i = 0; i < [[self colors] count]; i++) {
        UIColor *color = [[self colors] objectAtIndex:i];
        UIView *colorSwatch = [[UIView alloc] initWithFrame:CGRectMake(xOffset, 35.0, 100.0, 103.0)];
        xOffset += 105.0;
        colorSwatch.backgroundColor = color;
        colorSwatch.layer.cornerRadius = 4.0;
        colorSwatch.layer.borderWidth = 1.0;
        colorSwatch.layer.borderColor = [QIUtilities avatarBorderColor].CGColor;
        colorSwatch.layer.masksToBounds = YES;
        
        UIButton *colorButton = [[UIButton alloc] initWithFrame:colorSwatch.frame];
        colorButton.tag = i;
        [colorButton addTarget:self action:@selector(colorSelected:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.colorsScrollView addSubview:colorSwatch];
        [self.colorsScrollView addSubview:colorButton];
        [colorButton release];
        [colorSwatch release];
    }
    self.colorsScrollView.contentSize = CGSizeMake(xOffset, self.colorsScrollView.frame.size.height);
}

- (void)viewDidUnload {
    [self setColorsScrollView:nil];
    [self setTitleBarLabel:nil];
    [self setTitleView:nil];
    [self setEditorBackgroundView:nil];
    [super viewDidUnload];
}

- (void)dealloc {
    [colorsScrollView release];
    [titleBarLabel release];
    [titleView release];
    [editorBackgroundView release];
    [super dealloc];
}

@end
