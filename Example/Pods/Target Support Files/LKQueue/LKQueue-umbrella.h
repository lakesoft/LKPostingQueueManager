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

#import "LKQueue.h"
#import "LKQueueEntry.h"
#import "LKQueueEntryOperator.h"
#import "LKQueueManager.h"

FOUNDATION_EXPORT double LKQueueVersionNumber;
FOUNDATION_EXPORT const unsigned char LKQueueVersionString[];

