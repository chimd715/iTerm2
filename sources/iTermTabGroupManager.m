//
//  iTermTabGroupManager.m
//  iTerm2
//
//  Manages tab groups within a window.
//

#import "iTermTabGroupManager.h"
#import "iTermTabGroup.h"
#import "PTYTab.h"

NSString *const iTermTabGroupManagerDidChangeNotification = @"iTermTabGroupManagerDidChangeNotification";
NSString *const kTabGroupManagerArrangementGroups = @"Tab Groups";

@implementation iTermTabGroupManager {
    NSMutableArray<iTermTabGroup *> *_tabGroups;
    NSMutableDictionary<NSString *, iTermTabGroup *> *_tabToGroupMap;  // tabGUID -> group
}

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        _tabGroups = [[NSMutableArray alloc] init];
        _tabToGroupMap = [[NSMutableDictionary alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(tabGroupDidChange:)
                                                     name:iTermTabGroupDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(tabGroupCollapsedStateDidChange:)
                                                     name:iTermTabGroupCollapsedStateDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Properties

- (NSArray<iTermTabGroup *> *)tabGroups {
    return [_tabGroups copy];
}

#pragma mark - Notifications

- (void)tabGroupDidChange:(NSNotification *)notification {
    iTermTabGroup *group = notification.object;
    if ([_tabGroups containsObject:group]) {
        [self postDidChangeNotification];
    }
}

- (void)tabGroupCollapsedStateDidChange:(NSNotification *)notification {
    iTermTabGroup *group = notification.object;
    if ([_tabGroups containsObject:group]) {
        [self.delegate tabGroupManager:self didChangeCollapsedStateForGroup:group];
    }
}

- (void)postDidChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:iTermTabGroupManagerDidChangeNotification
                                                        object:self];
    [self.delegate tabGroupManagerNeedsTabBarUpdate:self];
}

#pragma mark - Group Management

- (iTermTabGroup *)createGroupWithName:(NSString *)name
                                 color:(NSColor *)color {
    iTermTabGroup *group = [[iTermTabGroup alloc] initWithName:name color:color];
    [_tabGroups addObject:group];
    [self postDidChangeNotification];
    return group;
}

- (iTermTabGroup *)createGroupWithName:(NSString *)name
                                 color:(NSColor *)color
                                  tabs:(NSArray<PTYTab *> *)tabs {
    iTermTabGroup *group = [self createGroupWithName:name color:color];
    for (PTYTab *tab in tabs) {
        [self addTab:tab toGroup:group];
    }
    return group;
}

- (void)removeGroup:(iTermTabGroup *)group {
    if (![_tabGroups containsObject:group]) {
        return;
    }

    // Remove tab-to-group mappings
    for (NSString *tabGUID in group.tabGUIDs) {
        [_tabToGroupMap removeObjectForKey:tabGUID];
    }

    [_tabGroups removeObject:group];
    [self postDidChangeNotification];
}

- (iTermTabGroup *)groupForTab:(PTYTab *)tab {
    return _tabToGroupMap[tab.stringUniqueIdentifier];
}

- (iTermTabGroup *)groupWithGUID:(NSString *)guid {
    for (iTermTabGroup *group in _tabGroups) {
        if ([group.guid isEqualToString:guid]) {
            return group;
        }
    }
    return nil;
}

#pragma mark - Tab-Group Assignment

- (void)addTab:(PTYTab *)tab toGroup:(iTermTabGroup *)group {
    [self addTab:tab toGroup:group atIndex:group.tabCount];
}

- (void)addTab:(PTYTab *)tab toGroup:(iTermTabGroup *)group atIndex:(NSUInteger)index {
    if (!tab || !group) {
        return;
    }

    NSString *tabGUID = tab.stringUniqueIdentifier;

    // Remove from current group if any
    iTermTabGroup *currentGroup = _tabToGroupMap[tabGUID];
    if (currentGroup) {
        [currentGroup removeTabWithGUID:tabGUID];
    }

    // Add to new group
    [group insertTabWithGUID:tabGUID atIndex:index];
    _tabToGroupMap[tabGUID] = group;

    [self postDidChangeNotification];
}

- (void)removeTabFromGroup:(PTYTab *)tab {
    NSString *tabGUID = tab.stringUniqueIdentifier;
    iTermTabGroup *group = _tabToGroupMap[tabGUID];

    if (group) {
        [group removeTabWithGUID:tabGUID];
        [_tabToGroupMap removeObjectForKey:tabGUID];

        // If group is now empty, remove it
        if (group.tabCount == 0) {
            [_tabGroups removeObject:group];
        }

        [self postDidChangeNotification];
    }
}

