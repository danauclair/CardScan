//
//  ImageCache.h
//  CardScan
//
//  Created by Dan Auclair on 1/9/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageCache : NSObject {
	NSMutableDictionary *dictionary;
}

+ (ImageCache *)sharedImageCache;
- (void)setImage:(UIImage *)i forKey:(NSString *)s;
- (UIImage *)imageForKey:(NSString *)s;
- (void)deleteImageForKey:(NSString *)s;

@end