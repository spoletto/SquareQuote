//
//  CMTextStylePickerViewController.h
//  CMTextStylePicker
//
//  Created by Chris Miles on 18/10/10.
//  Copyright (c) Chris Miles 2010.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <UIKit/UIKit.h>

#import "CMColourSelectTableViewController.h"
#import "CMFontSelectTableViewController.h"
#import "CMUpDownControl.h"


@class CMColourBlockView;
@protocol CMTextStylePickerViewControllerDelegate;

@interface CMTextStylePickerViewController : UIViewController <CMFontSelectTableViewControllerDelegate, CMColourSelectTableViewControllerDelegate> {

}

@property (nonatomic, assign)	id<CMTextStylePickerViewControllerDelegate> delegate;

@property (nonatomic, assign)	BOOL		defaultSettingsSwitchValue;
@property (nonatomic, retain)	UIColor		*selectedTextColour;
@property (nonatomic, retain)	UIFont		*selectedFont;

@property (nonatomic, retain)	IBOutlet	UITableViewCell		*applyAsDefaultCell;
@property (nonatomic, retain)	IBOutlet	UIBarButtonItem		*doneButtonItem;
@property (nonatomic, retain)	IBOutlet	UITableViewCell		*colourCell;
@property (nonatomic, retain)	IBOutlet	CMColourBlockView	*colourView;
@property (nonatomic, retain)	IBOutlet	UITableViewCell		*defaultSettingsCell;
@property (nonatomic, retain)	IBOutlet	UISwitch			*defaultSettingsSwitch;
@property (nonatomic, retain)	IBOutlet	UITableViewCell		*fontCell;
@property (nonatomic, retain)	IBOutlet	UILabel				*fontNameLabel;
@property (nonatomic, retain)	IBOutlet	CMUpDownControl		*fontSizeControl;
@property (nonatomic, retain)	IBOutlet	UITableViewCell		*sizeCell;
@property (retain, nonatomic) IBOutlet UITableView *tableView;

+ (CMTextStylePickerViewController *)textStylePickerViewController;
- (IBAction)doneAction;
- (IBAction)defaultTextSettingsAction:(UISwitch *)defaultSwitch;
- (IBAction)fontSizeValueChanged:(CMUpDownControl *)control;

@end


@protocol CMTextStylePickerViewControllerDelegate <NSObject>
@optional
- (void)textStylePickerViewController:(CMTextStylePickerViewController *)textStylePickerViewController userSelectedFont:(UIFont *)font;
- (void)textStylePickerViewController:(CMTextStylePickerViewController *)textStylePickerViewController userSelectedTextColor:(UIColor *)textColor;

- (void)textStylePickerViewControllerSelectedCustomStyle:(CMTextStylePickerViewController *)textStylePickerViewController;
- (void)textStylePickerViewControllerSelectedDefaultStyle:(CMTextStylePickerViewController *)textStylePickerViewController;

- (void)textStylePickerViewController:(CMTextStylePickerViewController *)textStylePickerViewController replaceDefaultStyleWithFont:(UIFont *)font textColor:(UIColor *)textColor;

- (void)textStylePickerViewControllerIsDone:(CMTextStylePickerViewController *)textStylePickerViewController;
@end
