//
//  QIChooseQuotePhoto.m
//  QuoteIt
//
//  Created by Stephen Poletto on 2/1/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import "QIChooseQuotePhoto.h"
#import "QITemplatePhotos.h"
#import "QITaggedPhotos.h"
#import "QIPhotoSearch.h"
#import "QIUtilities.h"

#define kQITemplatesIndex 0
#define kQITakePhotoIndex 1
#define kQITaggedPhotosIndex 2

@interface QIChooseQuotePhoto ()
- (NSArray *)tabBarControllerContent;
@end

@implementation QIChooseQuotePhoto
@synthesize backgroundImage;
@synthesize quoteSource;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UIBarButtonItem *backItem = [UIBarButtonItem barItemWithImage:[QIUtilities backButtonImage] highlightedImage:[QIUtilities backButtonPressed] title:@"  Back" target:self action:@selector(back:)];
        self.navigationItem.leftBarButtonItem = backItem;
        self.title = @"Choose Photo";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    QIRenderNavigationBarTitle();
    [backgroundImage setImage:[QIUtilities bookImage]];
    
    customTabBar = [[CustomTabBar alloc] initWithItemCount:[[self tabBarControllerContent] count] itemSize:CGSizeMake(self.view.frame.size.width/[self tabBarControllerContent].count, 50) tag:0 delegate:self];
    
    // Place the tab bar at the bottom of our view
    customTabBar.frame = CGRectMake(0, self.view.frame.size.height-50, self.view.frame.size.width, 50);
    [self.view addSubview:customTabBar];
    [customTabBar selectItemAtIndex:0];
    [self touchDownAtItemAtIndex:0];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (void)hideOverlayView:(BOOL)animated {
    if (!animated) {
        [overlayView removeFromSuperview];
        [overlayView release];
        overlayView = nil;
        self.navigationItem.leftBarButtonItem.enabled = YES;
        selectedViewController.view.userInteractionEnabled = YES;
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            overlayView.alpha = 0.0;  
        } completion:^(BOOL completed) {
            [overlayView removeFromSuperview];
            [overlayView release];
            overlayView = nil;
            self.navigationItem.leftBarButtonItem.enabled = YES;
            selectedViewController.view.userInteractionEnabled = YES;
        }];
    }
}

- (void)showOverlayViewWithImageNamed:(NSString *)imageName {
    [self hideOverlayView:NO]; // Ensure no existing overlay view.
    overlayView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    CGRect hack = overlayView.frame;
    hack.origin.y += 20; // Accomodate the status bar.
    overlayView.frame = hack;
    [self.navigationController.view addSubview:overlayView];
    self.navigationItem.leftBarButtonItem.enabled = NO;
    selectedViewController.view.userInteractionEnabled = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:QIHasSeenPhotoSelectorOptions]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:QIHasSeenPhotoSelectorOptions];
        [self showOverlayViewWithImageNamed:@"ol_ChooseBackground"];
    }
}

- (void)back:(id)sender {
    [QIUtilities navigationControllerPopViewControllerWithPageCurlTransition:super.navigationController];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSUInteger sourceType = 0;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        switch (buttonIndex) {
            case 0:
                sourceType = UIImagePickerControllerSourceTypeCamera;
                break;
            case 1:
                sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                break;
            case 2:
                return;
        }
    } else {
        if (buttonIndex == 1) {
            return;
        } else {
            sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        }
    }
    
	UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
	imagePickerController.delegate = self;
	imagePickerController.allowsEditing = YES;
    imagePickerController.sourceType = sourceType;
	[self presentModalViewController:imagePickerController animated:YES];
}


#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info  {
	[picker dismissModalViewControllerAnimated:YES];
    
    UIImage *photo = [info objectForKey:UIImagePickerControllerEditedImage];
    UIImage *downsizedPhoto = [UIImage scale:photo toFillSize:CGSizeMake(588, 588)];
    if ([self.delegate respondsToSelector:@selector(userDidSelectPhotoImage:)]) {
        [self.delegate userDidSelectPhotoImage:downsizedPhoto];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[self dismissModalViewControllerAnimated:YES];
}

- (void)cameraIconPressed {
    UIActionSheet *choosePhotoActionSheet;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        choosePhotoActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Photo"
                                                             delegate:self 
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Take Photo", @"Choose From Library", nil];
    } else {
        choosePhotoActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Photo"
                                                             delegate:self 
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Choose From Library", nil];
    }
    [choosePhotoActionSheet showInView:self.view];
    [choosePhotoActionSheet release];
}

- (UIImage *)selectedItemBackgroundImage {
    return nil;
}

- (UIImage *)tabBarArrowImage {
    return nil;
}

- (UIImage *)selectedItemImage {
    return nil;
}

- (UIImage *)backgroundImage {
    return [UIImage imageNamed:@"_Tab_Bar"];
}

- (UIImage *)glowImage {
    return nil;
}

