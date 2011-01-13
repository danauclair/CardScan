//
//  FileHelpers.m
//  CardScan
//
//  Created by Dan Auclair on 1/9/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import "FileHelpers.h"

NSString *pathInDocumentDirectory(NSString *fileName)
{
	NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory = [documentDirectories objectAtIndex:0];
	
	return [documentDirectory stringByAppendingPathComponent:fileName];
}
