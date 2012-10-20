//
//  QIQuoteEditor.h
//  QuoteIt
//
//  Created by Stephen Poletto on 1/2/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import "QIChooseQuotePhoto.h"
#import "QIFacebookConnect.h"
#import "QIQuoteEditorView.h"
#import "QITextEditor.h"

@interface QIQuoteEditor : UIViewController <QIChoosePhotoDelegate, UIGestureRecognizerDelegate, QIQuoteEditorViewDelegate, QITextEditorDelegate> {    
    QIChooseQuotePhoto *choosePhoto; // Save this for subsequent photo selections.
    BOOL userHasSetPhoto;
    
    UITapGestureRecognizer *privacyPopupDismissRecognizer;
    SPUserResizableView *selectedResizableView;
    
    UINavigationController *fontEditorNavigationController;
    
    NSString *privacyString;
    BOOL editTextButtonShouldBeEnabled;
    BOOL loading;
    
    UIImageView *overlayView;
    UIImage *memoryWarningCachedImage;
}

@property (retain, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (retain, nonatomic) IBOutlet QIQuoteEditorView *quoteEditor;
@property (retain, nonatomic) IBOutlet UIButton *choosePhotoButton;
@property (retain, nonatomic) IBOutlet UIButton *postQuoteButton;
@property (retain, nonatomic) IBOutlet UIButton *editTextButton;
@property (retain, nonatomic) IBOutlet UIButton *privacyButton;

@property (retain, nonatomic) IBOutlet UIView *privacyPopup;
@property (retain, nonatomic) IBOutlet UIImageView *popupBackground;

@property (retain, nonatomic) NSDictionary *quoteSource;
@property (retain, nonatomic) NSDictionary *quoteTopic;
@property (retain, nonatomic) NSString *quoteText;
@property (retain, nonatomic) NSString *editorImageURL;

- (void)setEditorImageURL:(NSString *)editorImageURLIn onlyIfNil:(BOOL)onlyIfNil;

@end
