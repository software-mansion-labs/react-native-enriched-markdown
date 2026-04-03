#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ENRMWordResult : NSObject

@property (nonatomic, copy, readonly) NSString *word;
@property (nonatomic, assign, readonly) NSRange range;

+ (instancetype)resultWithWord:(NSString *)word range:(NSRange)range;

@end

@interface ENRMWordsUtils : NSObject

/// Expands the modification range to word boundaries, then splits into
/// individual ENRMWordResult objects.
+ (NSArray<ENRMWordResult *> *)getAffectedWordsFromText:(NSString *)text modificationRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
