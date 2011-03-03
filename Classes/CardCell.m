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
		// create a new UILabel for the name and add it to the contentView of this UITableViewCell
		nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:nameLabel];
		[nameLabel release];
		
		// create a new UIImageView for the image and add it to the contentView
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
	
	// position a 70 x 70 px version of the card image inset 5 px w/ rounded corners
	float inset = 5.0;
	CGRect innerFrame = CGRectMake(inset, inset, 70, 70);
	imageView.frame = innerFrame;
	imageView.layer.masksToBounds = YES;
	imageView.layer.cornerRadius = 5.0;

	// position the name label 5 pixels over, with bold 18 size font
	innerFrame.origin.x += innerFrame.size.width + inset;
	innerFrame.size.width = self.contentView.bounds.size.width - 90;
	nameLabel.frame = innerFrame;
	nameLabel.font = [UIFont boldSystemFontOfSize:18];
}

- (void)setCard:(Card *)card
{
	// set the text & image on the subviews from the card data
	nameLabel.text = card.name;
	imageView.image = card.thumbnail;
}

@end
