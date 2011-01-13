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

// "private" methods
@interface CardScanViewController()

-(void)showNewPerson:(NSString *)text;
-(void)displayImagePickerWithSource:(UIImagePickerControllerSourceType)src;
-(UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;

@end

@implementation CardScanViewController

@synthesize cards;

- (id)init
{
	// call the superclass's designated initializer
	[super initWithStyle:UITableViewStyleGrouped];
	
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	
	UIBarButtonItem *cameraBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(selectImage:)];
	self.navigationItem.rightBarButtonItem = cameraBarButtonItem;
	[cameraBarButtonItem release];
	
	// initialize tesseract engine
	tesseractEngine = [[TesseractEngine alloc] init];
	cards = [[NSMutableArray alloc] init];
	
	self.navigationItem.title = @"Card Scan";
	self.tableView.rowHeight = 80.0;
	
	return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
	return [self init];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc {
	[tesseractEngine release];
	[cards release];
    [super dealloc];
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

- (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;
{
    float aspect = image.size.height / image.size.width;
    float aspectHeight = newSize.width * aspect;
    CGSize ratioSize = CGSizeMake(newSize.width, aspectHeight);
    UIGraphicsBeginImageContext(ratioSize);
    [image drawInRect:CGRectMake(0,0,ratioSize.width,ratioSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
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
		if (buttonIndex < 2) {
			if (buttonIndex == 0) {
				// need to also delete the cooresponding address book record
				ABAddressBookRef book = ABAddressBookCreate();
				ABRecordRef person = ABAddressBookGetPersonWithRecordID(book, deleteCard.recordId);
				
				if (person != NULL) {
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

		[deleteCard release];
	}
}

-(void) displayImagePickerWithSource:(UIImagePickerControllerSourceType)sourceType;
{
    if([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
		imagePicker.sourceType = sourceType;
        imagePicker.delegate = self;
		
        // 3.0/3.1 allowsEditing compatibility
		NSString *key = @"allowsEditing";
		if ([imagePicker respondsToSelector:@selector(setAllowsImageEditing:)]) {
			key = @"allowsImageEditing";
		}
		[imagePicker setValue:[NSNumber numberWithBool:YES] forKey:key];
		
        [self presentModalViewController:imagePicker animated:YES];
        [imagePicker release];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
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
	
	[DSBezelActivityView newActivityViewForView:self.view withLabel:@"Processing Image..."];
}

- (void)processImage:(UIImage *)image 
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	// resize, so as to not choke tesseract:
    // scaling up a low resolution image (eg. screenshots) seems to help the recognition.
    // 1200 pixels is an arbitrary value, but seems to work well.
    CGFloat newWidth = 1200;
    CGSize newSize = CGSizeMake(newWidth, newWidth);
	
    image = [image resizedImage:newSize interpolationQuality:kCGInterpolationHigh];
    
    NSString *text = [tesseractEngine readAndProcessImage:image];
	NSLog(@"Original OCR Text:\n%@", text);
    
    [self performSelectorOnMainThread:@selector(showNewPerson:) withObject:text waitUntilDone:NO];
    
    [pool release];
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

@end