//
//  CardParser.m
//  CardScan
//
//  Created by Dan Auclair on 1/8/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//
//  A class used to parse a bunch of OCR text into the fields of an ABRecordRef which can be added to the 
//  iPhone address book contacts. This class copies and opens a small SQLite databse with a table of ~5500
//  common American first names which it uses to help decipher which text on the business card is the name.
//
//  The class tokenizes the text by splitting it up by newlines and also by a simple " . " regex pattern.
//  This is because many business cards put multiple "tokens" of information on a single line separated by 
//  spaces and some kind of character such as |, -, /, or a dot.
//
//  Once the OCR text is fully tokenized it tries to identify the name (via SQLite table), job title (uses 
//  a set of common job title words), email, website, phone, address (all using regex patterns). The company
//  or organization name is assumed to be the first token/line of the text unless that is the name.
//
//  This is obviously a far from perfect parsing scheme for business card text, but it seems to work decently
//  on a number of cards that were tested. I'm sure a lot of improvements can be made here.
//

#import "CardParser.h"
#import "RegexKitLite.h"

// "private" methods
@interface CardParser()
- (NSArray *)tokenizeText:(NSString *)text;
- (NSString *)returnMatchOrNilForRegex:(NSString *)regEx withString:(NSString *)text;
- (BOOL)isCommonName:(NSString *)text;
- (BOOL)isCommonJobTitleWord:(NSString *)text;
- (NSString *)nameToken;
- (NSString *)emailToken;
- (NSString *)websiteToken;
- (NSString *)jobTitleToken;
- (NSString *)streetAddressToken;
- (NSString *)cityStateZipAddressToken;
- (NSArray *)phoneNumbers;
@end

@implementation CardParser

- (id)init
{
	return [self initWithText:nil];
}

- (id)initWithText:(NSString *)text
{
	if (![super	init]) {
		return nil;
	}
	
	// break up the OCR text into tokens split by newlines and dividers (i.e. | )
	tokens = [[self tokenizeText:text] retain];
	
	// copy the names.db SQLite database to the documents directory of the app if necessary
	NSString *path = pathInDocumentDirectory(@"names.db");
	NSFileManager *fm = [NSFileManager defaultManager];
	
	if (![fm fileExistsAtPath:path]) {
		NSLog(@"Copying names database to documents directory");
		NSString *pathForDB = [[NSBundle mainBundle] pathForResource:@"names" ofType:@"db"];
		BOOL success = [fm copyItemAtPath:pathForDB toPath:path error:NULL];
		
		if (!success) {
			NSLog(@"Database Copy Failed");
		}
	}
	
	// open the SQLite database
	const char *cPath = [path cStringUsingEncoding:NSUTF8StringEncoding];
	
	NSLog(@"Opening names database");
	
	if (sqlite3_open(cPath, &database) != SQLITE_OK) {
		NSLog(@"Unable to open database at %@", path);
	}
	
	return self;
}

- (void)dealloc
{
	[tokens release];
	
	// finalize & close SQLite database
	sqlite3_finalize(statement);
	sqlite3_close(database);
	
	[super dealloc];
}

