//
//  CardCell.h
//  CardScan
//
//  Created by Dan Auclair on 1/9/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Card;

@interface CardCell : UITableViewCell {
	UILabel *nameLabel;
	UIImageView *imageView;
}

- (void)setCard:(Card *)card;

@end
