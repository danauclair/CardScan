//
//  TesseractEngine.m
//  CardScan
//
//  Created by Dan Auclair on 1/8/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import "TesseractEngine.h"
#import "baseapi.h"

@interface TesseractEngine()
// interface for "private" methods
- (NSString *)documentsDirectory;
@end

@implementation TesseractEngine

@synthesize outputString;

- (id)init
{
	self = [super init];
	
	// if tessdata does not exist in the documents directory for the app, copy from the application bundle
    NSString *dataPath = [[self documentsDirectory] stringByAppendingPathComponent:@"tessdata"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
	
    if (![fileManager fileExistsAtPath:dataPath]) {
        // get the path to the app bundle
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
        NSString *tessdataPath = [bundlePath stringByAppendingPathComponent:@"tessdata"];
		
        if (tessdataPath) {
			// perform the copy
            [fileManager copyItemAtPath:tessdataPath toPath:dataPath error:NULL];
        }
    }
    
    NSString *dataPathWithSlash = [[self documentsDirectory] stringByAppendingString:@"/"];
    setenv("TESSDATA_PREFIX", [dataPathWithSlash UTF8String], 1);
    
    // init the tesseract engine
    tess = new TessBaseAPI();
    tess->Init([dataPath cStringUsingEncoding:NSUTF8StringEncoding],    // Path to tessdata-no ending /.
               "eng");													// ISO 639-3 string or NULL.
	
	return self;
}

- (void)dealloc
{
	// shutdown tesseract
	tess->End();
	
	[super dealloc];
}

- (NSString *)documentsDirectory 
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (NSString *)readAndProcessImage:(UIImage *)image 
{
    CGSize imageSize = [image size];
    double bytes_per_line	= CGImageGetBytesPerRow([image CGImage]);
    double bytes_per_pixel	= CGImageGetBitsPerPixel([image CGImage]) / 8.0;
    
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider([image CGImage]));
    const UInt8 *imageData = CFDataGetBytePtr(data);
    
    // this could take a while...
    char* text = tess->TesseractRect(imageData,
                                     bytes_per_pixel,
                                     bytes_per_line,
                                     0, 0,
                                     imageSize.width, imageSize.height);
    
	// return as objective-c string
    return [NSString stringWithUTF8String:text];
}

@end