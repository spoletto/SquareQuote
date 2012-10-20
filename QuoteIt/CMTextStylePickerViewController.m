//
//  CMTextStylePickerViewController.m
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

#import "CMTextStylePickerViewController.h"
#import "CMColourBlockView.h"
#import "CMUpDownControl.h"
#import "QIUtilities.h"

#define kDisabledCellAlpha		0.4


#pragma mark -
#pragma mark Private Interface

@interface CMTextStylePickerViewController ()
@property (nonatomic, retain)	NSArray		*tableLayout;
@end


#pragma mark -
#pragma mark Implementation

@implementation CMTextStylePickerViewController
@synthesize tableView;

@synthesize delegate, defaultSettingsSwitchValue, selectedTextColour, selectedFont;
@synthesize tableLayout, fontSizeControl;
@synthesize sizeCell, colourCell, fontCell, defaultSettingsCell, applyAsDefaultCell, fontNameLabel, defaultSettingsSwitch;
@synthesize colourView, doneButtonItem;

+ (CMTextStylePickerViewController *)textStylePickerViewController {
	CMTextStylePickerViewController *textStylePickerViewController = [[CMTextStylePickerViewController alloc] initWithNibName:@"CMTextStylePickerViewController" bundle:nil];
	return [textStylePickerViewController autorelease];
}

- (void)notifyDelegateSelectedFontChanged {
	if (delegate && [delegate respondsToSelector:@selector(textStylePickerViewController:userSelectedFont:)]) {
		[delegate textStylePickerViewController:self userSelectedFont:self.selectedFont];
	}
}

- (void)notifyDelegateSelectedTextColorChanged {
	if (delegate && [delegate respondsToSelector:@selector(textStylePickerViewController:userSelectedTextColor:)]) {
		[delegate textStylePickerViewController:self userSelectedTextColor:self.selectedTextColour];
	}
}

