//
//  QIShareQuote.h
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import "QISourceSelection.h"
#import "QIFacebookConnect.h"
#import "QIChooseTopic.h"

@class UIPlaceholderTextView, QIQuoteEditor;

@interface QIShareQuote : UIViewController <QISourceSelectionDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, QIChooseTopicDelegate> {
    NSDictionary *selectedSource;
    NSDictionary *selectedTopic;
    
    NSString *profilePictureURL;
    QIQuoteEditor *editor;
    
    NSString *memoryWarningCachedQuoteText;
}

@property (retain, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (retain, nonatomic) IBOutlet UIButton *nextButton;
@property (retain, nonatomic) IBOutlet UIPlaceholderTextView *quoteTextView;
@property (retain, nonatomic) IBOutlet UIButton *chooseSourceButton;
@property (retain, nonatomic) IBOutlet UIButton *chooseTopicButton;
@property (retain, nonatomic) IBOutlet UIImageView *sourcePhoto;
@property (retain, nonatomic) IBOutlet UILabel *sourceName;

@property (retain, nonatomic) IBOutlet UILabel *whatWasSaidLabel;
@property (retain, nonatomic) IBOutlet UILabel *whoSaidItLabel;
@property (retain, nonatomic) IBOutlet UILabel *regardingLabel;

@property (retain, nonatomic) IBOutlet UIView *whoContainingView;
@property (retain, nonatomic) IBOutlet UIView *regardingContainingView;
@property (retain, nonatomic) IBOutlet UILabel *regardingFormFieldLabel;

@property (retain, nonatomic) IBOutlet UIImageView *textViewBackground;
@property (retain, nonatomic) IBOutlet UIImageView *whoSaidItImage;
@property (retain, nonatomic) IBOutlet UIImageView *whatWasItRegardingImage;


@end
