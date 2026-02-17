#import "TableContainerView.h"
#import "AttributedRenderer.h"
#import "HTMLGenerator.h"
#import "LinkTapUtils.h"
#import "MarkdownASTNode.h"
#import "MarkdownASTSerializer.h"
#import "RenderContext.h"
#import "StyleConfig.h"
#import <UIKit/UIPasteboard.h>

@interface TableCellData : NSObject
@property (nonatomic, strong) NSMutableAttributedString *attributedText;
@property (nonatomic, copy) NSString *plainText;
@property (nonatomic, copy) NSString *markdownText;
@property (nonatomic, assign) BOOL isHeader;
@property (nonatomic, assign) NSTextAlignment alignment;
@end

@implementation TableCellData
@end

@interface TableContainerView () <UITextViewDelegate, UIContextMenuInteractionDelegate>
@end

@implementation TableContainerView {
  UIScrollView *_scrollView;
  UIView *_gridContainer;
  NSArray<NSArray<TableCellData *> *> *_rows;
  NSUInteger _colCount;

  NSMutableArray<NSNumber *> *_colWidths;
  NSMutableArray<NSNumber *> *_rowHeights;
  CGFloat _totalTableWidth;
  CGFloat _totalTableHeight;
  CGFloat _borderWidth;

  NSString *_cachedMarkdown;
}

- (instancetype)initWithConfig:(StyleConfig *)config
{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _config = config;
    _borderWidth = config.tableBorderWidth;
    _allowFontScaling = YES;
    _maxFontSizeMultiplier = 0;
    _enableLinkPreview = YES;
    [self setupScrollView];
  }
  return self;
}

- (void)setupScrollView
{
  _scrollView = [[UIScrollView alloc] init];
  _scrollView.showsVerticalScrollIndicator = NO;
  _scrollView.showsHorizontalScrollIndicator = YES;
  _scrollView.bounces = YES;
  _scrollView.alwaysBounceHorizontal = NO;
  [self addSubview:_scrollView];

  _gridContainer = [[UIView alloc] init];
  [_scrollView addSubview:_gridContainer];

  UIContextMenuInteraction *contextMenu = [[UIContextMenuInteraction alloc] initWithDelegate:self];
  [_gridContainer addInteraction:contextMenu];
}

- (StyleConfig *)cellConfigForHeader:(BOOL)isHeader
{
  StyleConfig *cellConfig = [self.config copy];

  [cellConfig setParagraphFontSize:self.config.tableFontSize];
  NSString *headerFamily =
      self.config.tableHeaderFontFamily.length > 0 ? self.config.tableHeaderFontFamily : self.config.tableFontFamily;
  [cellConfig setParagraphFontFamily:isHeader ? headerFamily : self.config.tableFontFamily];
  [cellConfig setParagraphFontWeight:isHeader ? @"bold" : self.config.tableFontWeight];
  [cellConfig setParagraphColor:isHeader ? self.config.tableHeaderTextColor : self.config.tableColor];
  [cellConfig setParagraphLineHeight:self.config.tableLineHeight];

  [cellConfig setParagraphMarginTop:0];
  [cellConfig setParagraphMarginBottom:0];

  return cellConfig;
}

- (NSMutableAttributedString *)renderCellNode:(MarkdownASTNode *)cellNode
                                     isHeader:(BOOL)isHeader
                                   cellConfig:(StyleConfig *)cellConfig
                                    alignment:(NSTextAlignment)alignment
{

  MarkdownASTNode *temporaryRoot = [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeDocument];
  for (MarkdownASTNode *child in cellNode.children) {
    [temporaryRoot addChild:child];
  }

  AttributedRenderer *renderer = [[AttributedRenderer alloc] initWithConfig:cellConfig];
  RenderContext *context = [RenderContext new];
  context.allowFontScaling = self.allowFontScaling;
  context.maxFontSizeMultiplier = self.maxFontSizeMultiplier;

  NSMutableAttributedString *attributedText = [renderer renderRoot:temporaryRoot context:context];

  [context applyLinkAttributesToString:attributedText];

  if (alignment != NSTextAlignmentLeft && attributedText.length > 0) {
    NSRange fullRange = NSMakeRange(0, attributedText.length);
    [attributedText
        enumerateAttribute:NSParagraphStyleAttributeName
                   inRange:fullRange
                   options:0
                usingBlock:^(NSParagraphStyle *paragraphStyle, NSRange range, BOOL *stop) {
                  NSMutableParagraphStyle *mutableStyle =
                      paragraphStyle ? [paragraphStyle mutableCopy] : [[NSMutableParagraphStyle alloc] init];
                  mutableStyle.alignment = alignment;
                  [attributedText addAttribute:NSParagraphStyleAttributeName value:mutableStyle range:range];
                }];
  }

  return attributedText;
}

