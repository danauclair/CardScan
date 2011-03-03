//
//  CardDetailViewController.m
//  CardScan
//
//  Created by Dan Auclair on 1/9/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import "CardDetailViewController.h"
#import "ImageCache.h"
#import "Card.h"
#import <AddressBook/AddressBook.h>
#import <QuartzCore/QuartzCore.h>

@implementation CardDetailViewController

@synthesize currentCard;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	return [self init];
}

- (id)init
{
	[super initWithNibName:@"CardDetailViewController" bundle:nil];
	return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	imageView.layer.masksToBounds = YES;
	imageView.layer.cornerRadius = 5.0;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];

	// release any subviews
	[imageView release];
	imageView = nil;
	
	[contactButton release];
	contactButton = nil;
}

- (void)dealloc
{
	[imageView release];
	[contactButton release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// set the title to the address book name
	self.navigationItem.title = currentCard.name;
	
	// set the image view to the original image from the ImageCache
	if (currentCard.imageKey) {
		imageView.image = [[ImageCache sharedImageCache] imageForKey:currentCard.imageKey];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (IBAction)showContact:(id)sender
{
	ABAddressBookRef book = ABAddressBookCreate();
	ABRecordRef record = ABAddressBookGetPersonWithRecordID(book, currentCard.recordId);
	ABPersonViewController *personViewController = [[ABPersonViewController alloc] init];
	
	personViewController.displayedPerson = record;
	personViewController.allowsEditing = YES;
	personViewController.personViewDelegate = self;
	
	[self.navigationController pushViewController:personViewController animated:YES];
	[personViewController release];
	CFRelease(book);
}

- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifierForValue
{
	return YES;
}

@end
