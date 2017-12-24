#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "LKCodingObject.h"

FOUNDATION_EXPORT double LKCodingObjectVersionNumber;
FOUNDATION_EXPORT const unsigned char LKCodingObjectVersionString[];

