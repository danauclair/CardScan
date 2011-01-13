//
//  NewPersonViewController.m
//  CardScan
//
//  Created by Dan Auclair on 1/12/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import "NewPersonViewController.h"

@implementation NewPersonViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// had to subclass this just to set the navigation bar to black
	// for some reason would not work when setting directly 
	// on the parent navigation controller from calling code
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
}

@end
