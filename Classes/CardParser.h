//
//  CardParser.h
//  CardScan
//
//  Created by Dan Auclair on 1/8/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <sqlite3.h>

@interface CardParser : NSObject {
	NSMutableArray *tokens;
	sqlite3 *database;
	sqlite3_stmt *statement;
}

- (id)initWithText:(NSString *)text;
- (ABRecordRef)parsedABRecordRef;

@end