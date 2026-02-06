//
//  iTermTabGroupManager.h
//  iTerm2
//
//  Manages tab groups within a window.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class iTermTabGroup;
@class PTYTab;
@class PseudoTerminal;

extern NSString *const iTermTabGroupManagerDidChangeNotification;
extern NSString *const kTabGroupManagerArrangementGroups;

@protocol iTermTabGroupManagerDelegate <NSObject>

// Called when a tab group's collapsed state changes
- (void)tabGroupManager:(id)manager didChangeCollapsedStateForGroup:(iTermTabGroup *)group;

// Called when tabs need to be reordered in the tab bar
- (void)tabGroupManagerNeedsTabBarUpdate:(id)manager;

// Get tab by GUID
- (nullable PTYTab *)tabGroupManager:(id)manager tabWithGUID:(NSString *)guid;

// Get all tabs
- (NSArray<PTYTab *> *)tabGroupManagerAllTabs:(id)manager;

// Move a tab to a new index in the tab bar (for keeping groups contiguous)
- (void)tabGroupManager:(id)manager moveTabAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

// Get the current index of a tab in the tab bar
- (NSUInteger)tabGroupManager:(id)manager indexOfTab:(PTYTab *)tab;

@end

@interface iTermTabGroupManager : NSObject

@property (nonatomic, weak) id<iTermTabGroupManagerDelegate> delegate;

// All tab groups (ordered)
@property (nonatomic, readonly) NSArray<iTermTabGroup *> *tabGroups;

#pragma mark - Initialization

- (instancetype)init NS_DESIGNATED_INITIALIZER;

#pragma mark - Group Management

// Create a new tab group
- (iTermTabGroup *)createGroupWithName:(NSString *)name
                                 color:(nullable NSColor *)color;

// Create a new tab group with initial tabs
- (iTermTabGroup *)createGroupWithName:(NSString *)name
                                 color:(nullable NSColor *)color
                                  tabs:(NSArray<PTYTab *> *)tabs;

// Remove a tab group (tabs are ungrouped, not removed)
- (void)removeGroup:(iTermTabGroup *)group;

// Get group for a tab
- (nullable iTermTabGroup *)groupForTab:(PTYTab *)tab;

// Get group by GUID
- (nullable iTermTabGroup *)groupWithGUID:(NSString *)guid;

#pragma mark - Tab-Group Assignment

// Add a tab to a group
- (void)addTab:(PTYTab *)tab toGroup:(iTermTabGroup *)group;

// Add a tab to a group at a specific index
- (void)addTab:(PTYTab *)tab toGroup:(iTermTabGroup *)group atIndex:(NSUInteger)index;

// Remove a tab from its group (ungroup)
- (void)removeTabFromGroup:(PTYTab *)tab;

// Move a tab from one group to another
- (void)moveTab:(PTYTab *)tab toGroup:(iTermTabGroup *)group;

// Move a tab to a specific position in a group
- (void)moveTab:(PTYTab *)tab toGroup:(iTermTabGroup *)group atIndex:(NSUInteger)index;

#pragma mark - Group Reordering

// Move a group to a new index
- (void)moveGroupAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

#pragma mark - Collapse/Expand

// Collapse a group (hide its tabs except the representative)
- (void)collapseGroup:(iTermTabGroup *)group;

// Expand a group (show all tabs)
- (void)expandGroup:(iTermTabGroup *)group;

// Toggle collapsed state
- (void)toggleCollapseGroup:(iTermTabGroup *)group;

// Check if a tab should be visible (not hidden due to collapsed group)
- (BOOL)isTabVisible:(PTYTab *)tab;

// Get the representative tab for a collapsed group (first tab)
- (nullable PTYTab *)representativeTabForGroup:(iTermTabGroup *)group;

#pragma mark - Tab Order

// Get tabs in display order (respecting groups and collapsed state)
- (NSArray<PTYTab *> *)tabsInDisplayOrder;

// Get all visible tabs (tabs not hidden due to collapsed groups)
- (NSArray<PTYTab *> *)visibleTabs;

// Get hidden tabs (tabs hidden due to collapsed groups)
- (NSArray<PTYTab *> *)hiddenTabs;

#pragma mark - Persistence

// Get arrangement for saving
- (NSDictionary *)arrangement;

// Restore from arrangement
- (void)restoreFromArrangement:(NSDictionary *)arrangement;

#pragma mark - Tab Lifecycle

// Called when a tab is added to the window
- (void)tabWasAdded:(PTYTab *)tab;

// Called when a tab is removed from the window
- (void)tabWasRemoved:(PTYTab *)tab;

// Called when tabs are reordered in the tab bar (via drag)
- (void)tabsWereReordered:(NSArray<PTYTab *> *)tabs;

// Ensure grouped tabs are contiguous in the tab bar (call after adding a tab to a group)
- (void)ensureGroupedTabsAreContiguous;

// Reorder a tab within its group
- (void)moveTab:(PTYTab *)tab withinGroupToIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