- (void)moveTab:(PTYTab *)tab toGroup:(iTermTabGroup *)group {
    [self moveTab:tab toGroup:group atIndex:group.tabCount];
}

- (void)moveTab:(PTYTab *)tab toGroup:(iTermTabGroup *)group atIndex:(NSUInteger)index {
    [self addTab:tab toGroup:group atIndex:index];
}

#pragma mark - Group Reordering

- (void)moveGroupAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
    if (fromIndex >= _tabGroups.count || toIndex >= _tabGroups.count) {
        return;
    }
    if (fromIndex == toIndex) {
        return;
    }

    iTermTabGroup *group = _tabGroups[fromIndex];
    [_tabGroups removeObjectAtIndex:fromIndex];

    if (toIndex > _tabGroups.count) {
        toIndex = _tabGroups.count;
    }
    [_tabGroups insertObject:group atIndex:toIndex];

    [self postDidChangeNotification];
}

#pragma mark - Collapse/Expand

- (void)collapseGroup:(iTermTabGroup *)group {
    group.collapsed = YES;
}

- (void)expandGroup:(iTermTabGroup *)group {
    group.collapsed = NO;
}

- (void)toggleCollapseGroup:(iTermTabGroup *)group {
    [group toggleCollapsed];
}

- (BOOL)isTabVisible:(PTYTab *)tab {
    iTermTabGroup *group = [self groupForTab:tab];
    if (!group) {
        // Ungrouped tabs are always visible
        return YES;
    }

    if (!group.collapsed) {
        // Expanded group, all tabs visible
        return YES;
    }

    // Collapsed group - only first tab (representative) is visible
    PTYTab *representative = [self representativeTabForGroup:group];
    return (tab == representative);
}

- (PTYTab *)representativeTabForGroup:(iTermTabGroup *)group {
    if (group.tabCount == 0) {
        return nil;
    }

    NSString *firstTabGUID = group.tabGUIDs.firstObject;
    return [self.delegate tabGroupManager:self tabWithGUID:firstTabGUID];
}

#pragma mark - Tab Order

- (NSArray<PTYTab *> *)tabsInDisplayOrder {
    NSMutableArray<PTYTab *> *result = [NSMutableArray array];
    NSMutableSet<NSString *> *processedTabGUIDs = [NSMutableSet set];

    // First, add tabs from groups in order
    for (iTermTabGroup *group in _tabGroups) {
        for (NSString *tabGUID in group.tabGUIDs) {
            PTYTab *tab = [self.delegate tabGroupManager:self tabWithGUID:tabGUID];
            if (tab) {
                [result addObject:tab];
                [processedTabGUIDs addObject:tabGUID];
            }
        }
    }

    // Then, add ungrouped tabs
    NSArray<PTYTab *> *allTabs = [self.delegate tabGroupManagerAllTabs:self];
    for (PTYTab *tab in allTabs) {
        if (![processedTabGUIDs containsObject:tab.stringUniqueIdentifier]) {
            [result addObject:tab];
        }
    }

    return result;
}

- (NSArray<PTYTab *> *)visibleTabs {
    NSMutableArray<PTYTab *> *result = [NSMutableArray array];

    for (PTYTab *tab in [self tabsInDisplayOrder]) {
        if ([self isTabVisible:tab]) {
            [result addObject:tab];
        }
    }

    return result;
}

- (NSArray<PTYTab *> *)hiddenTabs {
    NSMutableArray<PTYTab *> *result = [NSMutableArray array];

    for (PTYTab *tab in [self tabsInDisplayOrder]) {
        if (![self isTabVisible:tab]) {
            [result addObject:tab];
        }
    }

    return result;
}

#pragma mark - Persistence

- (NSDictionary *)arrangement {
    NSMutableArray *groupArrangements = [NSMutableArray array];
    for (iTermTabGroup *group in _tabGroups) {
        [groupArrangements addObject:[group arrangement]];
    }
    return @{ kTabGroupManagerArrangementGroups: groupArrangements };
}

- (void)restoreFromArrangement:(NSDictionary *)arrangement {
    [_tabGroups removeAllObjects];
    [_tabToGroupMap removeAllObjects];

    NSArray *groupArrangements = arrangement[kTabGroupManagerArrangementGroups];
    if (![groupArrangements isKindOfClass:[NSArray class]]) {
        return;
    }

    for (NSDictionary *groupArrangement in groupArrangements) {
        iTermTabGroup *group = [iTermTabGroup tabGroupFromArrangement:groupArrangement];
        if (group) {
            [_tabGroups addObject:group];

            // Rebuild tab-to-group map
            for (NSString *tabGUID in group.tabGUIDs) {
                _tabToGroupMap[tabGUID] = group;
            }
        }
    }

    [self postDidChangeNotification];
}

