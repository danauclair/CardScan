//
//  CardScanViewController.m
//  CardScan
//
//  Created by Dan Auclair on 1/8/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import "CardScanViewController.h"
#import "CardDetailViewController.h"
#import "CardParser.h"
#import "Card.h"
#import "CardCell.h"
#import "TesseractEngine.h"
#import "UIImage+Resize.h"
#import "RegexKitLite.h"
#import "DSActivityView.h"
#import <AddressBook/AddressBook.h>
#import "ImageCache.h"
#import "NewPersonViewController.h"

// enum used to distinguish between action sheets
enum {
	ActionSheetSelectImage = 0,
	ActionSheetConfirmDelete = 1
}; typedef NSUInteger ActionSheetType;

// interface for "private" methods
@interface CardScanViewController()
-(void)showNewPerson:(NSString *)text;
-(void)displayImagePickerWithSource:(UIImagePickerControllerSourceType)src;
@end

@implementation CardScanViewController

@synthesize cards;

- (id)init
{
	// init the super UITableView with grouped style
	[super initWithStyle:UITableViewStyleGrouped];
	
	// make the leftBarButtonItem the "edit" button for the UITableView
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	
	// create a new camera icon button for the rightBarButtonItem, and hook it up to the selectImage: selector
	UIBarButtonItem *cameraBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(selectImage:)];
	self.navigationItem.rightBarButtonItem = cameraBarButtonItem;
	[cameraBarButtonItem release];
	
	// initialize tesseract engine
	tesseractEngine = [[TesseractEngine alloc] init];
	
	// initialize an empty cards array
	cards = [[NSMutableArray alloc] init];
	
	// set the main view title, which shows up in the UINavgiationController
	self.navigationItem.title = @"Card Scan";
	
	return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
	return [self init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)dealloc {
	[tesseractEngine release];
	[cards release];
    [super dealloc];
}

