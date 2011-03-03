//
//  Card.m
//  CardScan
//
//  Created by Dan Auclair on 1/9/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import "Card.h"
#import "UIImage+RoundedCorner.h"
#import <AddressBook/AddressBook.h>

@implementation Card

@synthesize imageKey, recordId;

- (id)initWithRecordId:(int)recId
{
	if (![super init]) {
		return nil;
	}
	
	recordId = (int)recId;

	return self;
}

-(id)init
{
	return [self initWithRecordId:0];
}

- (void)dealloc
{
	[imageKey release];
	[thumbnail release];
	[thumbnailData release];
	
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	[super init];
	
	// decode properties with their names as keys
	self.recordId = [aDecoder decodeIntForKey:@"recordId"];
	self.imageKey = [aDecoder decodeObjectForKey:@"imageKey"];
	thumbnailData = [[aDecoder decodeObjectForKey:@"thumbnailData"] retain];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	// encode properties with property name keys
	[aCoder encodeInt:recordId forKey:@"recordId"];
	[aCoder	encodeObject:imageKey forKey:@"imageKey"];
	[aCoder encodeObject:thumbnailData forKey:@"thumbnailData"];
}

- (UIImage *)thumbnail
{
	if (!thumbnailData) {
		return nil;
	}
	
	// lazy load thumbnail UIImage from thumbnail NSData
	if (!thumbnail) {
		thumbnail = [[UIImage imageWithData:thumbnailData] retain];
	}
	
	return thumbnail;
}

- (void)setThumbnailDataFromImage:(UIImage *)image
{
	// release the old thumbnail data
	[thumbnailData release];
	
	// release the old thumbnail
	[thumbnail release];
	
	// create an empty image of size 70x70
	CGRect imageRect = CGRectMake(0, 0, 70, 70);
	UIGraphicsBeginImageContext(imageRect.size);
	[image drawInRect:imageRect];
	
	// create the new image
	thumbnail = UIGraphicsGetImageFromCurrentImageContext();
	[thumbnail retain];
	
	// end image context
	UIGraphicsEndImageContext();
	
	// set the thumbnail data object from the jpeg data of the image
	thumbnailData = UIImageJPEGRepresentation(thumbnail, 1.0f);
	[thumbnailData retain];
}

- (NSString *)name
{
	// use the address book to retrieve the person's full name
	ABAddressBookRef book = ABAddressBookCreate();
	ABRecordRef record = ABAddressBookGetPersonWithRecordID(book, recordId);
	NSString *result = nil;
	
	if (record != NULL) {
		CFStringRef cfName = ABRecordCopyCompositeName(record);
		result = [NSString stringWithString:(NSString *)cfName];
		CFRelease(cfName);
	}
	
	CFRelease(book);
	return result;
}

@end