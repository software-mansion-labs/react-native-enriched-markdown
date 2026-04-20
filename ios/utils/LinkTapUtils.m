#import "LinkTapUtils.h"
#import "ENRMSpoilerTapUtils.h"
#import "ENRMTextHitTest.h"
#import "LinkRenderer.h"

NSString *_Nullable linkURLAtTapLocation(ENRMPlatformTextView *textView, ENRMTapRecognizer *recognizer)
{
  NSUInteger characterIndex = ENRMCharacterIndexForTap(textView, recognizer);
  if (characterIndex == NSNotFound)
    return nil;

  NSAttributedString *attrText = ENRMGetAttributedText(textView);
  return [attrText attribute:@"linkURL" atIndex:characterIndex effectiveRange:NULL];
}

NSString *_Nullable linkURLAtRange(ENRMPlatformTextView *textView, NSRange characterRange)
{
  NSAttributedString *attrText = ENRMGetAttributedText(textView);
  if (characterRange.location >= attrText.length) {
    return nil;
  }
  return [attrText attribute:@"linkURL" atIndex:characterRange.location effectiveRange:NULL];
}

BOOL inlineElementAtTapLocation(ENRMPlatformTextView *textView, ENRMTapRecognizer *recognizer,
                                NSString *_Nullable *_Nullable outLinkURL, NSString *_Nullable *_Nullable outMentionURL,
                                NSString *_Nullable *_Nullable outMentionText,
                                NSString *_Nullable *_Nullable outCitationURL,
                                NSString *_Nullable *_Nullable outCitationText)
{
  NSUInteger characterIndex = ENRMCharacterIndexForTap(textView, recognizer);
  if (characterIndex == NSNotFound)
    return NO;

  NSAttributedString *attrText = ENRMGetAttributedText(textView);
  NSDictionary *attrs = [attrText attributesAtIndex:characterIndex effectiveRange:NULL];

  NSString *mentionURL = attrs[ENRMMentionURLAttributeName];
  if (mentionURL) {
    if (outMentionURL)
      *outMentionURL = mentionURL;
    if (outMentionText)
      *outMentionText = attrs[ENRMMentionTextAttributeName] ?: @"";
    return YES;
  }

  NSString *citationURL = attrs[ENRMCitationURLAttributeName];
  if (citationURL) {
    if (outCitationURL)
      *outCitationURL = citationURL;
    if (outCitationText)
      *outCitationText = attrs[ENRMCitationTextAttributeName] ?: @"";
    return YES;
  }

  NSString *linkURL = attrs[@"linkURL"];
  if (linkURL) {
    if (outLinkURL)
      *outLinkURL = linkURL;
    return YES;
  }

  return NO;
}

BOOL isPointOnInteractiveElement(ENRMPlatformTextView *textView, CGPoint point)
{
  NSUInteger charIndex = ENRMCharacterIndexAtPoint(textView, point);
  if (charIndex == NSNotFound)
    return NO;

  NSDictionary *attrs = [ENRMGetAttributedText(textView) attributesAtIndex:charIndex effectiveRange:NULL];
  return attrs[@"linkURL"] != nil || attrs[ENRMMentionURLAttributeName] != nil ||
         attrs[ENRMCitationURLAttributeName] != nil || [attrs[@"TaskItem"] boolValue] ||
         attrs[SpoilerAttributeName] != nil;
}
