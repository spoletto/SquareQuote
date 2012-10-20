//
//  QIColorSelector.m
//  QuoteIt
//
//  Created by Stephen Poletto on 3/15/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "UIDevice+DETweetComposeViewController.h"
#import "QIColorSelector.h"
#import "QIUtilities.h"

@interface QIColorSelector ()

@end

@implementation QIColorSelector
@synthesize delegate;
@synthesize editorBackgroundView;
@synthesize colorsScrollView;
@synthesize titleView;
@synthesize titleBarLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Text Color";
        
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
                                 [UIColor whiteColor], UIColorFromRGB(0xe44209),
                                 UIColorFromRGB(0x1bfbde), UIColorFromRGB(0x182541),
                                 UIColorFromRGB(0x6bd0ff), UIColorFromRGB(0xb1ff77),
                                 UIColorFromRGB(0xfee74f), UIColorFromRGB(0xfff5d6),
                                 UIColorFromRGB(0x3a2b67), UIColorFromRGB(0xff003c), nil];
    }
    return QIColorSelectorColors;
}

- (void)back:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)done:(id)sender {
    if (delegate && [delegate respondsToSelector:@selector(colorSelectorIsDone:)]) {
        [delegate colorSelectorIsDone:self];
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
    if (delegate && [delegate respondsToSelector:@selector(colorSelctor:userSelectedTextColor:)]) {
        [delegate colorSelctor:self userSelectedTextColor:[[self colors] objectAtIndex:colorIndex]];
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
    CGFloat xOffset = 5.0;
    for (NSInteger i = 0; i < [[self colors] count]; i++) {
        UIColor *color = [[self colors] objectAtIndex:i];
        UIView *colorSwatch = [[UIView alloc] initWithFrame:CGRectMake(xOffset, 35.0, 65.0, 103.0)];
        xOffset += 70.0;
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
