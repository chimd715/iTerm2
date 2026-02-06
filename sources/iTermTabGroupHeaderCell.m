//
//  iTermTabGroupHeaderCell.m
//  iTerm2
//
//  A tab bar cell that represents a tab group header with collapse/expand functionality.
//

#import "iTermTabGroupHeaderCell.h"
#import "iTermTabGroup.h"
#import "NSColor+iTerm.h"
#import "PSMTabBarControl.h"

static const CGFloat kCollapseButtonSize = 12.0;
static const CGFloat kColorIndicatorSize = 10.0;
static const CGFloat kPadding = 6.0;
static const CGFloat kMinimumNameWidth = 30.0;

@implementation iTermTabGroupHeaderCell

#pragma mark - Initialization

- (instancetype)initWithTabGroup:(iTermTabGroup *)group controlView:(PSMTabBarControl *)tabBarControl {
    self = [super init];
    if (self) {
        _tabGroup = group;
        _tabBarControl = tabBarControl;
    }
    return self;
}

#pragma mark - Width Calculations

- (CGFloat)minimumWidth {
    // Collapse button + color indicator + min name width + padding
    return kPadding + kCollapseButtonSize + kPadding + kColorIndicatorSize + kPadding +
           kMinimumNameWidth + kPadding + [self tabCountBadgeWidth] + kPadding;
}

- (CGFloat)desiredWidth {
    CGFloat nameWidth = [self nameWidth];
    return kPadding + kCollapseButtonSize + kPadding + kColorIndicatorSize + kPadding +
           nameWidth + kPadding + [self tabCountBadgeWidth] + kPadding;
}

- (CGFloat)nameWidth {
    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightMedium]
    };
    NSString *name = self.tabGroup.name ?: @"";
    return ceil([name sizeWithAttributes:attributes].width);
}

- (CGFloat)tabCountBadgeWidth {
    NSString *countText = [NSString stringWithFormat:@"%lu", (unsigned long)self.tabGroup.tabCount];
    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont systemFontOfSize:9 weight:NSFontWeightMedium]
    };
    return ceil([countText sizeWithAttributes:attributes].width) + 8;  // Extra padding for badge
}

#pragma mark - Drawing

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    self.frame = cellFrame;

    // Draw background with group color tint
    [self drawBackgroundWithFrame:cellFrame];

    // Draw collapse/expand button
    [self drawCollapseButtonWithFrame:[self collapseButtonRectForFrame:cellFrame]];

    // Draw color indicator
    [self drawColorIndicatorWithFrame:[self colorIndicatorRectForFrame:cellFrame]];

    // Draw group name
    [self drawNameLabelWithFrame:[self nameLabelRectForFrame:cellFrame]];

    // Draw tab count badge
    [self drawTabCountBadgeWithFrame:[self tabCountBadgeRectForFrame:cellFrame]];
}

- (void)drawBackgroundWithFrame:(NSRect)frame {
    NSColor *baseColor = self.tabGroup.color ?: [NSColor secondaryLabelColor];

    // Create a subtle tint based on the group color
    NSColor *bgColor = [[baseColor colorWithAlphaComponent:0.15] blendedColorWithFraction:0.5
                                                                                   ofColor:[NSColor windowBackgroundColor]];

    [bgColor setFill];
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(frame, 1, 2)
                                                         xRadius:4
                                                         yRadius:4];
    [path fill];

    // Draw subtle border
    NSColor *borderColor = [baseColor colorWithAlphaComponent:0.3];
    [borderColor setStroke];
    path.lineWidth = 0.5;
    [path stroke];
}

- (void)drawCollapseButtonWithFrame:(NSRect)buttonRect {
    // Draw the expand/collapse chevron
    NSColor *color = self.isCollapseButtonHighlighted ?
                     [NSColor labelColor] :
                     [NSColor secondaryLabelColor];
    [color setStroke];

    NSBezierPath *chevron = [NSBezierPath bezierPath];
    chevron.lineWidth = 1.5;
    chevron.lineCapStyle = NSLineCapStyleRound;
    chevron.lineJoinStyle = NSLineJoinStyleRound;

    CGFloat centerX = NSMidX(buttonRect);
    CGFloat centerY = NSMidY(buttonRect);
    CGFloat size = 4.0;

    if (self.tabGroup.collapsed) {
        // Right-pointing chevron (collapsed)
        [chevron moveToPoint:NSMakePoint(centerX - size * 0.5, centerY - size)];
        [chevron lineToPoint:NSMakePoint(centerX + size * 0.5, centerY)];
        [chevron lineToPoint:NSMakePoint(centerX - size * 0.5, centerY + size)];
    } else {
        // Down-pointing chevron (expanded)
        [chevron moveToPoint:NSMakePoint(centerX - size, centerY - size * 0.5)];
        [chevron lineToPoint:NSMakePoint(centerX, centerY + size * 0.5)];
        [chevron lineToPoint:NSMakePoint(centerX + size, centerY - size * 0.5)];
    }

    [chevron stroke];
}

- (void)drawColorIndicatorWithFrame:(NSRect)colorRect {
    NSColor *color = self.tabGroup.color ?: [NSColor tertiaryLabelColor];
    [color setFill];

    NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:colorRect];
    [circle fill];

    // Draw a subtle border
    [[color shadowWithLevel:0.2] setStroke];
    circle.lineWidth = 0.5;
    [circle stroke];
}

