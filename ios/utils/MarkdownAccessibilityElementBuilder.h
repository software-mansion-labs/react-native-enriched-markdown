#import <UIKit/UIKit.h>

@class AccessibilityInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 * Builds UIAccessibilityElement objects from markdown content for VoiceOver.
 * Handles headings, links, images, lists, and custom rotor navigation.
 */
@interface MarkdownAccessibilityElementBuilder : NSObject

/**
 * Builds accessibility elements for the given text view content.
 * - Headings get UIAccessibilityTraitHeader
 * - Links get UIAccessibilityTraitLink
 * - Images get UIAccessibilityTraitImage
 * - List items get position hints (e.g., "bullet point", "list item 1")
 * - Other content gets UIAccessibilityTraitStaticText
 */
+ (NSMutableArray<UIAccessibilityElement *> *)buildElementsForTextView:(UITextView *)textView
                                                                  info:(AccessibilityInfo *)info
                                                             container:(id)container;

/** Filters elements with UIAccessibilityTraitHeader trait. */
+ (NSArray<UIAccessibilityElement *> *)filterHeadingElements:(NSArray<UIAccessibilityElement *> *)elements;

/** Filters elements with UIAccessibilityTraitLink trait. */
+ (NSArray<UIAccessibilityElement *> *)filterLinkElements:(NSArray<UIAccessibilityElement *> *)elements;

/** Filters elements with UIAccessibilityTraitImage trait. */
+ (NSArray<UIAccessibilityElement *> *)filterImageElements:(NSArray<UIAccessibilityElement *> *)elements;

/** Creates a custom rotor for heading navigation. */
+ (UIAccessibilityCustomRotor *)createHeadingRotorWithElements:(NSArray<UIAccessibilityElement *> *)elements;

/** Creates a custom rotor for link navigation. */
+ (UIAccessibilityCustomRotor *)createLinkRotorWithElements:(NSArray<UIAccessibilityElement *> *)elements;

/** Creates a custom rotor for image navigation. */
+ (UIAccessibilityCustomRotor *)createImageRotorWithElements:(NSArray<UIAccessibilityElement *> *)elements;

/**
 * Builds the standard set of accessibility custom rotors (headings, links, images)
 * from an array of accessibility elements.
 * Only includes rotors for categories that have matching elements.
 */
+ (NSArray<UIAccessibilityCustomRotor *> *)buildRotorsFromElements:(NSArray<UIAccessibilityElement *> *)elements;

@end

NS_ASSUME_NONNULL_END