- (NSString *)extractPlainTextFromNode:(MarkdownASTNode *)node
{
  if (!node)
    return @"";
  NSMutableString *buffer = [node.content mutableCopy] ?: [NSMutableString string];
  for (MarkdownASTNode *child in node.children) {
    [buffer appendString:[self extractPlainTextFromNode:child]];
  }
  return [buffer copy];
}

- (void)applyTableNode:(MarkdownASTNode *)tableNode
{
  [[_gridContainer subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

  StyleConfig *headerCellConfig = [self cellConfigForHeader:YES];
  StyleConfig *bodyCellConfig = [self cellConfigForHeader:NO];

  NSMutableArray *allRows = [NSMutableArray array];
  _colCount = 0;

  for (MarkdownASTNode *section in tableNode.children) {
    BOOL isSectionHead = (section.type == MarkdownNodeTypeTableHead);

    for (MarkdownASTNode *rowNode in section.children) {
      if (rowNode.type != MarkdownNodeTypeTableRow)
        continue;

      NSMutableArray<TableCellData *> *rowCells = [NSMutableArray array];
      for (MarkdownASTNode *cellNode in rowNode.children) {
        TableCellData *cell = [[TableCellData alloc] init];
        cell.isHeader = isSectionHead || (cellNode.type == MarkdownNodeTypeTableHeaderCell);
        cell.alignment = [self textAlignmentFromString:cellNode.attributes[@"align"]];
        cell.plainText = [self extractPlainTextFromNode:cellNode];
        cell.markdownText = markdownFromASTNodeChildren(cellNode);

        StyleConfig *cellConfig = cell.isHeader ? headerCellConfig : bodyCellConfig;
        cell.attributedText = [self renderCellNode:cellNode
                                          isHeader:cell.isHeader
                                        cellConfig:cellConfig
                                         alignment:cell.alignment];
        [rowCells addObject:cell];
      }
      _colCount = MAX(_colCount, rowCells.count);
      [allRows addObject:rowCells];
    }
  }

  _rows = [allRows copy];
  _cachedMarkdown = [self buildMarkdownFromRows];
  [self computeLayout];
  [self renderGrid];
}

- (NSTextAlignment)textAlignmentFromString:(NSString *)align
{
  if ([align isEqualToString:@"center"])
    return NSTextAlignmentCenter;
  if ([align isEqualToString:@"right"])
    return NSTextAlignmentRight;
  return NSTextAlignmentLeft;
}

- (void)computeLayout
{
  // TODO: Consider making minColumnWidth / maxColumnWidth configurable via style props
  const CGFloat minimumColumnWidth = 60.0;
  const CGFloat maximumColumnWidth = 300.0;
  const CGFloat horizontalPadding = self.config.tableCellPaddingHorizontal * 2;
  const CGFloat verticalPadding = self.config.tableCellPaddingVertical * 2;

  _colWidths = [NSMutableArray arrayWithCapacity:_colCount];
  for (NSUInteger i = 0; i < _colCount; i++)
    [_colWidths addObject:@0];

  for (NSArray<TableCellData *> *row in _rows) {
    for (NSUInteger column = 0; column < row.count; column++) {
      CGRect boundingRect = [row[column].attributedText
          boundingRectWithSize:CGSizeMake(maximumColumnWidth, CGFLOAT_MAX)
                       options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                       context:nil];
      CGFloat width = MIN(MAX(ceil(boundingRect.size.width) + horizontalPadding, minimumColumnWidth),
                          maximumColumnWidth + horizontalPadding);
      if (width > [_colWidths[column] doubleValue])
        _colWidths[column] = @(width);
    }
  }

  _rowHeights = [NSMutableArray arrayWithCapacity:_rows.count];
  for (NSArray<TableCellData *> *row in _rows) {
    CGFloat maxHeight = 0;
    for (NSUInteger column = 0; column < row.count; column++) {
      CGFloat availableWidth = [_colWidths[column] doubleValue] - horizontalPadding;
      CGRect boundingRect = [row[column].attributedText
          boundingRectWithSize:CGSizeMake(availableWidth, CGFLOAT_MAX)
                       options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                       context:nil];
      maxHeight = MAX(maxHeight, ceil(boundingRect.size.height) + verticalPadding);
    }
    [_rowHeights addObject:@(maxHeight)];
  }

  _totalTableWidth = [[_colWidths valueForKeyPath:@"@sum.self"] doubleValue] + _borderWidth;
  _totalTableHeight = [[_rowHeights valueForKeyPath:@"@sum.self"] doubleValue] + _borderWidth;
}

- (void)renderGrid
{
  _gridContainer.frame = CGRectMake(0, 0, _totalTableWidth, _totalTableHeight);
  _gridContainer.layer.cornerRadius = self.config.tableBorderRadius;
  _gridContainer.layer.masksToBounds = YES;

  CGFloat yOffset = 0;
  NSUInteger bodyRowIndex = 0;

  for (NSUInteger r = 0; r < _rows.count; r++) {
    NSArray<TableCellData *> *row = _rows[r];
    CGFloat rowHeight = [_rowHeights[r] doubleValue];
    BOOL isHeaderRow = (row.count > 0 && row.firstObject.isHeader);

    [self renderRow:row atY:yOffset height:rowHeight isHeader:isHeaderRow bodyIndex:bodyRowIndex];

    if (!isHeaderRow)
      bodyRowIndex++;
    yOffset += rowHeight;
  }
}

- (void)renderRow:(NSArray<TableCellData *> *)row
              atY:(CGFloat)yOffset
           height:(CGFloat)height
         isHeader:(BOOL)isHeader
        bodyIndex:(NSUInteger)bodyIndex
{

  CGFloat xOffset = 0;
  UIColor *rowBackground = isHeader ? self.config.tableHeaderBackgroundColor
                                    : (bodyIndex % 2 == 0 ? self.config.tableRowEvenBackgroundColor
                                                          : self.config.tableRowOddBackgroundColor);

  for (NSUInteger column = 0; column < _colCount; column++) {
    CGFloat columnWidth = [_colWidths[column] doubleValue];
    CGRect cellFrame = CGRectMake(xOffset, yOffset, columnWidth + _borderWidth, height + _borderWidth);

    UIView *cellBackground = [[UIView alloc] initWithFrame:cellFrame];
    cellBackground.backgroundColor = rowBackground;
    cellBackground.layer.borderColor = self.config.tableBorderColor.CGColor;
    cellBackground.layer.borderWidth = _borderWidth;
    [_gridContainer addSubview:cellBackground];

    if (column < row.count) {
      [self addTextToCell:cellBackground data:row[column] width:columnWidth height:height];
    }
    xOffset += columnWidth;
  }
}

- (void)addTextToCell:(UIView *)container data:(TableCellData *)data width:(CGFloat)width height:(CGFloat)height
{
  const CGFloat horizontalPadding = self.config.tableCellPaddingHorizontal;
  const CGFloat verticalPadding = self.config.tableCellPaddingVertical;

  UITextView *cellTextView = [self createCellTextView];
  cellTextView.frame =
      CGRectMake(horizontalPadding, verticalPadding, width - (horizontalPadding * 2), height - (verticalPadding * 2));
  cellTextView.attributedText = data.attributedText;
  [container addSubview:cellTextView];
}

- (UITextView *)createCellTextView
{
  UITextView *textView = [[UITextView alloc] init];
  textView.editable = NO;
  textView.scrollEnabled = NO;
  textView.selectable = NO;
  textView.backgroundColor = [UIColor clearColor];
  textView.textContainerInset = UIEdgeInsetsZero;
  textView.textContainer.lineFragmentPadding = 0;
  textView.linkTextAttributes = @{};
  textView.accessibilityElementsHidden = YES;
  textView.delegate = self;

  UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(cellTextTapped:)];
  [textView addGestureRecognizer:tapRecognizer];
  return textView;
}

- (void)cellTextTapped:(UITapGestureRecognizer *)recognizer
{
  UITextView *textView = (UITextView *)recognizer.view;
  NSString *url = linkURLAtTapLocation(textView, recognizer);
  if (url && self.onLinkPress)
    self.onLinkPress(url);
}

- (BOOL)textView:(UITextView *)textView
    shouldInteractWithURL:(NSURL *)URL
                  inRange:(NSRange)range
              interaction:(UITextItemInteraction)interaction
{
  if (interaction != UITextItemInteractionPresentActions)
    return YES;

  NSString *urlString = linkURLAtRange(textView, range);
  if (!urlString || self.enableLinkPreview)
    return YES;

  if (self.onLinkLongPress)
    self.onLinkLongPress(urlString);
  return NO;
}

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction
                        configurationForMenuAtLocation:(CGPoint)location
{
  return [UIContextMenuConfiguration
      configurationWithIdentifier:nil
                  previewProvider:nil
                   actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
                     UIAction *copyMarkdown =
                         [UIAction actionWithTitle:@"Copy as Markdown"
                                             image:[UIImage systemImageNamed:@"doc.text"]
                                        identifier:nil
                                           handler:^(__kindof UIAction *action) { [self copyMarkdownToPasteboard]; }];

                     UIAction *copyPlainText =
                         [UIAction actionWithTitle:@"Copy"
                                             image:[UIImage systemImageNamed:@"doc.on.doc"]
                                        identifier:nil
                                           handler:^(__kindof UIAction *action) { [self copyTableToPasteboard]; }];

                     return [UIMenu menuWithTitle:@"" children:@[ copyPlainText, copyMarkdown ]];
                   }];
}

