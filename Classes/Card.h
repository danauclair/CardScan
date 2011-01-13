//
//  Card.h
//  CardScan
//
//  Created by Dan Auclair on 1/9/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Card : NSObject <NSCoding> {
	UIImage *thumbnail;
	NSData *thumbnailData;
	NSString *imageKey;
	int recordId;
}

@property(readonly) UIImage *thumbnail;
@property(readonly) NSString *name;
@property(nonatomic, copy) NSString *imageKey;
@property(nonatomic) int recordId;

- (id)initWithRecordId:(int)recId;
- (void)setThumbnailDataFromImage:(UIImage *)image;

@end
