//
//  PseudoTerminal+TabGroups.h
//  iTerm2
//
//  Tab group management extension for PseudoTerminal.
//

#import "PseudoTerminal.h"

NS_ASSUME_NONNULL_BEGIN

@class iTermTabGroup;
@class iTermTabGroupManager;
@class PTYTab;

@interface PseudoTerminal (TabGroups)

// The tab group manager for this window
@property (nonatomic, readonly) iTermTabGroupManager *tabGroupManager;

#pragma mark - Tab Group Management

// Create a new tab group with the currently selected tabs
- (iTermTabGroup *)createTabGroupWithSelectedTabs;

// Create a new tab group with specific tabs
- (iTermTabGroup *)createTabGroupWithTabs:(NSArray<PTYTab *> *)tabs
                                     name:(nullable NSString *)name
                                    color:(nullable NSColor *)color;

// Add the current tab to an existing group
- (void)addCurrentTabToGroup:(iTermTabGroup *)group;

// Remove the current tab from its group
- (void)removeCurrentTabFromGroup;

// Ungroup all tabs in a group
- (void)ungroupTabGroup:(iTermTabGroup *)group;

// Delete a tab group and all its tabs
- (void)closeTabGroup:(iTermTabGroup *)group;

#pragma mark - Tab Group Navigation

// Select the next visible tab (respecting collapsed groups)
- (void)selectNextVisibleTab;

// Select the previous visible tab (respecting collapsed groups)
- (void)selectPreviousVisibleTab;

// Select the first tab in a group
- (void)selectGroup:(iTermTabGroup *)group;

#pragma mark - Tab Group Actions

// Toggle collapse state of a group
- (void)toggleCollapseTabGroup:(iTermTabGroup *)group;

// Rename a tab group (shows editor popover)
- (void)renameTabGroup:(iTermTabGroup *)group;

// Change color of a tab group (shows color picker)
- (void)changeColorOfTabGroup:(iTermTabGroup *)group;

#pragma mark - Context Menu

// Returns the context menu for tab groups
- (NSMenu *)tabGroupContextMenuForTab:(PTYTab *)tab;

// Returns the context menu for a tab group header
- (NSMenu *)contextMenuForTabGroup:(iTermTabGroup *)group;

#pragma mark - Arrangement

// Key for tab groups in terminal arrangement
extern NSString *const TERMINAL_ARRANGEMENT_TAB_GROUPS;

// Include tab groups in arrangement
- (void)addTabGroupsToArrangement:(NSMutableDictionary *)arrangement;

// Restore tab groups from arrangement
- (void)restoreTabGroupsFromArrangement:(NSDictionary *)arrangement;

@end

NS_ASSUME_NONNULL_END