- (void)copyMarkdownToPasteboard
{
  if (_cachedMarkdown.length > 0) {
    [[UIPasteboard generalPasteboard] setString:_cachedMarkdown];
  }
}

- (void)copyTableToPasteboard
{
  NSString *plainText = [self buildPlainTextFromRows];
  if (plainText.length == 0)
    return;

  NSMutableDictionary *items = [NSMutableDictionary dictionary];
  items[@"public.utf8-plain-text"] = plainText;

  if (_cachedMarkdown.length > 0) {
    items[@"net.daringfireball.markdown"] = _cachedMarkdown;
  }

  NSString *html = generateTableHTML([self rowDictionariesForHTML], self.config);
  if (html.length > 0) {
    NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    if (htmlData)
      items[@"public.html"] = htmlData;
  }

  [[UIPasteboard generalPasteboard] setItems:@[ items ]];
}

- (NSString *)buildMarkdownFromRows
{
  if (_rows.count == 0 || _colCount == 0)
    return @"";

  NSMutableString *markdown = [NSMutableString string];
  BOOL headerSeparatorAdded = NO;

  for (NSArray<TableCellData *> *row in _rows) {
    NSMutableArray<NSString *> *cellStrings = [NSMutableArray arrayWithCapacity:_colCount];

    for (NSUInteger column = 0; column < _colCount; column++) {
      NSString *cellMarkdown = (column < row.count) ? (row[column].markdownText ?: @"") : @"";
      [cellStrings addObject:cellMarkdown];
    }

    [markdown appendFormat:@"| %@ |\n", [cellStrings componentsJoinedByString:@" | "]];

    if (!headerSeparatorAdded && row.count > 0 && row.firstObject.isHeader) {
      NSMutableArray<NSString *> *separators = [NSMutableArray arrayWithCapacity:_colCount];

      for (NSUInteger column = 0; column < _colCount; column++) {
        NSTextAlignment columnAlignment = (column < row.count) ? row[column].alignment : NSTextAlignmentLeft;

        switch (columnAlignment) {
          case NSTextAlignmentCenter:
            [separators addObject:@":---:"];
            break;
          case NSTextAlignmentRight:
            [separators addObject:@"---:"];
            break;
          default:
            [separators addObject:@"---"];
            break;
        }
      }

      [markdown appendFormat:@"| %@ |\n", [separators componentsJoinedByString:@" | "]];
      headerSeparatorAdded = YES;
    }
  }

  return [markdown copy];
}

