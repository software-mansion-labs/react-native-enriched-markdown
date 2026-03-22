#import "ENRMInputLinkPrompt.h"

// TODO: Wrap all user-facing strings with NSLocalizedString for localization support.
void ENRMShowLinkPrompt(RCTUIView *sourceView, NSString *existingURL, void (^completion)(NSString *url))
{
#if !TARGET_OS_OSX
  BOOL isEditing = existingURL.length > 0;
  NSString *title = isEditing ? @"Edit Link" : @"Add Link";
  NSString *buttonTitle = isEditing ? @"Update" : @"Add";

  UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                 message:nil
                                                          preferredStyle:UIAlertControllerStyleAlert];

  [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
    textField.placeholder = @"URL";
    textField.text = existingURL ?: @"";
    textField.keyboardType = UIKeyboardTypeURL;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
  }];

  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

  [alert addAction:[UIAlertAction actionWithTitle:buttonTitle
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            NSString *url = alert.textFields.firstObject.text ?: @"";
                                            if (url.length > 0) {
                                              completion(url);
                                            }
                                          }]];

  UIViewController *presenter = sourceView.window.rootViewController;
  while (presenter.presentedViewController) {
    presenter = presenter.presentedViewController;
  }
  [presenter presentViewController:alert animated:YES completion:nil];
#else
  BOOL isEditing = existingURL.length > 0;
  NSString *title = isEditing ? @"Edit Link" : @"Add Link";
  NSString *buttonTitle = isEditing ? @"Update" : @"Add";

  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = title;
  alert.informativeText = @"Enter the URL for the link.";
  [alert addButtonWithTitle:buttonTitle];
  [alert addButtonWithTitle:@"Cancel"];

  NSTextField *urlField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 260, 24)];
  urlField.placeholderString = @"URL";
  urlField.stringValue = existingURL ?: @"";
  alert.accessoryView = urlField;

  [alert beginSheetModalForWindow:sourceView.window
                completionHandler:^(NSModalResponse returnCode) {
                  if (returnCode == NSAlertFirstButtonReturn) {
                    NSString *url = urlField.stringValue ?: @"";
                    if (url.length > 0) {
                      completion(url);
                    }
                  }
                }];
#endif
}
