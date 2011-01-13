//
//  CardScanViewController.h
//  CardScan
//
//  Created by Dan Auclair on 1/8/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>

@class TesseractEngine;
@class CardDetailViewController;
@class Card;

@interface CardScanViewController : UITableViewController <UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, ABNewPersonViewControllerDelegate> {
	TesseractEngine *tesseractEngine;
	NSMutableArray *cards;
	NSString *currentImageKey;
	CardDetailViewController *detailViewController;
	Card *deleteCard;
}

@property (nonatomic, retain) NSMutableArray *cards;

-(IBAction)selectImage:(id)sender;

@end
