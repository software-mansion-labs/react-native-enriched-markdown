#pragma once

#import "ENRMFormattingRange.h"
#import "ENRMInputStyledRange.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ENRMParseResult : NSObject
@property (nonatomic, strong) NSString *plainText;
@property (nonatomic, strong) NSArray<ENRMFormattingRange *> *formattingRanges;
@end

@interface ENRMInputParser : NSObject

- (ENRMParseResult *)parseToPlainTextAndRanges:(NSString *)markdown;

@end

NS_ASSUME_NONNULL_END