- (void)drawNameLabelWithFrame:(NSRect)labelRect {
    NSString *name = self.tabGroup.name ?: @"Group";

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByTruncatingTail;
    style.alignment = NSTextAlignmentLeft;

    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: [NSColor labelColor],
        NSParagraphStyleAttributeName: style
    };

    [name drawInRect:labelRect withAttributes:attributes];
}

- (void)drawTabCountBadgeWithFrame:(NSRect)badgeRect {
    if (self.tabGroup.tabCount == 0) {
        return;
    }

    // Draw badge background
    NSColor *badgeBg = self.tabGroup.color ?
                       [self.tabGroup.color colorWithAlphaComponent:0.3] :
                       [NSColor tertiarySystemFillColor];
    [badgeBg setFill];

    NSBezierPath *badge = [NSBezierPath bezierPathWithRoundedRect:badgeRect
                                                          xRadius:badgeRect.size.height / 2
                                                          yRadius:badgeRect.size.height / 2];
    [badge fill];

    // Draw count text
    NSString *countText = [NSString stringWithFormat:@"%lu", (unsigned long)self.tabGroup.tabCount];

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;

    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont systemFontOfSize:9 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: [NSColor secondaryLabelColor],
        NSParagraphStyleAttributeName: style
    };

    NSSize textSize = [countText sizeWithAttributes:attributes];
    NSRect textRect = NSMakeRect(NSMidX(badgeRect) - textSize.width / 2,
                                  NSMidY(badgeRect) - textSize.height / 2,
                                  textSize.width,
                                  textSize.height);
    [countText drawInRect:textRect withAttributes:attributes];
}

#pragma mark - Interaction Rects

- (NSRect)collapseButtonRectForFrame:(NSRect)cellFrame {
    return NSMakeRect(cellFrame.origin.x + kPadding,
                      NSMidY(cellFrame) - kCollapseButtonSize / 2,
                      kCollapseButtonSize,
                      kCollapseButtonSize);
}

- (NSRect)colorIndicatorRectForFrame:(NSRect)cellFrame {
    CGFloat x = cellFrame.origin.x + kPadding + kCollapseButtonSize + kPadding;
    return NSMakeRect(x,
                      NSMidY(cellFrame) - kColorIndicatorSize / 2,
                      kColorIndicatorSize,
                      kColorIndicatorSize);
}

- (NSRect)nameLabelRectForFrame:(NSRect)cellFrame {
    CGFloat x = cellFrame.origin.x + kPadding + kCollapseButtonSize + kPadding +
                kColorIndicatorSize + kPadding;
    CGFloat badgeWidth = [self tabCountBadgeWidth] + kPadding;
    CGFloat width = cellFrame.size.width - x - badgeWidth - kPadding + cellFrame.origin.x;

    return NSMakeRect(x,
                      NSMidY(cellFrame) - 7,  // Approximate text height / 2
                      MAX(width, 0),
                      14);
}

- (NSRect)tabCountBadgeRectForFrame:(NSRect)cellFrame {
    CGFloat badgeWidth = [self tabCountBadgeWidth];
    CGFloat badgeHeight = 14;
    return NSMakeRect(NSMaxX(cellFrame) - kPadding - badgeWidth,
                      NSMidY(cellFrame) - badgeHeight / 2,
                      badgeWidth,
                      badgeHeight);
}

#pragma mark - Hit Testing

- (BOOL)isPointInCollapseButton:(NSPoint)point {
    NSRect buttonRect = [self collapseButtonRectForFrame:self.frame];
    // Expand hit area slightly for easier clicking
    buttonRect = NSInsetRect(buttonRect, -4, -4);
    return NSPointInRect(point, buttonRect);
}

- (BOOL)isPointInColorIndicator:(NSPoint)point {
    NSRect colorRect = [self colorIndicatorRectForFrame:self.frame];
    colorRect = NSInsetRect(colorRect, -4, -4);
    return NSPointInRect(point, colorRect);
}

- (BOOL)isPointInNameArea:(NSPoint)point {
    NSRect nameRect = [self nameLabelRectForFrame:self.frame];
    return NSPointInRect(point, nameRect);
}

#pragma mark - Mouse Events

- (void)mouseDown:(NSEvent *)event {
    NSPoint point = [self.tabBarControl convertPoint:event.locationInWindow fromView:nil];

    if ([self isPointInCollapseButton:point]) {
        [self.delegate tabGroupHeaderCell:self didToggleCollapseForGroup:self.tabGroup];
    } else if ([self isPointInColorIndicator:point]) {
        [self.delegate tabGroupHeaderCell:self didRequestColorChangeForGroup:self.tabGroup];
    }
}

- (void)mouseDoubleClick:(NSEvent *)event {
    NSPoint point = [self.tabBarControl convertPoint:event.locationInWindow fromView:nil];

    if ([self isPointInNameArea:point]) {
        [self.delegate tabGroupHeaderCell:self didRequestRenameForGroup:self.tabGroup];
    }
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
    return [self.delegate tabGroupHeaderCell:self menuForGroup:self.tabGroup];
}

@end
