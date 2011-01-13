//
//  TesseractEngine.h
//  CardScan
//
//  Created by Dan Auclair on 1/8/11.
//  Copyright 2011 Dan Auclair. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
#import "baseapi.h"
using namespace tesseract;
#else
@class TessBaseAPI;
#endif

@interface TesseractEngine : NSObject {
	TessBaseAPI *tess;
    NSString *outputString;
}

@property(nonatomic,copy) NSString *outputString;

- (NSString *)readAndProcessImage:(UIImage *)image;

@end