- (NSString *)buildPlainTextFromRows
{
  if (_rows.count == 0)
    return @"";

  NSMutableString *result = [NSMutableString string];

  for (NSArray<TableCellData *> *row in _rows) {
    NSMutableArray<NSString *> *rowContent = [NSMutableArray arrayWithCapacity:row.count];

    for (TableCellData *cell in row) {
      [rowContent addObject:cell.plainText ?: @""];
    }

    [result appendFormat:@"%@\n", [rowContent componentsJoinedByString:@"\t"]];
  }

  return [result copy];
}

- (NSArray<NSArray<NSDictionary *> *> *)rowDictionariesForHTML
{
  NSMutableArray *rowsResult = [NSMutableArray arrayWithCapacity:_rows.count];

  for (NSArray<TableCellData *> *cellDataRow in _rows) {
    NSMutableArray *rowDictionaries = [NSMutableArray arrayWithCapacity:cellDataRow.count];

    for (TableCellData *cell in cellDataRow) {
      NSAttributedString *text = cell.attributedText ?: [[NSAttributedString alloc] init];

      NSDictionary *cellDict =
          @{@"attributedText" : text, @"isHeader" : @(cell.isHeader), @"alignment" : @(cell.alignment)};

      [rowDictionaries addObject:cellDict];
    }

    [rowsResult addObject:[rowDictionaries copy]];
  }

  return [rowsResult copy];
}

