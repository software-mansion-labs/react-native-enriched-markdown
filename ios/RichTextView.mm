#import "RichTextView.h"
#import "MarkdownParser.h"
#import "MarkdownASTNode.h"
#import "AttributedRenderer.h"
#import "RenderContext.h"
#import "RichTextTheme.h"

#import <react/renderer/components/RichTextViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/RichTextViewSpec/EventEmitters.h>
#import <react/renderer/components/RichTextViewSpec/Props.h>
#import <react/renderer/components/RichTextViewSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;

// Constants
static const CGFloat kDefaultFontSize = 16.0;
static const CGFloat kMinimumHeight = 100.0;
static const CGFloat kLabelPadding = 10.0;

@interface RichTextView () <RCTRichTextViewViewProtocol>
- (void)setupTextView;
- (void)setupConstraints;
- (void)renderMarkdownContent:(NSString *)markdownString withProps:(const RichTextViewProps &)props;
- (void)textTapped:(UITapGestureRecognizer *)recognizer;
- (UIFont *)createFontWithFamily:(NSString *)fontFamily size:(CGFloat)size;
@end

@implementation RichTextView {
    UITextView * _textView;
    MarkdownParser * _parser;
}

// MARK: - Component utils

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
    return concreteComponentDescriptorProvider<RichTextViewComponentDescriptor>();
}

// MARK: - Init

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        static const auto defaultProps = std::make_shared<const RichTextViewProps>();
        _props = defaultProps;

        self.backgroundColor = [UIColor clearColor];  
        _parser = [[MarkdownParser alloc] init];
        
        [self setupTextView];
        [self setupConstraints];
    }

    return self;
}

- (void)setupTextView {
    _textView = [[UITextView alloc] init];
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    _textView.text = @"";
    _textView.font = [UIFont systemFontOfSize:16.0];
    _textView.backgroundColor = [UIColor clearColor];  
    _textView.textColor = [UIColor blackColor];
    _textView.editable = NO;
    _textView.scrollEnabled = NO;
    _textView.textContainerInset = UIEdgeInsetsZero;
    _textView.textContainer.lineFragmentPadding = 0;
    
    // Add tap gesture recognizer
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textTapped:)];
    [_textView addGestureRecognizer:tapRecognizer];
    
    [self addSubview:_textView];
}

- (void)setupConstraints {
    [NSLayoutConstraint activateConstraints:@[
        [_textView.topAnchor constraintEqualToAnchor:self.topAnchor 
                                           constant:kLabelPadding],
        [_textView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor 
                                                constant:kLabelPadding],
        [_textView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor 
                                                 constant:-kLabelPadding],
        [_textView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor 
                                               constant:-kLabelPadding],
        [self.heightAnchor constraintGreaterThanOrEqualToConstant:kMinimumHeight]
    ]];
}

// MARK: - Rendering

- (void)renderMarkdownContent:(NSString *)markdownString withProps:(const RichTextViewProps &)props {
    MarkdownASTNode *ast = [_parser parseMarkdown:markdownString];
    if (!ast) {
        NSLog(@"RichTextView: Failed to parse markdown");
        return;
    }
    
    AttributedRenderer *renderer = [AttributedRenderer new];
    RichTextTheme *theme = [RichTextTheme defaultTheme];
    
    CGFloat fontSize = props.fontSize > 0 ? props.fontSize : kDefaultFontSize;
    
    // Create font with family and size
    NSString *fontFamily = [[NSString alloc] initWithUTF8String:props.fontFamily.c_str()];
    theme.baseFont = [self createFontWithFamily:fontFamily size:fontSize];
    if (_textView.textColor) { theme.textColor = _textView.textColor; }
    
    const auto &headerConfig = props.headerConfig;
    
    theme.headerConfig.scale = headerConfig.scale > 0 ? headerConfig.scale : 2.0;
    theme.headerConfig.isBold = headerConfig.isBold;
    
    RenderContext *renderContext = [RenderContext new];
    NSMutableAttributedString *attributedText = [renderer renderRoot:ast theme:theme context:renderContext];
    
    // Add custom attributes for links
    for (NSUInteger i = 0; i < renderContext.linkRanges.count; i++) {
        NSValue *rangeValue = renderContext.linkRanges[i];
        NSRange range = [rangeValue rangeValue];
        NSString *url = renderContext.linkURLs[i];
        
        // Add custom attribute for link detection
        [attributedText addAttribute:@"linkURL" value:url range:range];
    }
    
    _textView.attributedText = attributedText;
}

// MARK: - Props