#pragma mark - Tab Lifecycle

- (void)tabWasAdded:(PTYTab *)tab {
    // New tabs are ungrouped by default
    // Nothing special to do here
}

- (void)tabWasRemoved:(PTYTab *)tab {
    [self removeTabFromGroup:tab];
}

- (void)tabsWereReordered:(NSArray<PTYTab *> *)tabs {
    // When tabs are reordered via drag, update the tab order within each group
    // to match the new tab bar order
    for (iTermTabGroup *group in _tabGroups) {
        NSMutableArray<NSString *> *sortedTabGUIDs = [NSMutableArray array];

        // Go through tabs in their new order and collect GUIDs that belong to this group
        for (PTYTab *tab in tabs) {
            NSString *tabGUID = tab.stringUniqueIdentifier;
            if (_tabToGroupMap[tabGUID] == group) {
                [sortedTabGUIDs addObject:tabGUID];
            }
        }

        // Update the group's tab order if it changed
        if (![group.tabGUIDs isEqualToArray:sortedTabGUIDs]) {
            [group reorderTabsToMatch:sortedTabGUIDs];
        }
    }

    [self postDidChangeNotification];
}

- (void)ensureGroupedTabsAreContiguous {
    // For each group, move its tabs so they are contiguous in the tab bar
    // This maintains the tab's relative position within the group

    NSArray<PTYTab *> *allTabs = [self.delegate tabGroupManagerAllTabs:self];
    if (allTabs.count == 0) {
        return;
    }

    for (iTermTabGroup *group in _tabGroups) {
        if (group.tabCount < 2) {
            continue;
        }

        // Find the indices of all tabs in this group
        NSMutableArray<NSNumber *> *groupTabIndices = [NSMutableArray array];
        for (NSString *tabGUID in group.tabGUIDs) {
            PTYTab *tab = [self.delegate tabGroupManager:self tabWithGUID:tabGUID];
            if (tab) {
                NSUInteger index = [self.delegate tabGroupManager:self indexOfTab:tab];
                if (index != NSNotFound) {
                    [groupTabIndices addObject:@(index)];
                }
            }
        }

        if (groupTabIndices.count < 2) {
            continue;
        }

        // Sort indices
        [groupTabIndices sortUsingSelector:@selector(compare:)];

        // Check if tabs are contiguous
        BOOL isContiguous = YES;
        NSUInteger expectedIndex = [groupTabIndices[0] unsignedIntegerValue];
        for (NSNumber *indexNum in groupTabIndices) {
            if ([indexNum unsignedIntegerValue] != expectedIndex) {
                isContiguous = NO;
                break;
            }
            expectedIndex++;
        }

        if (!isContiguous) {
            // Move tabs to make them contiguous
            // Place them starting at the position of the first tab
            NSUInteger targetIndex = [groupTabIndices[0] unsignedIntegerValue];

            for (NSUInteger i = 1; i < groupTabIndices.count; i++) {
                NSUInteger currentIndex = [groupTabIndices[i] unsignedIntegerValue];
                NSUInteger desiredIndex = targetIndex + i;

                if (currentIndex != desiredIndex) {
                    // Need to move this tab
                    // Account for index shifts when moving
                    NSUInteger adjustedFrom = currentIndex;
                    NSUInteger adjustedTo = desiredIndex;

                    [self.delegate tabGroupManager:self moveTabAtIndex:adjustedFrom toIndex:adjustedTo];

                    // Refresh indices after the move
                    allTabs = [self.delegate tabGroupManagerAllTabs:self];
                    [groupTabIndices removeAllObjects];
                    for (NSString *tabGUID in group.tabGUIDs) {
                        PTYTab *tab = [self.delegate tabGroupManager:self tabWithGUID:tabGUID];
                        if (tab) {
                            NSUInteger index = [self.delegate tabGroupManager:self indexOfTab:tab];
                            if (index != NSNotFound) {
                                [groupTabIndices addObject:@(index)];
                            }
                        }
                    }
                    [groupTabIndices sortUsingSelector:@selector(compare:)];
                }
            }
        }
    }
}

- (void)moveTab:(PTYTab *)tab withinGroupToIndex:(NSUInteger)index {
    NSString *tabGUID = tab.stringUniqueIdentifier;
    iTermTabGroup *group = _tabToGroupMap[tabGUID];

    if (!group) {
        return;
    }

    // Update position within the group's internal list
    [group moveTabWithGUID:tabGUID toIndex:index];

    [self postDidChangeNotification];
}

@end
