//
//  QIFontSelector.m
//  QuoteIt
//
//  Created by Stephen Poletto on 3/15/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "UIDevice+DETweetComposeViewController.h"
#import "QIFontSelector.h"
#import "QIUtilities.h"

@interface QIFontSelector ()

@end

@implementation QIFontSelector
@synthesize delegate;
@synthesize editorBackgroundView;
@synthesize fontsScrollView;
@synthesize titleView;
@synthesize titleViewLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Choose Font";
        
        CGFloat shiftDownByHeight = ([UIDevice de_isIOS5]) ? 15.0 : 0.0;
        UIBarButtonItem *backItem = [UIBarButtonItem barItemWithImage:[UIImage imageNamed:@"sheet_btn_back_static"] highlightedImage:[UIImage imageNamed:@"sheet_btn_back_active"] title:nil target:self action:@selector(back:) shiftedDownByHeight:shiftDownByHeight];
        self.navigationItem.leftBarButtonItem = backItem;
        
        UIBarButtonItem *doneItem = [UIBarButtonItem barItemWithImage:[UIImage imageNamed:@"sheet_btn_done_static"] highlightedImage:[UIImage imageNamed:@"sheet_btn_done_press"] title:nil target:self action:@selector(done:) shiftedDownByHeight:shiftDownByHeight];
        self.navigationItem.rightBarButtonItem = doneItem;
    }
    return self;
}

- (void)back:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)done:(id)sender {
    if (delegate && [delegate respondsToSelector:@selector(fontSelectorIsDone:)]) {
        [delegate fontSelectorIsDone:self];
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

static NSArray *QIFontSelectorFonts;
- (NSArray *)fonts {
    if (!QIFontSelectorFonts) {
        // Use a mutable array to add each font that exists on the device and avoid an early nil
        // termination if we used initWithObjects:
        NSMutableArray *existentFonts = [NSMutableArray array];
        
        NSArray *fontNames = [NSArray arrayWithObjects:@"AmericanTypewriter", @"HelveticaNeue-Bold", @"ArialRoundedMTBold",
                              @"Baskerville-BoldItalic", @"BodoniSvtyTwoITCTT-Book", @"Chalkduster", @"Cochin", @"Futura-Medium", @"Futura-CondensedExtraBold",
                              @"GeezaPro", @"Georgia", @"Georgia-Italic", @"GillSans-Bold", @"HoeflerText-Regular", @"Noteworthy-Bold", nil];
        for (NSString *fontName in fontNames) {
            UIFont *font = [UIFont fontWithName:fontName size:17.0];
            if (font) {
                [existentFonts addObject:font];
            }
        }
        QIFontSelectorFonts = [[NSArray alloc] initWithArray:existentFonts];
    }
    return QIFontSelectorFonts;
}

- (void)fontSelected:(UIButton *)sender {
    NSInteger fontIndex = sender.tag;
    if (delegate && [delegate respondsToSelector:@selector(fontSelctor:userSelectedFont:)]) {
        [delegate fontSelctor:self userSelectedFont:[[self fonts] objectAtIndex:fontIndex] ];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.titleView.backgroundColor = [UIColor clearColor];
    
    if (![UIDevice de_isIOS5]) {
        CGRect titleFrame = self.titleViewLabel.frame;
        titleFrame.origin.y -= 8;
        self.titleViewLabel.frame = titleFrame;
    }
    
    self.navigationItem.titleView = self.titleView;
    self.titleViewLabel.text = self.title;
    self.titleViewLabel.textColor = [QIUtilities textEditorHeaderLabelColor];
    
    self.fontsScrollView.backgroundColor = [UIColor clearColor];
    CGFloat xOffset = 5.0;
    for (NSInteger i = 0; i < [[self fonts] count]; i++) {
        UIFont *font = [[self fonts] objectAtIndex:i];
        UILabel *fontSwatch = [[UILabel alloc] initWithFrame:CGRectMake(xOffset, 35.0, 130.0, 103.0)];
        
        fontSwatch.backgroundColor = [QIUtilities textEditorFontSelectorBackgroundColor];
        fontSwatch.numberOfLines = 0;
        fontSwatch.font = font;
        fontSwatch.text = QIPrettyFontNameFromFont(font);
        fontSwatch.textAlignment = UITextAlignmentCenter;
        
        xOffset += 135.0;
        
        fontSwatch.layer.cornerRadius = 4.0;
        fontSwatch.layer.borderWidth = 1.0;
        fontSwatch.layer.borderColor = [QIUtilities avatarBorderColor].CGColor;
        fontSwatch.layer.masksToBounds = YES;
        
        UIButton *fontButton = [[UIButton alloc] initWithFrame:fontSwatch.frame];
        fontButton.tag = i;
        [fontButton addTarget:self action:@selector(fontSelected:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.fontsScrollView addSubview:fontSwatch];
        [self.fontsScrollView addSubview:fontButton];
        [fontButton release];
        [fontSwatch release];
    }
    self.fontsScrollView.contentSize = CGSizeMake(xOffset, self.fontsScrollView.frame.size.height);
}

- (void)viewDidUnload {
    [self setTitleView:nil];
    [self setTitleViewLabel:nil];
    [self setEditorBackgroundView:nil];
    [self setFontsScrollView:nil];
    [super viewDidUnload];
}

- (void)dealloc {
    [titleView release];
    [titleViewLabel release];
    [editorBackgroundView release];
    [fontsScrollView release];
    [super dealloc];
}

@end
