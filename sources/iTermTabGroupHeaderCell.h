//
//  iTermTabGroupHeaderCell.h
//  iTerm2
//
//  A tab bar cell that represents a tab group header with collapse/expand functionality.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class iTermTabGroup;
@class iTermTabGroupHeaderCell;
@class PSMTabBarControl;
@protocol PSMTabStyle;

@protocol iTermTabGroupHeaderCellDelegate <NSObject>

// Called when the collapse/expand button is clicked
- (void)tabGroupHeaderCell:(iTermTabGroupHeaderCell *)cell didToggleCollapseForGroup:(iTermTabGroup *)group;

// Called when the group name is double-clicked for editing
- (void)tabGroupHeaderCell:(iTermTabGroupHeaderCell *)cell didRequestRenameForGroup:(iTermTabGroup *)group;

// Called when the color button is clicked
- (void)tabGroupHeaderCell:(iTermTabGroupHeaderCell *)cell didRequestColorChangeForGroup:(iTermTabGroup *)group;

// Context menu for the group header
- (NSMenu *)tabGroupHeaderCell:(iTermTabGroupHeaderCell *)cell menuForGroup:(iTermTabGroup *)group;

@end

@interface iTermTabGroupHeaderCell : NSActionCell

// The tab group this header represents
@property (nonatomic, strong) iTermTabGroup *tabGroup;

// Delegate for handling interactions
@property (nonatomic, weak) id<iTermTabGroupHeaderCellDelegate> delegate;

// Frame for this cell
@property (nonatomic, assign) NSRect frame;

// Style for rendering (from tab bar)
@property (nonatomic, weak) id<PSMTabStyle> style;

// Tab bar control reference
@property (nonatomic, weak) PSMTabBarControl *tabBarControl;

// Display properties
@property (nonatomic, readonly) CGFloat minimumWidth;
@property (nonatomic, readonly) CGFloat desiredWidth;

// Mouse tracking
@property (nonatomic, assign) BOOL isMouseOver;
@property (nonatomic, assign) BOOL isCollapseButtonHighlighted;

#pragma mark - Initialization

- (instancetype)initWithTabGroup:(iTermTabGroup *)group controlView:(PSMTabBarControl *)controlView;

#pragma mark - Drawing

// Draw the header cell
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;

#pragma mark - Hit Testing

// Check if a point is over the collapse/expand button
- (BOOL)isPointInCollapseButton:(NSPoint)point;

// Check if a point is over the color indicator
- (BOOL)isPointInColorIndicator:(NSPoint)point;

// Check if a point is over the group name
- (BOOL)isPointInNameArea:(NSPoint)point;

#pragma mark - Interaction Rects

// Rect for the collapse/expand button
- (NSRect)collapseButtonRectForFrame:(NSRect)cellFrame;

// Rect for the color indicator
- (NSRect)colorIndicatorRectForFrame:(NSRect)cellFrame;

// Rect for the group name label
- (NSRect)nameLabelRectForFrame:(NSRect)cellFrame;

// Rect for the tab count badge
- (NSRect)tabCountBadgeRectForFrame:(NSRect)cellFrame;

@end

NS_ASSUME_NONNULL_END
