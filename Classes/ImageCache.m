//
//  ImageCache.m
//  CardScan
//
//  Created by Dan Auclair on 1/9/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import "ImageCache.h"

static ImageCache *sharedImageCache;

@implementation ImageCache

+ (ImageCache *)sharedImageCache
{
	// lazily create the sharedImageCache on-demand
	if (!sharedImageCache) {
		sharedImageCache = [[ImageCache alloc] init];
	}
	
	return sharedImageCache;
}

+ (id)allocWithZone:(NSZone *)zone
{
	if (!sharedImageCache) {
		sharedImageCache = [super allocWithZone:zone];
	}
	
	return sharedImageCache;
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

- (void)release
{
}

- (id)init
{
	[super init];
	
	// allocate an empty dictionary to keep images in
	dictionary = [[NSMutableDictionary alloc] init];
	
	// register with the notification center for memory warnings
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(clearCache:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	
	return self;
}

- (void)dealloc
{
	[dictionary release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)setImage:(UIImage *)i forKey:(NSString *)s
{
	// add the key/image to the dictionary
	[dictionary setObject:i forKey:s];

	NSString *imagePath = pathInDocumentDirectory(s);
	
	// turn the image into JPEG representation
	NSData *d = UIImageJPEGRepresentation(i, 0.5);
	
	// atomically write the JPEG to disk in the documents directory
	[d writeToFile:imagePath atomically:YES];
}

- (UIImage *)imageForKey:(NSString *)s
{
	// check the in-memory dictionary for the image key
	UIImage *result = [dictionary objectForKey:s];
	
	// if no result, must have been flushed from cache, check the filesystem
	if (!result) {
		// try to open an image from the documents directory
		result = [UIImage imageWithContentsOfFile:pathInDocumentDirectory(s)];
		
		if (result) {
			// add the image back into the cache
			[dictionary setObject:result forKey:s];
		} else {
			NSLog(@"Error: unable to find %@", pathInDocumentDirectory(s));
		}
	}
	
	return result;
}

- (void)deleteImageForKey:(NSString *)s
{
	// remove image from the in-memory dictionary
	[dictionary removeObjectForKey:s];
	
	// build the path in the documents directory and remove that file
	NSString *path = pathInDocumentDirectory(s);
	[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)clearCache:(NSNotification *)note
{
	// flush the in-memory cache
	NSLog(@"flushing %d images out of the cache", [dictionary count]);
	[dictionary removeAllObjects];
}

@end