- (CGFloat)measureHeight:(CGFloat)maxWidth
{
  if (_rows.count == 0)
    return 0;
  if (_rowHeights.count == 0)
    [self computeLayout];
  return _totalTableHeight;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  _scrollView.frame = self.bounds;
  _scrollView.contentSize = CGSizeMake(MAX(_totalTableWidth, self.bounds.size.width), _totalTableHeight);
  _scrollView.scrollEnabled = (_totalTableWidth > self.bounds.size.width);
  _gridContainer.frame = CGRectMake(0, 0, _totalTableWidth, _totalTableHeight);
}

- (BOOL)isAccessibilityElement
{
  return NO;
}

- (NSArray *)accessibilityElements
{
  if (_rows.count == 0)
    return nil;

  NSMutableArray *elements = [NSMutableArray array];
  CGFloat yOffset = 0;

  for (NSUInteger rowIndex = 0; rowIndex < _rows.count; rowIndex++) {
    NSArray<TableCellData *> *row = _rows[rowIndex];
    CGFloat rowHeight = [_rowHeights[rowIndex] doubleValue];

    NSMutableArray *cellTexts = [NSMutableArray array];
    for (TableCellData *cell in row) {
      if (cell.plainText.length > 0)
        [cellTexts addObject:cell.plainText];
    }

    if (cellTexts.count > 0) {
      UIAccessibilityElement *element = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
      element.accessibilityLabel = [NSString
          stringWithFormat:@"Row %lu: %@", (unsigned long)(rowIndex + 1), [cellTexts componentsJoinedByString:@", "]];
      element.accessibilityFrameInContainerSpace = CGRectMake(0, yOffset, _totalTableWidth, rowHeight);
      element.accessibilityTraits =
          row.firstObject.isHeader ? UIAccessibilityTraitHeader : UIAccessibilityTraitStaticText;
      [elements addObject:element];
    }
    yOffset += rowHeight;
  }
  return elements;
}

@end