// break up a string of text by newlines & single character separators
- (NSArray *)tokenizeText:(NSString *)text
{
	// split into array of lines
	NSArray *lines = [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	NSMutableArray *components = [NSMutableArray array]; // autoreleased
	
	// tokenize each line using any single character surrounded by spaces, i.e. | 
	for (NSString *line in lines) {
		for (NSString *token in [line componentsSeparatedByRegex:@" . "]) {
			// only add non-trivial length tokens, strings under 3 characters seem to be OCR character garbage
			if ([token length] > 2) {
				[components addObject:token];
			}
		}
	}
	
	return components;
}


- (ABRecordRef)parsedABRecordRef
{
	NSString *organization = nil;
	NSString *first = nil;
	NSString *middle = nil;
	NSString *last = nil;
	
	NSString *firstToken = [tokens objectAtIndex:0];
	
	// find the name token of the card
	NSString *nameToken = [self nameToken];
	
	// if the name token is not the first token in the array, assume the first one is the organization name
	if (![nameToken isEqual:firstToken]) {
		organization = firstToken;
	}
	
	// split up the name token into first, last, and join remaining as middle
	if (nameToken) {
		NSMutableArray *nameComponents = [NSMutableArray arrayWithArray:[nameToken componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];

		first = [nameComponents objectAtIndex:0];

		if (nameComponents.count > 1) {
			last = [nameComponents objectAtIndex:nameComponents.count - 1];
			middle = nil;
			
			if (nameComponents.count > 2) {
				[nameComponents removeObject:first];
				[nameComponents removeObject:last];
				middle = [nameComponents componentsJoinedByString:@" "];
			}
		}

		NSLog(@"First: %@", first);

		if (middle) {
			NSLog(@"Middle: %@", middle);
		}

		if (last) {
			NSLog(@"Last: %@", last);
		}
	}
	
	NSArray *phones = [self phoneNumbers];
	
	for (NSString *phone in phones) {
		NSLog(@"Phone: %@", phone);
	}
	
	NSString *email = [self emailToken];
	if (email) {
		NSLog(@"Email: %@", email);
	}
	
	NSString *website = [self websiteToken];
	if (website) {
		NSLog(@"Website: %@", website);
	}
	
	NSString *jobTitle = [self jobTitleToken];
	if (jobTitle) {
		NSLog(@"Job Title: %@", jobTitle);
	}
	
	NSString *address = [self streetAddressToken];
	if (address) {
		NSLog(@"Street Address: %@", address);
	}
	
	NSString *city = nil;
	NSString *state = nil;
	NSString *zip = nil;
	NSString *cityStateZipToken = [self cityStateZipAddressToken];
	
	if (cityStateZipToken) {
		city = [self returnMatchOrNilForRegex:@"^[A-Za-z]+," withString:cityStateZipToken];
		if (city) {
			city = [city stringByReplacingOccurrencesOfString:@"," withString:@""];
			NSLog(@"City: %@", city);
		}
		
		state = [self returnMatchOrNilForRegex:@", [A-Za-z]+" withString:cityStateZipToken];
		if (state) {
			state = [state stringByReplacingOccurrencesOfString:@", " withString:@""];
			NSLog(@"State: %@", state);
		}
		
		zip = [self returnMatchOrNilForRegex:@"[0-9]{5}" withString:cityStateZipToken];
		if (zip) {
			NSLog(@"Zip: %@", zip);
		}
	}
	
	if (tokens.count > 0) {
		// if the organization name was not filled by the first token above, arbitrarily set
		// it to the first unmatched token here. i know this kind of sucks, should figure out
		// a better way to parse out a company or organization name (maybe some regex with co, inc, LLC)
		organization = [tokens objectAtIndex:0];
		[tokens removeObject:organization];
		
		for (NSString *token in tokens) {
			NSLog(@"Unmatched Token: %@", token);
		}
	}
	
	NSLog(@"Creating New Address Book Record...");
	
	ABRecordRef person = ABPersonCreate(); 
	CFErrorRef  error = NULL;  
	
	// name
	if (first) {
		ABRecordSetValue(person, kABPersonFirstNameProperty, first, NULL);
	}
	
	if (last) {
		ABRecordSetValue(person, kABPersonLastNameProperty, last, NULL);
	}
	
	if (middle) {
		ABRecordSetValue(person, kABPersonMiddleNameProperty, middle, NULL);
	}
	
	// organization
	if (organization) {
		ABRecordSetValue(person, kABPersonOrganizationProperty, organization, NULL);
	}
	
	// title
	if(jobTitle) {
		ABRecordSetValue(person, kABPersonJobTitleProperty, jobTitle, NULL);
	}
	
	// email
	if (email) {
		ABMutableMultiValueRef emailMultiVal = ABMultiValueCreateMutable(kABMultiStringPropertyType);
		ABMultiValueAddValueAndLabel(emailMultiVal, email, CFSTR("email"), NULL);
		ABRecordSetValue(person, kABPersonEmailProperty, emailMultiVal, &error);
		CFRelease(emailMultiVal);
	}
	
	// phone
	if (phones.count > 0) {
		ABMutableMultiValueRef phoneMultiVal = ABMultiValueCreateMutable(kABMultiStringPropertyType);
		for (NSString *phone in phones) {
			ABMultiValueAddValueAndLabel(phoneMultiVal, phone, kABPersonPhoneMainLabel, NULL);
		}
		ABRecordSetValue(person, kABPersonPhoneProperty, phoneMultiVal, &error);
		CFRelease(phoneMultiVal);
	}
	
	// address
	if (address || city || state || zip) {
		ABMutableMultiValueRef addy = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);  
		NSMutableDictionary *addressDict = [[NSMutableDictionary alloc] init];
		
		if (zip) {
			[addressDict setObject:zip forKey:(NSString *)kABPersonAddressZIPKey];
		}
		
		if (city) {
			[addressDict setObject:city forKey:(NSString *)kABPersonAddressCityKey];
		}
		
		if (state) {
			[addressDict setObject:state forKey:(NSString *)kABPersonAddressStateKey];
		}
		
		if (address) {
			[addressDict setObject:address forKey:(NSString *)kABPersonAddressStreetKey];
		}
		
		ABMultiValueAddValueAndLabel(addy, addressDict, kABWorkLabel, NULL);
		ABRecordSetValue(person, kABPersonAddressProperty, addy, &error); 
		CFRelease(addy);
	}
	
	// homepage
	if (website) {
		ABMutableMultiValueRef webMultiVal = ABMultiValueCreateMutable(kABMultiStringPropertyType);
		ABMultiValueAddValueAndLabel(webMultiVal, website, kABPersonHomePageLabel, NULL);
		ABRecordSetValue(person, kABPersonURLProperty, webMultiVal, &error);
		CFRelease(webMultiVal);
	}

	if (error != NULL) {
		NSLog(@"Error: %@", error);
	}
	
	[(id)person autorelease];
	return person;
}

- (NSString *)nameToken
{
	NSString *result = nil;
	
	for (NSString *token in tokens) {
		for (NSString *word in [token componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]) {
			if ([self isCommonName:word]) {
				result = token;
				break;
			}
		}
	}
	
	if (result) {
		[tokens removeObject:result];
	}
	
	return result;
}

- (NSString *)jobTitleToken
{
	NSString *result = nil;
	
	for (NSString *token in tokens) {
		for (NSString *word in [token componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]) {
			if ([self isCommonJobTitleWord:word]) {
				result = token;
				break;
			}
		}
	}
	
	if (result) {
		[tokens removeObject: result];
	}
	
	return result;
}

- (NSString *)emailToken
{
	NSString *emailRegex = @"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
	NSString *result = nil;
	
	for (NSString *token in tokens) {
		result = [self returnMatchOrNilForRegex:emailRegex withString:token];
		if (result) {
			break;
		}
	}
	
	if (result) {
		[tokens removeObject:result];
	}
	
	return result;
}

// uses RegexKitLite to check for a match, returns either the match or nil
- (NSString *)returnMatchOrNilForRegex:(NSString *)regEx withString:(NSString *)text
{
	NSString *match = [text stringByMatching:regEx];
	
	if ([match isEqual:@""]) {
		return nil;
	} else {
		return match;
	}
}

- (NSString *)websiteToken
{
	NSString *websiteRegex = @"[A-Za-z0-9]+\\.[A-Za-z]{2,4}";
	NSString *result = nil;
	
	for (NSString *token in tokens) {
		result = [self returnMatchOrNilForRegex:websiteRegex withString:token];
		
		if (result) {
			break;
		}
	}
	
	if (result) {
		[tokens removeObject:result];
	}
	
	return result;
}

- (NSArray *)phoneNumbers
{
	NSString *phoneRegex  = @"\\(?[0-9]{3}\\)?[-. ]?[0-9]{3}[-. ]?[0-9]{4}";
	NSMutableArray *result = [NSMutableArray array];
	NSMutableArray *phoneTokens = [NSMutableArray array];
	
	for (NSString *token in tokens) {
		NSString *phoneNumber = [self returnMatchOrNilForRegex:phoneRegex withString:token];
		if (phoneNumber) {
			[phoneTokens addObject:token];
			[result addObject:phoneNumber];
		}
	}
	
	[tokens removeObjectsInArray:phoneTokens];
	
	return result;
}

- (NSString *)streetAddressToken
{
	NSString *addressRegex = @"[0-9]{1,6} [A-Za-z]+";
	NSString *result = nil;
	
	for( NSString *token in tokens) {
		if ([self returnMatchOrNilForRegex:addressRegex withString:token]) {
			result = token;
			break;
		}
	}
	
	if (result) {
		[tokens removeObject:result];
	}
	
	return result;
}

- (NSString *)cityStateZipAddressToken
{
	NSString *addressRegex = @"[A-Za-z]+, [A-Za-z]+ [0-9]{5}";
	NSString *result = nil;
	
	for (NSString *token in tokens) {
		if ([self returnMatchOrNilForRegex:addressRegex withString:token]) {
			result = token;
			break;
		}
	}
	
	if (result) {
		[tokens removeObject:result];
	}
	
	return result;
}


- (BOOL)isCommonName:(NSString *)text
{
	// query SQLite database of ~5500 common American names
	if (!statement) {
		char *cQuery = "SELECT Name FROM FirstName WHERE Name = ?";
		
		if (sqlite3_prepare_v2(database, cQuery, -1, &statement, NULL) != SQLITE_OK) {
			NSLog(@"query error: %s", statement);
		}
	}
	
	// expects upper-case C string
	const char *cText = [[text uppercaseString] cStringUsingEncoding:NSUTF8StringEncoding];
	
	sqlite3_bind_text(statement, 1, cText, -1, SQLITE_TRANSIENT);
	
	BOOL result = NO;
	
	while (sqlite3_step(statement) == SQLITE_ROW) {
		result = YES; // found the name in the database
	}
	
	sqlite3_reset(statement);
	
	return result;
}
				
- (BOOL)isCommonJobTitleWord:(NSString *)word
{
	// this is obviously far from perfect, but a set of common words that are usually found in job titles
	// this would need to be fine tuned a lot -- possibly put into a SQLite table
	// don't want to get false positives with company name or address, etc
	NSSet *commonJobTitleWords = [NSSet setWithObjects:@"account",@"accountant",@"accounts",@"director",@"coordinator",@"technician",
								  @"actuary",@"analyst",@"assistant",@"clerk",@"secretary",@"receptionist",@"services",@"administrator",
								  @"administrative",@"supervisor",@"attorney",@"trainer",@"auditor",@"librarian",@"associate",@"president",
								  @"manager",@"operator",@"inspector",@"barista",@"server",@"aide",@"catering",@"sales",@"programmer",
								  @"specialist",@"producer",@"executive",@"foreman",@"senior",@"junior",@"controller",@"instructor",
								  @"educator",@"clinician",@"attendant",@"superintendent",@"lieutenant",@"captain",@"head",@"lead",
								  @"representative",@"coach",@"engineer",@"engineering",@"architect",@"worker",@"technical",@"machinist",
								  @"payroll",@"intern",@"recruiter",@"dietitian",@"scientist",@"officer",@"systems",@"registrar",
								  @"developer",@"chairman",@"CEO",@"CTO",@"CFO",@"IT",@"operations",@"agent",nil];
	
	// check the NSSet for the word as lowercase
	if ([commonJobTitleWords containsObject:[word lowercaseString]]) {
		return YES;
	}
	
	return NO;
}

@end
