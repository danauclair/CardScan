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
	dictionary = [[NSMutableDictionary alloc] init];
	
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
	[dictionary setObject:i forKey:s];

	NSString *imagePath = pathInDocumentDirectory(s);
	
	// turn the image into JPEG representation
	NSData *d = UIImageJPEGRepresentation(i, 0.5);
	
	[d writeToFile:imagePath atomically:YES];
}

- (UIImage *)imageForKey:(NSString *)s
{
	UIImage *result = [dictionary objectForKey:s];
	
	if (!result) {
		result = [UIImage imageWithContentsOfFile:pathInDocumentDirectory(s)];
		
		if (result) {
			[dictionary setObject:result forKey:s];
		} else {
			NSLog(@"Error: unable to find %@", pathInDocumentDirectory(s));
		}
	}
	
	return result;
}

- (void)deleteImageForKey:(NSString *)s
{
	[dictionary removeObjectForKey:s];
	
	NSString *path = pathInDocumentDirectory(s);
	[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)clearCache:(NSNotification *)note
{
	NSLog(@"flushing %d images out of the cache", [dictionary count]);
	[dictionary removeAllObjects];
}

@end