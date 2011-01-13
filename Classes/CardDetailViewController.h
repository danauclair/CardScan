//
//  CardDetailViewController.h
//  CardScan
//
//  Created by Dan Auclair on 1/9/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>

@class Card;

@interface CardDetailViewController : UIViewController <ABPersonViewControllerDelegate> {
	IBOutlet UIImageView *imageView;
	IBOutlet UIButton *contactButton;
	Card *currentCard;
}

@property (nonatomic, retain) Card *currentCard;

- (IBAction)showContact:(id)sender;

@end
