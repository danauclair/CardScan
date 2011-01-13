//
//  CardCell.m
//  CardScan
//
//  Created by Dan Auclair on 1/9/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import "CardCell.h"
#import "Card.h"
#import <QuartzCore/QuartzCore.h>

@implementation CardCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:nameLabel];
		[nameLabel release];
		
		imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:imageView];
		imageView.contentMode = UIViewContentModeScaleAspectFit;
		[imageView release];
	}
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	float inset = 5.0;
	CGRect innerFrame = CGRectMake(inset, inset, 70, 70);
	imageView.frame = innerFrame;
	imageView.layer.masksToBounds = YES;
	imageView.layer.cornerRadius = 5.0;

	innerFrame.origin.x += innerFrame.size.width + inset;
	innerFrame.size.width = self.contentView.bounds.size.width - 90;
	nameLabel.frame = innerFrame;
	nameLabel.font = [UIFont boldSystemFontOfSize:18];
}

- (void)setCard:(Card *)card
{
	nameLabel.text = card.name;
	imageView.image = card.thumbnail;
}

@end