- (IBAction)selectImage:(id)sender
{
	// if camera is available on the device, show a UIActionSheet to select either camera or photo library
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select Image Source"
																 delegate:self 
														cancelButtonTitle:@"Cancel" 
												   destructiveButtonTitle:nil
														otherButtonTitles:@"Camera",@"Photo Library", nil];
		actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
		
		// set the tag of the action sheet to ActionSheetSelectImage to distinguish between SelectImage/ConfirmDelete action sheets
		actionSheet.tag = ActionSheetSelectImage;
		[actionSheet showInView:self.view];
        [actionSheet release];
    } else {
		// no camera, just display a modal UIImagePicker with the photo library
        [self displayImagePickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex;
{
	if (actionSheet.tag == ActionSheetSelectImage) {
		// action sheet for "Select Image Source"
		switch (buttonIndex) {
			case 0: // camera
				[self displayImagePickerWithSource:UIImagePickerControllerSourceTypeCamera];
				break;
			case 1: // photo library
				[self displayImagePickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
				break;
			case 2: // cancel
			default:
				break;
		}
	} else if (actionSheet.tag == ActionSheetConfirmDelete) {
		// action sheet for "Also Delete Address Book Contact?"
		if (buttonIndex < 2) {
			if (buttonIndex == 0) {
				// need to also delete the cooresponding address book record
				ABAddressBookRef book = ABAddressBookCreate();
				ABRecordRef person = ABAddressBookGetPersonWithRecordID(book, deleteCard.recordId);
				
				if (person != NULL) {
					// remove the ABRecordRef from the address book and save it
					ABAddressBookRemoveRecord(book, person, NULL);
					ABAddressBookSave(book, NULL);
				}
				
				CFRelease(book);
			}
			
			// delete the row in the table view
			int index = [cards indexOfObject:deleteCard];
			[cards removeObjectAtIndex:index];
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
			
			// delete from the ImageCache (which will remove the image from the file system)
			[[ImageCache sharedImageCache] deleteImageForKey:[deleteCard imageKey]];
		}
		
		// no longer need this reference
		[deleteCard release];
		deleteCard = nil;
	}
}

-(void) displayImagePickerWithSource:(UIImagePickerControllerSourceType)sourceType;
{
	// sanity check to make sure we have the sourceType for the current device
    if([UIImagePickerController isSourceTypeAvailable:sourceType]) {
		// create a new UIImagePickerController with appropriate sourceType (i.e. Camera or Photo Library)
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
		imagePicker.sourceType = sourceType;
        imagePicker.delegate = self;
		
        // 3.0/3.1 allowsEditing compatibility for API change
		NSString *key = @"allowsEditing";
		if ([imagePicker respondsToSelector:@selector(setAllowsImageEditing:)]) {
			key = @"allowsImageEditing";
		}
		[imagePicker setValue:[NSNumber numberWithBool:YES] forKey:key];
		
		// present the UIImagePickerController as a modal view
        [self presentModalViewController:imagePicker animated:YES];
        [imagePicker release];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	// dismiss the modal image picker view
    [self dismissModalViewControllerAnimated:YES];
	
	// create a unique ID to use as the image key
	CFUUIDRef newUniqueID = CFUUIDCreate(kCFAllocatorDefault);
	CFStringRef	newUniqueIDString = CFUUIDCreateString(kCFAllocatorDefault, newUniqueID);
	currentImageKey = (NSString *)newUniqueIDString;
	[currentImageKey retain];
	CFRelease(newUniqueIDString);
	CFRelease(newUniqueID);
	
	// store the image in the ImageCache with the key
	UIImage *croppedImage = [[info objectForKey:UIImagePickerControllerEditedImage] retain];
	[[ImageCache sharedImageCache] setImage:croppedImage forKey:currentImageKey];
	
    // process image in new thread
	[NSThread detachNewThreadSelector:@selector(processImage:) toTarget:self withObject:croppedImage];
	[croppedImage release];
	
	// throw up a "Processing Image..." activity bezel while we wait
	[DSBezelActivityView newActivityViewForView:self.view withLabel:@"Processing Image..."];
}

- (void)processImage:(UIImage *)image 
{
	// this is happening on a separate thread, create a new NSAutoreleasePool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// resize the selected image to 1200 x 1200 pixel which helps with tesseract recognition
    CGFloat newWidth = 1200;
    CGSize newSize = CGSizeMake(newWidth, newWidth);
    image = [image resizedImage:newSize interpolationQuality:kCGInterpolationHigh];
    
	// calling this on TesseractEngine will take a long time...
    NSString *text = [tesseractEngine readAndProcessImage:image];
	NSLog(@"Original OCR Text:\n%@", text);
    
	// call the showNewPerson: selector with the output text back on the main thread
    [self performSelectorOnMainThread:@selector(showNewPerson:) withObject:text waitUntilDone:NO];
    
    [pool release];
}

-(void)showNewPerson:(NSString *)text;
{
	CardParser *cardParser = [[CardParser alloc] initWithText:text];
	
	ABRecordRef ocrPerson = [cardParser parsedABRecordRef];
	
	// add the original biz card image to the address book record
	ABPersonSetImageData(ocrPerson, (CFDataRef)UIImageJPEGRepresentation([[ImageCache sharedImageCache] imageForKey:currentImageKey], 1.0f), NULL);
	
	NewPersonViewController *newPersonViewController = [[NewPersonViewController alloc] init];
	newPersonViewController.displayedPerson = ocrPerson;
	newPersonViewController.newPersonViewDelegate = self;
	
	UINavigationController *personNav = [[UINavigationController alloc] initWithRootViewController:newPersonViewController];
	
	newPersonViewController.navigationController.toolbar.barStyle = UIBarStyleBlack;
	
	[DSBezelActivityView removeViewAnimated:YES];
	
	[self presentModalViewController:personNav animated:YES];
	
	[newPersonViewController release];
	[personNav release];
	[cardParser release];
}

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonViewController didCompleteWithNewPerson:(ABRecordRef)person
{
	[self dismissModalViewControllerAnimated:YES];
	
	if (person != NULL) {
		// add a new card for the person
		Card *c = [[Card alloc] initWithRecordId:ABRecordGetRecordID(person)];
		c.imageKey = currentImageKey;
		[c setThumbnailDataFromImage:[[ImageCache sharedImageCache] imageForKey:currentImageKey]];
		[cards addObject:c];
		
		[c release];
		[currentImageKey release];

		[self.tableView reloadData];
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [cards count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CardCell *cell = (CardCell *)[tableView dequeueReusableCellWithIdentifier:@"CardCell"];
	
	if (!cell) {
		cell = [[[CardCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CardCell"] autorelease];
	}

	[cell setCard:[cards objectAtIndex:indexPath.row]];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		deleteCard = [[cards objectAtIndex:[indexPath row]] retain];
		
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Also Delete Address Book Contact?"
																 delegate:self 
														cancelButtonTitle:@"Cancel" 
												   destructiveButtonTitle:@"Yes"
														otherButtonTitles:@"No", nil];
		actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
		actionSheet.tag = ActionSheetConfirmDelete;
		[actionSheet showInView:self.view];
        [actionSheet release];
	}
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
	Card *movedCard = [[cards objectAtIndex:[fromIndexPath row]] retain];
	[cards removeObjectAtIndex:[fromIndexPath row]];
	[cards insertObject:movedCard atIndex:[toIndexPath row]];
	[movedCard release];
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!detailViewController) {
		detailViewController = [[CardDetailViewController alloc] init];
	}
	
	detailViewController.currentCard = [cards objectAtIndex:[indexPath row]];	
	
	// push the detail view controller onto the top of the navigation controller's stack
	[self.navigationController pushViewController:detailViewController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 80.0;
}

@end