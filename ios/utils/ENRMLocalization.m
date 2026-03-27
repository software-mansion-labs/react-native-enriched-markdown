#import "ENRMLocalization.h"

@interface ENRMLocalizationBundleToken : NSObject
@end

@implementation ENRMLocalizationBundleToken
@end

NSBundle *ENRMLocalizationBundle(void)
{
  static NSBundle *bundle;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSArray<NSBundle *> *searchBundles =
        [@[ [NSBundle bundleForClass:[ENRMLocalizationBundleToken class]], [NSBundle mainBundle] ]
            arrayByAddingObjectsFromArray:[NSBundle allBundles]];

    for (NSBundle *candidate in searchBundles) {
      NSURL *resourceURL = [candidate URLForResource:@"ReactNativeEnrichedMarkdown" withExtension:@"bundle"];
      if (!resourceURL) {
        continue;
      }

      NSBundle *resourceBundle = [NSBundle bundleWithURL:resourceURL];
      if (resourceBundle) {
        bundle = resourceBundle;
        break;
      }
    }

    if (!bundle) {
      bundle = [NSBundle bundleForClass:[ENRMLocalizationBundleToken class]];
    }
  });

  return bundle;
}

NSString *ENRMLocalizedString(NSString *key)
{
  NSString *localized = [ENRMLocalizationBundle() localizedStringForKey:key value:nil table:nil];
  if (localized.length > 0 && ![localized isEqualToString:key]) {
    return localized;
  }

  localized = [[NSBundle mainBundle] localizedStringForKey:key value:nil table:nil];
  if (localized.length > 0) {
    return localized;
  }

  return key;
}