- (void)enableTextOptionCells {
	// Undo the "disabled" look and enable user interaction
	[UIView beginAnimations:nil context:NULL];
	
	for (UITableViewCell *cell in [self.tableLayout objectAtIndex:1]) {
		cell.userInteractionEnabled = YES;
		if (cell != self.sizeCell) {
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		
		cell.contentView.alpha = 1.0;
	}
	
	self.applyAsDefaultCell.contentView.alpha = 1.0;
	self.applyAsDefaultCell.userInteractionEnabled = YES;
	
	[UIView commitAnimations];
}

- (void)disableTextOptionCells {
	// Make cells look "disabled" and disable user interaction
	[UIView beginAnimations:nil context:NULL];
	
	for (UITableViewCell *cell in [self.tableLayout objectAtIndex:1]) {
		cell.userInteractionEnabled = NO;
		cell.accessoryType = UITableViewCellAccessoryNone;
		
		cell.contentView.alpha = kDisabledCellAlpha;
	}
	
	self.applyAsDefaultCell.contentView.alpha = kDisabledCellAlpha;
	self.applyAsDefaultCell.userInteractionEnabled = NO;
	
	[UIView commitAnimations];
}

- (void)replaceDefaultSettings {
	if (delegate && [delegate respondsToSelector:@selector(textStylePickerViewController:replaceDefaultStyleWithFont:textColor:)]) {
		[delegate textStylePickerViewController:self replaceDefaultStyleWithFont:self.selectedFont textColor:self.selectedTextColour];
	}
	
	self.defaultSettingsSwitchValue = YES;
	[self.defaultSettingsSwitch setOn:YES animated:YES];
	[self disableTextOptionCells];
}

- (void)updateFontColourSelections {
	self.fontNameLabel.text = selectedFont.fontName;
	self.fontSizeControl.value = selectedFont.pointSize;
    [self.fontSizeControl setNeedsDisplay];
}

- (IBAction)doneAction {
	if (delegate && [delegate respondsToSelector:@selector(textStylePickerViewControllerIsDone:)]) {
		[delegate textStylePickerViewControllerIsDone:self];
	}
}

- (IBAction)defaultTextSettingsAction:(UISwitch *)defaultSwitch {
	self.defaultSettingsSwitchValue = defaultSwitch.on;
		
	if (self.defaultSettingsSwitchValue) {
		// Use default text style
		if (delegate && [delegate respondsToSelector:@selector(textStylePickerViewControllerSelectedDefaultStyle:)]) {
			[delegate textStylePickerViewControllerSelectedDefaultStyle:self];
		}
		[self disableTextOptionCells];
	}
	else {
		// Use custom text style
		if (delegate && [delegate respondsToSelector:@selector(textStylePickerViewControllerSelectedCustomStyle:)]) {
			[delegate textStylePickerViewControllerSelectedCustomStyle:self];
		}
		[self enableTextOptionCells];
	}
	
	[self updateFontColourSelections];
}

- (void)setSelectedFont:(UIFont *)selectedFontIn {
    [selectedFont release];
    selectedFont = [selectedFontIn retain];
    [self updateFontColourSelections];
    [self.tableView reloadData];
}

- (void)setSelectedTextColour:(UIColor *)selectedTextColourIn {
    [selectedTextColour release];
    selectedTextColour = [selectedTextColourIn retain];
    [self.tableView reloadData];
}

- (IBAction)fontSizeValueChanged:(CMUpDownControl *)control {
	CGFloat size = (CGFloat)control.value;
	UIFont *textFont = [UIFont fontWithName:self.selectedFont.fontName size:size];
	self.selectedFont = textFont;
	
	[self notifyDelegateSelectedFontChanged];
}


#pragma mark  -
#pragma mark ColourSelectTableViewControllerDelegate methods

- (void)colourSelectTableViewController:(CMColourSelectTableViewController *)colourSelectTableViewController didSelectColour:(UIColor *)colour {
	self.selectedTextColour = colour;
	self.colourView.colour = colour;	// Update the colour swatch
	[self notifyDelegateSelectedTextColorChanged];
}


#pragma mark -
#pragma mark FontSelectTableViewControllerDelegate methods

- (void)fontSelectTableViewController:(CMFontSelectTableViewController *)fontSelectTableViewController didSelectFont:(UIFont *)textFont {
	self.selectedFont = textFont;
	self.fontNameLabel.text = [textFont fontName];
	[self notifyDelegateSelectedFontChanged];
}


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

	self.title = @"Text Style";
    QIRenderNavigationBarTitle();
		
	self.fontSizeControl.minimumAllowedValue = 8;
	self.fontSizeControl.maximumAllowedValue = 72;
	
	[self updateFontColourSelections];
	
	self.tableLayout = [NSArray arrayWithObjects:
						//[NSArray arrayWithObjects:
						// self.defaultSettingsCell,
						// nil],
						[NSArray arrayWithObjects:
						 self.sizeCell,
						 self.fontCell,
						 self.colourCell,
						 nil],
						//[NSArray arrayWithObjects:
						// self.applyAsDefaultCell,
						// nil],
						nil];
    [self.tableView reloadData];
	
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		// iPhone UI
		self.navigationItem.rightBarButtonItem = self.doneButtonItem;
	}
	else {
		// iPad UI
		self.contentSizeForViewInPopover = CGSizeMake(320.0, 330.0);
	}
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Set the frame size
    CGRect frame = self.view.frame;
    frame.size.height = 210;
    self.view.frame = frame;
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return YES;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [tableLayout count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [[tableLayout objectAtIndex:section] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    static NSString *CellIdentifier = @"Cell";
//    
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    if (cell == nil) {
//        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
//    }
    
    UITableViewCell *cell = [[tableLayout objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [[tableLayout objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	return cell.bounds.size.height;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *selectedIndexPath = indexPath;
	UITableViewCell *cell = [[tableLayout objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	
	if (cell == self.sizeCell || cell == self.defaultSettingsCell) {
		// Disable selection of cell
		selectedIndexPath = nil;
	}
	
	return selectedIndexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [[tableLayout objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	
	if (cell == self.fontCell) {
		CMFontSelectTableViewController *fontSelectTableViewController = [[CMFontSelectTableViewController alloc] initWithNibName:@"CMFontSelectTableViewController" bundle:nil];
		fontSelectTableViewController.delegate = self;
		fontSelectTableViewController.selectedFont = self.selectedFont;
		[self.navigationController pushViewController:fontSelectTableViewController animated:YES];
		[fontSelectTableViewController release];
	}
	else if (cell == self.colourCell) {
		CMColourSelectTableViewController *colourSelectTableViewController = [[CMColourSelectTableViewController alloc] initWithNibName:@"CMColourSelectTableViewController" bundle:nil];
		colourSelectTableViewController.delegate = self;
		colourSelectTableViewController.selectedColour = self.selectedTextColour;
		[self.navigationController pushViewController:colourSelectTableViewController animated:YES];
		[colourSelectTableViewController release];
	}
	else if (cell == self.applyAsDefaultCell) {
		// "Replace default settings"
		[self replaceDefaultSettings];
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (cell == self.colourCell) {
		self.colourView.colour = self.selectedTextColour;
	}

	if (self.defaultSettingsSwitchValue == NO) {
		// Custom text style is active
		if (cell == self.defaultSettingsCell) {
			self.defaultSettingsSwitch.on = NO;
		}
		else {
			cell.contentView.alpha = 1.0;
			cell.userInteractionEnabled = YES;
		}

	}
	else {
		// Text style is default
		if (cell == self.defaultSettingsCell) {
			self.defaultSettingsSwitch.on = YES;
		}
		else {
			cell.contentView.alpha = kDisabledCellAlpha;
			cell.userInteractionEnabled = NO;
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	}
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [self setTableView:nil];
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
	
	self.applyAsDefaultCell = nil;
	self.colourCell = nil;
	self.colourView = nil;
	self.defaultSettingsCell = nil;
	self.defaultSettingsSwitch = nil;
	self.doneButtonItem = nil;
	self.fontCell = nil;
	self.fontNameLabel = nil;
	self.fontSizeControl = nil;
	self.sizeCell = nil;
}


- (void)dealloc {
	[applyAsDefaultCell release];
	[colourCell release];
	[colourView release];
	[defaultSettingsCell release];
	[defaultSettingsSwitch release];
	[doneButtonItem release];
	[fontCell release];
	[fontNameLabel release];
	[fontSizeControl release];
	[selectedTextColour release];
	[selectedFont release];
	[sizeCell release];
	[tableLayout release];
	
    [tableView release];
    [super dealloc];
}


@end