- (UIImage *)imageForButtonAtIndex:(NSUInteger)itemIndex {
    UIImage *image = nil;
    switch (itemIndex) {
        case kQITakePhotoIndex:
            image = [UIImage imageNamed:@"btn_capture_static"];
            break;
        case kQITaggedPhotosIndex:
            image = [UIImage imageNamed:@"fb_icon_static"];
            break;
        case kQITemplatesIndex:
            image = [UIImage imageNamed:@"templates_icon_static"];
            break;
        default:
            break;
    }
    return image;
}

- (UIImage *)imageFor:(CustomTabBar *)tabBar atIndex:(NSUInteger)itemIndex {
    return [self imageForButtonAtIndex:itemIndex];
}

- (UIImage *)selectedImageForButtonAtIndex:(NSUInteger)itemIndex {
    UIImage *image = nil;
    switch (itemIndex) {
        case kQITakePhotoIndex:
            image = [UIImage imageNamed:@"btn_capture_static"];
            break;
        case kQITaggedPhotosIndex:
            image = [UIImage imageNamed:@"fb_icon_press"];
            break;
        case kQITemplatesIndex:
            image = [UIImage imageNamed:@"templates_icon_press"];
            break;
        default:
            break;
    }
    return image;
}

- (void)presentViewControllerForItemAtIndex:(NSUInteger)itemIndex {
    // Remove the current view controller's view
    [selectedViewController viewWillDisappear:NO];
    [selectedViewController.view removeFromSuperview];
    [selectedViewController viewDidDisappear:NO];
    
    if (itemIndex != kQITakePhotoIndex) {
        // Get the right view controller
        UIViewController *viewController = [[self tabBarControllerContent] objectAtIndex:itemIndex];
        
        // Set the view controller's frame to account for the tab bar
        viewController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-50);
        
        selectedViewController = viewController;
        
        // Add the new view controller's view
        [viewController viewWillAppear:NO];
        [self.view insertSubview:viewController.view belowSubview:customTabBar];
        [viewController viewDidAppear:NO];
    }
    
    if (selectedButton) {
        UIImage *unselectedImage = [self imageForButtonAtIndex:[[customTabBar buttons] indexOfObject:selectedButton]];
        [selectedButton setImage:unselectedImage forState:UIControlStateNormal];
        [selectedButton setImage:unselectedImage forState:UIControlStateHighlighted];
        [selectedButton setImage:unselectedImage forState:UIControlStateSelected];
    }
    
    UIImage *selectedImage = [self selectedImageForButtonAtIndex:itemIndex];
    selectedButton = [[customTabBar buttons] objectAtIndex:itemIndex];
    [selectedButton setImage:selectedImage forState:UIControlStateNormal];
    [selectedButton setImage:selectedImage forState:UIControlStateHighlighted];
    [selectedButton setImage:selectedImage forState:UIControlStateSelected];
}

- (void)touchDownAtItemAtIndex:(NSUInteger)itemIndex {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:QIHasSeenPhotoSelectorOptions]) {
        [self hideOverlayView:YES];
    }
    if (itemIndex == kQITakePhotoIndex) {
        [TestFlight passCheckpoint:@"Photo Selection -- Take Photo"];
        [self cameraIconPressed];
    } else if (itemIndex == kQITemplatesIndex) {
        [TestFlight passCheckpoint:@"Photo Selection -- Template Photos"];
        [self presentViewControllerForItemAtIndex:itemIndex];
    } else if (itemIndex == kQITaggedPhotosIndex) {
        [TestFlight passCheckpoint:@"Photo Selection -- Tagged Photos"];
        [self presentViewControllerForItemAtIndex:itemIndex];
    }
}

- (void)setQuoteSource:(NSDictionary *)quoteSourceIn {
    if (quoteSourceIn != quoteSource) {
        [quoteSource release];
        quoteSource = [quoteSourceIn retain];
    
        QITaggedPhotos *taggedPhotos = [[self tabBarControllerContent] objectAtIndex:kQITaggedPhotosIndex];
        taggedPhotos.quoteSource = quoteSource;
    }
}

- (NSArray *)tabBarControllerContent {
    if (!tabBarControllerContent) {
        QITaggedPhotos *taggedPhotos = [[[QITaggedPhotos alloc] init] autorelease];
        QITemplatePhotos *templatePhotos = [[[QITemplatePhotos alloc] init] autorelease];
        //QIPhotoSearch *photoSearch = [[[QIPhotoSearch alloc] init] autorelease];
        
        // Forward image selection messages up to our delegate.
        taggedPhotos.delegate = self.delegate;
        templatePhotos.delegate = self.delegate;
        //photoSearch.delegate = self.delegate;
        
        taggedPhotos.quoteSource = quoteSource;
        
        NSArray *controllers = [[NSArray alloc] initWithObjects:templatePhotos, [NSNull null], taggedPhotos, nil];
        tabBarControllerContent = controllers;
    }
    return tabBarControllerContent;
}

- (void)dealloc {
    [backgroundImage release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setBackgroundImage:nil];
    [super viewDidUnload];
}

@end
