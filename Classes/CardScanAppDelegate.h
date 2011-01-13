//
//  CardScanAppDelegate.h
//  CardScan
//
//  Created by Dan Auclair on 1/8/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CardScanViewController;

@interface CardScanAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	CardScanViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

