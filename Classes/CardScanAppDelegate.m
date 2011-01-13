//
//  CardScanAppDelegate.m
//  CardScan
//
//  Created by Dan Auclair on 1/8/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import "CardScanAppDelegate.h"
#import "CardScanViewController.h"

// "private" methods
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
		cardsArray = [NSMutableArray array];
	}
	
	// create the CardScanViewController
	viewController = [[CardScanViewController alloc] init];
	viewController.cards = cardsArray;
	
	// set up a UINavigationController and add the CardScanViewController as the root
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
	navController.navigationBar.barStyle = UIBarStyleBlack;
	window.rootViewController = navController;
	[navController release];
	
    [window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
	[self archiveCards];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
	[self archiveCards];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}

- (void)dealloc
{
	[viewController release];
    [window release];
    [super dealloc];
}

- (NSString *)cardArrayPath
{
	return pathInDocumentDirectory(@"Cards.data");
}

- (void)archiveCards
{
	[NSKeyedArchiver archiveRootObject:viewController.cards toFile:[self cardArrayPath]];
}

@end