- (void)updateProps:(Props::Shared const &)props 
          oldProps:(Props::Shared const &)oldProps {
    const auto &oldViewProps = *std::static_pointer_cast<RichTextViewProps const>(_props);
    const auto &newViewProps = *std::static_pointer_cast<RichTextViewProps const>(props);
    
    BOOL needsRerender = NO;
    
    if (oldViewProps.markdown != newViewProps.markdown) {
        NSString *markdownString = [[NSString alloc] initWithUTF8String:newViewProps.markdown.c_str()];
        [self renderMarkdownContent:markdownString withProps:newViewProps];
        needsRerender = YES;
    }
    
    if (oldViewProps.textColor != newViewProps.textColor) {
        NSString *textColorString = [[NSString alloc] initWithUTF8String:newViewProps.textColor.c_str()];
        _textView.textColor = [self hexStringToColor:textColorString];
        needsRerender = YES;
    }
    
    if (oldViewProps.fontSize != newViewProps.fontSize || oldViewProps.fontFamily != newViewProps.fontFamily) {
        CGFloat fontSize = newViewProps.fontSize > 0 ? newViewProps.fontSize : kDefaultFontSize;
        NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.fontFamily.c_str()];
        _textView.font = [self createFontWithFamily:fontFamily size:fontSize];
        needsRerender = YES;
    }
    
    if (oldViewProps.headerConfig.scale != newViewProps.headerConfig.scale ||
        oldViewProps.headerConfig.isBold != newViewProps.headerConfig.isBold) {
        needsRerender = YES;
    }
    
    if (needsRerender && !newViewProps.markdown.empty()) {
        NSString *markdownString = [[NSString alloc] initWithUTF8String:newViewProps.markdown.c_str()];
        [self renderMarkdownContent:markdownString withProps:newViewProps];
    }

    [super updateProps:props oldProps:oldProps];
}

Class<RCTComponentViewProtocol> RichTextViewCls(void)
{
    return RichTextView.class;
}

- (UIColor *)hexStringToColor:(NSString *)hexString {
    if (!hexString.length) return nil;
    
    NSString *cleanHex = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if (cleanHex.length != 6) return nil;
    
    NSScanner *scanner = [NSScanner scannerWithString:cleanHex];
    unsigned hexValue;
    if (![scanner scanHexInt:&hexValue]) return nil;
    
    CGFloat red = ((hexValue >> 16) & 0xFF) / 255.0f;
    CGFloat green = ((hexValue >> 8) & 0xFF) / 255.0f;
    CGFloat blue = (hexValue & 0xFF) / 255.0f;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
}

// MARK: - Gesture handling

- (void)textTapped:(UITapGestureRecognizer *)recognizer {
    /*
     * HOW LINK TAPPING WORKS:
     * 
     * 1. SETUP PHASE (During Rendering):
     *    - Each link gets a custom @"linkURL" attribute attached to its text range
     *    - The URL is stored as the attribute's value
     *    - This creates an "invisible map" of where links are in the text
     * 
     *    Example:
     *    Text: "Check out this [link to React Native](https://reactnative.dev)"
     *          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
     *          |     |     |     |     |     |     |     |     |     |     |
     *          0     5    10    15    20    25    30    35    40    45    50
     * 
     *    Attributes:
     *    - Characters 15-29: @"linkURL" = "https://reactnative.dev"
     *    - Characters 0-14: no special attributes
     *    - Characters 30-50: no special attributes
     * 
     * 2. TOUCH DETECTION PHASE (When User Taps):
     *    - UITapGestureRecognizer detects the tap
     *    - We get the tap coordinates relative to the text view
     *    - We adjust for text container insets to get precise text coordinates
     */
    
    UITextView *textView = (UITextView *)recognizer.view;
    
    // Location of the tap in text-container coordinates
    NSLayoutManager *layoutManager = textView.layoutManager;
    CGPoint location = [recognizer locationInView:textView];
    location.x -= textView.textContainerInset.left;
    location.y -= textView.textContainerInset.top;
    
    /*
     * 3. CHARACTER INDEX LOOKUP:
     *    - NSLayoutManager converts the tap coordinates to a character index
     *    - This tells us exactly which character in the text was tapped
     *    - Uses UIKit's built-in text layout system (very accurate)
     */
    NSUInteger characterIndex;
    characterIndex = [layoutManager characterIndexForPoint:location
                                           inTextContainer:textView.textContainer
                  fractionOfDistanceBetweenInsertionPoints:NULL];
    
    /*
     * 4. LINK DETECTION:
     *    - We check if there's a @"linkURL" attribute at the tapped character
     *    - If found, we get the URL value and the effective range
     *    - If it's a link, we emit the onLinkPress event to React Native
     * 
     * COMPLETE FLOW:
     * 1. User taps → UITapGestureRecognizer fires
     * 2. Get coordinates → Convert to text container coordinates  
     * 3. Find character → NSLayoutManager.characterIndexForPoint
     * 4. Check attributes → Look for @"linkURL" at that character
     * 5. If link found → Emit onLinkPress event with URL
     * 6. React Native → Receives event and shows alert
     */
    if (characterIndex < textView.textStorage.length) {
        NSRange range;
        NSString *url = [textView.attributedText attribute:@"linkURL" atIndex:characterIndex effectiveRange:&range];
        
        if (url) {            
            // Emit onLinkPress event to React Native
            const auto &eventEmitter = *std::static_pointer_cast<RichTextViewEventEmitter const>(_eventEmitter);
            eventEmitter.onLinkPress({
                .url = std::string([url UTF8String])
            });
        }
    }
}

// MARK: - Helper methods

- (UIFont *)createFontWithFamily:(NSString *)fontFamily size:(CGFloat)size {
    if (fontFamily && fontFamily.length > 0) {
        UIFont *customFont = [UIFont fontWithName:fontFamily size:size];
        if (customFont) {
            return customFont;
        }
    }
    
    return [UIFont systemFontOfSize:size];
}

@end
