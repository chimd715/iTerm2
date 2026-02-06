//
//  iTermTabGroup.h
//  iTerm2
//
//  Tab group model for grouping tabs with collapse/expand, name, and color support.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const iTermTabGroupDidChangeNotification;
extern NSString *const iTermTabGroupCollapsedStateDidChangeNotification;

// Arrangement keys
extern NSString *const kTabGroupArrangementGUID;
extern NSString *const kTabGroupArrangementName;
extern NSString *const kTabGroupArrangementColorData;
extern NSString *const kTabGroupArrangementCollapsed;
extern NSString *const kTabGroupArrangementTabGUIDs;

@class PTYTab;

@interface iTermTabGroup : NSObject <NSCopying>

// Unique identifier for this group
@property (nonatomic, readonly, copy) NSString *guid;

// Display name for the group
@property (nonatomic, copy) NSString *name;

// Color associated with the group (for visual identification)
@property (nonatomic, strong, nullable) NSColor *color;

// Whether the group is currently collapsed (tabs hidden)
@property (nonatomic, getter=isCollapsed) BOOL collapsed;

// GUIDs of tabs in this group (ordered)
@property (nonatomic, readonly) NSArray<NSString *> *tabGUIDs;

// Number of tabs in the group
@property (nonatomic, readonly) NSUInteger tabCount;

#pragma mark - Initialization

// Create a new tab group with a generated GUID
- (instancetype)initWithName:(NSString *)name color:(nullable NSColor *)color;

// Create a tab group with a specific GUID (for restoration)
- (instancetype)initWithGUID:(NSString *)guid
                        name:(NSString *)name
                       color:(nullable NSColor *)color
                   collapsed:(BOOL)collapsed NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Tab Management

// Add a tab to the group
- (void)addTabWithGUID:(NSString *)tabGUID;

// Add a tab at a specific index
- (void)insertTabWithGUID:(NSString *)tabGUID atIndex:(NSUInteger)index;

// Remove a tab from the group
- (void)removeTabWithGUID:(NSString *)tabGUID;

// Check if a tab is in this group
- (BOOL)containsTabWithGUID:(NSString *)tabGUID;

// Get index of a tab in the group
- (NSUInteger)indexOfTabWithGUID:(NSString *)tabGUID;

// Move a tab within the group
- (void)moveTabWithGUID:(NSString *)tabGUID toIndex:(NSUInteger)newIndex;

// Remove all tabs from the group
- (void)removeAllTabs;

#pragma mark - Collapse/Expand

// Toggle collapsed state
- (void)toggleCollapsed;

#pragma mark - Arrangement (Persistence)

// Create arrangement dictionary for saving
- (NSDictionary *)arrangement;

// Create from arrangement dictionary
+ (nullable instancetype)tabGroupFromArrangement:(NSDictionary *)arrangement;

#pragma mark - Predefined Colors

// Returns an array of predefined colors for tab groups
+ (NSArray<NSColor *> *)predefinedColors;

// Returns color name for display
+ (NSString *)nameForColor:(NSColor *)color;

@end

NS_ASSUME_NONNULL_END
