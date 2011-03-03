//
//  CardScanAppDelegate.m
//  CardScan
//
//  Created by Dan Auclair on 1/8/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import "CardScanAppDelegate.h"
#import "CardScanViewController.h"

// interface for "private" methods
@interface CardScanAppDelegate()
- (NSString *)cardArrayPath;
- (void)archiveCards;
@end

@implementation CardScanAppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// unarchive any existing array of card objects
	NSMutableArray *cardsArray = [NSKeyedUnarchiver unarchiveObjectWithFile:[self cardArrayPath]];
	
	if (!cardsArray) {
		// if an archived version didn't exist, create a new empty one
		cardsArray = [NSMutableArray array];
	}
	
	// create the CardScanViewController
	viewController = [[CardScanViewController alloc] init];
	
	// assign the cards array to the cards property on the view controller
	viewController.cards = cardsArray;
	
	// set up a UINavigationController and add the CardScanViewController as the root view controller
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
	navController.navigationBar.barStyle = UIBarStyleBlack;
	window.rootViewController = navController;
	
	// window will retain UINavigationController, we can release it
	[navController release];
	
    [window makeKeyAndVisible];
	
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// application has been sent to background, save the current array of cards
	[self archiveCards];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// application is about to terminate, save our current array of cards
	[self archiveCards];
}

- (void)dealloc
{
	[viewController release];
    [window release];
    [super dealloc];
}

- (void)archiveCards
{
	// use NSKeyedArchiver to archive the cards array to the app's documents directory on the filesystem
	[NSKeyedArchiver archiveRootObject:viewController.cards toFile:[self cardArrayPath]];
}

- (NSString *)cardArrayPath
{
	// return a path to a "Cards.data" file in the document sandbox of the application
	return pathInDocumentDirectory(@"Cards.data");
}

@end