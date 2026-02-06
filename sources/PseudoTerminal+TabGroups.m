//
//  PseudoTerminal+TabGroups.m
//  iTerm2
//
//  Tab group management extension for PseudoTerminal.
//

#import "PseudoTerminal+TabGroups.h"
#import "iTermTabGroup.h"
#import "iTermTabGroupManager.h"
#import "iTermTabGroupColorPickerViewController.h"
#import "iTermTabGroupNameEditor.h"
#import "PTYTab.h"
#import "iTermController.h"
#import <objc/runtime.h>

NSString *const TERMINAL_ARRANGEMENT_TAB_GROUPS = @"Tab Groups";

static const void *kTabGroupManagerKey = &kTabGroupManagerKey;

@implementation PseudoTerminal (TabGroups)

#pragma mark - Tab Group Manager Accessor

- (iTermTabGroupManager *)tabGroupManager {
    iTermTabGroupManager *manager = objc_getAssociatedObject(self, kTabGroupManagerKey);
    if (!manager) {
        manager = [[iTermTabGroupManager alloc] init];
        manager.delegate = (id<iTermTabGroupManagerDelegate>)self;
        objc_setAssociatedObject(self, kTabGroupManagerKey, manager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return manager;
}

#pragma mark - Tab Group Management

- (iTermTabGroup *)createTabGroupWithSelectedTabs {
    PTYTab *currentTab = [self currentTab];
    if (!currentTab) {
        return nil;
    }

    // For now, create a group with just the current tab
    // In a full implementation, this would include all selected tabs
    return [self createTabGroupWithTabs:@[currentTab]
                                   name:@"New Group"
                                  color:[[iTermTabGroup predefinedColors] firstObject]];
}

- (iTermTabGroup *)createTabGroupWithTabs:(NSArray<PTYTab *> *)tabs
                                     name:(NSString *)name
                                    color:(NSColor *)color {
    if (tabs.count == 0) {
        return nil;
    }

    NSString *groupName = name ?: @"New Group";
    NSColor *groupColor = color ?: [[iTermTabGroup predefinedColors] firstObject];

    iTermTabGroup *group = [self.tabGroupManager createGroupWithName:groupName
                                                               color:groupColor
                                                                tabs:tabs];

    // Update the tab bar
    [self updateTabBarForTabGroups];

    return group;
}

- (void)addCurrentTabToGroup:(iTermTabGroup *)group {
    PTYTab *currentTab = [self currentTab];
    if (currentTab && group) {
        [self.tabGroupManager addTab:currentTab toGroup:group];
        [self updateTabBarForTabGroups];
    }
}

- (void)removeCurrentTabFromGroup {
    PTYTab *currentTab = [self currentTab];
    if (currentTab) {
        [self.tabGroupManager removeTabFromGroup:currentTab];
        [self updateTabBarForTabGroups];
    }
}

- (void)ungroupTabGroup:(iTermTabGroup *)group {
    if (group) {
        // Get all tabs before removing the group
        NSArray<NSString *> *tabGUIDs = [group.tabGUIDs copy];

        // Remove all tabs from the group
        for (NSString *tabGUID in tabGUIDs) {
            PTYTab *tab = [self tabWithGUID:tabGUID];
            if (tab) {
                [self.tabGroupManager removeTabFromGroup:tab];
            }
        }

        [self updateTabBarForTabGroups];
    }
}

- (void)closeTabGroup:(iTermTabGroup *)group {
    if (!group) {
        return;
    }

    // Get all tabs in the group
    NSArray<NSString *> *tabGUIDs = [group.tabGUIDs copy];

    // Close each tab
    for (NSString *tabGUID in tabGUIDs) {
        PTYTab *tab = [self tabWithGUID:tabGUID];
        if (tab) {
            [self closeTabIfConfirmed:tab];
        }
    }

    // The group will be automatically removed when all tabs are closed
}

#pragma mark - Tab Group Navigation

- (void)selectNextVisibleTab {
    NSArray<PTYTab *> *visibleTabs = [self.tabGroupManager visibleTabs];
    PTYTab *currentTab = [self currentTab];

    if (visibleTabs.count == 0 || !currentTab) {
        return;
    }

    NSUInteger currentIndex = [visibleTabs indexOfObject:currentTab];
    if (currentIndex == NSNotFound) {
        // Current tab is hidden, select the first visible tab
        [[visibleTabs firstObject] makeActive];
        return;
    }

    NSUInteger nextIndex = (currentIndex + 1) % visibleTabs.count;
    [visibleTabs[nextIndex] makeActive];
}

- (void)selectPreviousVisibleTab {
    NSArray<PTYTab *> *visibleTabs = [self.tabGroupManager visibleTabs];
    PTYTab *currentTab = [self currentTab];

    if (visibleTabs.count == 0 || !currentTab) {
        return;
    }

    NSUInteger currentIndex = [visibleTabs indexOfObject:currentTab];
    if (currentIndex == NSNotFound) {
        // Current tab is hidden, select the last visible tab
        [[visibleTabs lastObject] makeActive];
        return;
    }

    NSUInteger prevIndex = (currentIndex + visibleTabs.count - 1) % visibleTabs.count;
    [visibleTabs[prevIndex] makeActive];
}

- (void)selectGroup:(iTermTabGroup *)group {
    PTYTab *representativeTab = [self.tabGroupManager representativeTabForGroup:group];
    if (representativeTab) {
        [representativeTab makeActive];
    }
}

#pragma mark - Tab Group Actions

- (void)toggleCollapseTabGroup:(iTermTabGroup *)group {
    [self.tabGroupManager toggleCollapseGroup:group];
    [self updateTabBarForTabGroups];
}

- (void)renameTabGroup:(iTermTabGroup *)group {
    // Find the tab bar view
    NSView *tabBarView = [self tabBarView];
    if (!tabBarView) {
        return;
    }

    // Show the name editor
    [iTermTabGroupNameEditor editNameForGroup:group
                               relativeToRect:tabBarView.bounds
                                       ofView:tabBarView
                                preferredEdge:NSRectEdgeMaxY
                                   completion:^(NSString *newName) {
        if (newName) {
            group.name = newName;
            [self updateTabBarForTabGroups];
        }
    }];
}

- (void)changeColorOfTabGroup:(iTermTabGroup *)group {
    NSView *tabBarView = [self tabBarView];
    if (!tabBarView) {
        return;
    }

    [iTermTabGroupColorPickerViewController showColorPickerRelativeToRect:tabBarView.bounds
                                                                   ofView:tabBarView
                                                            preferredEdge:NSRectEdgeMaxY
                                                             currentColor:group.color
                                                               completion:^(NSColor *selectedColor) {
        if (selectedColor) {
            group.color = selectedColor;
        } else {
            // nil means remove color was selected
            group.color = nil;
        }
        [self updateTabBarForTabGroups];
    }];
}

#pragma mark - Context Menu

- (NSMenu *)tabGroupContextMenuForTab:(PTYTab *)tab {
    NSMenu *menu = [[NSMenu alloc] init];

    iTermTabGroup *currentGroup = [self.tabGroupManager groupForTab:tab];

    if (currentGroup) {
        // Tab is in a group
        NSMenuItem *removeItem = [[NSMenuItem alloc] initWithTitle:@"Remove from Group"
                                                            action:@selector(removeCurrentTabFromGroupAction:)
                                                     keyEquivalent:@""];
        removeItem.target = self;
        [menu addItem:removeItem];

        [menu addItem:[NSMenuItem separatorItem]];
    }

    // Add to existing group submenu
    NSArray<iTermTabGroup *> *groups = self.tabGroupManager.tabGroups;
    if (groups.count > 0) {
        NSMenuItem *addToGroupItem = [[NSMenuItem alloc] initWithTitle:@"Add to Group"
                                                                action:nil
                                                         keyEquivalent:@""];
        NSMenu *submenu = [[NSMenu alloc] init];

        for (iTermTabGroup *group in groups) {
            if (group != currentGroup) {
                NSMenuItem *groupItem = [[NSMenuItem alloc] initWithTitle:group.name
                                                                   action:@selector(addTabToGroupAction:)
                                                            keyEquivalent:@""];
                groupItem.target = self;
                groupItem.representedObject = group;
                [submenu addItem:groupItem];
            }
        }

        if (submenu.numberOfItems > 0) {
            addToGroupItem.submenu = submenu;
            [menu addItem:addToGroupItem];
        }
    }

    // Create new group
    NSMenuItem *createGroupItem = [[NSMenuItem alloc] initWithTitle:@"Create New Group with Tab"
                                                             action:@selector(createGroupWithCurrentTabAction:)
                                                      keyEquivalent:@""];
    createGroupItem.target = self;
    [menu addItem:createGroupItem];

    return menu;
}

- (NSMenu *)contextMenuForTabGroup:(iTermTabGroup *)group {
    NSMenu *menu = [[NSMenu alloc] init];

    // Collapse/Expand
    NSString *collapseTitle = group.collapsed ? @"Expand Group" : @"Collapse Group";
    NSMenuItem *collapseItem = [[NSMenuItem alloc] initWithTitle:collapseTitle
                                                          action:@selector(toggleCollapseGroupAction:)
                                                   keyEquivalent:@""];
    collapseItem.target = self;
    collapseItem.representedObject = group;
    [menu addItem:collapseItem];

    [menu addItem:[NSMenuItem separatorItem]];

    // Rename
    NSMenuItem *renameItem = [[NSMenuItem alloc] initWithTitle:@"Rename Group..."
                                                        action:@selector(renameGroupAction:)
                                                 keyEquivalent:@""];
    renameItem.target = self;
    renameItem.representedObject = group;
    [menu addItem:renameItem];

    // Change Color
    NSMenuItem *colorItem = [[NSMenuItem alloc] initWithTitle:@"Change Color..."
                                                       action:@selector(changeGroupColorAction:)
                                                keyEquivalent:@""];
    colorItem.target = self;
    colorItem.representedObject = group;
    [menu addItem:colorItem];

    [menu addItem:[NSMenuItem separatorItem]];

    // Ungroup
    NSMenuItem *ungroupItem = [[NSMenuItem alloc] initWithTitle:@"Ungroup Tabs"
                                                         action:@selector(ungroupAction:)
                                                  keyEquivalent:@""];
    ungroupItem.target = self;
    ungroupItem.representedObject = group;
    [menu addItem:ungroupItem];

    // Close Group
    NSMenuItem *closeItem = [[NSMenuItem alloc] initWithTitle:@"Close Group"
                                                       action:@selector(closeGroupAction:)
                                                keyEquivalent:@""];
    closeItem.target = self;
    closeItem.representedObject = group;
    [menu addItem:closeItem];

    return menu;
}

#pragma mark - Menu Actions

- (void)removeCurrentTabFromGroupAction:(id)sender {
    [self removeCurrentTabFromGroup];
}

- (void)addTabToGroupAction:(NSMenuItem *)sender {
    iTermTabGroup *group = sender.representedObject;
    [self addCurrentTabToGroup:group];
}

- (void)createGroupWithCurrentTabAction:(id)sender {
    [self createTabGroupWithSelectedTabs];
}

- (void)toggleCollapseGroupAction:(NSMenuItem *)sender {
    iTermTabGroup *group = sender.representedObject;
    [self toggleCollapseTabGroup:group];
}

- (void)renameGroupAction:(NSMenuItem *)sender {
    iTermTabGroup *group = sender.representedObject;
    [self renameTabGroup:group];
}

- (void)changeGroupColorAction:(NSMenuItem *)sender {
    iTermTabGroup *group = sender.representedObject;
    [self changeColorOfTabGroup:group];
}

- (void)ungroupAction:(NSMenuItem *)sender {
    iTermTabGroup *group = sender.representedObject;
    [self ungroupTabGroup:group];
}

- (void)closeGroupAction:(NSMenuItem *)sender {
    iTermTabGroup *group = sender.representedObject;
    [self closeTabGroup:group];
}

#pragma mark - Arrangement

- (void)addTabGroupsToArrangement:(NSMutableDictionary *)arrangement {
    NSDictionary *groupArrangement = [self.tabGroupManager arrangement];
    arrangement[TERMINAL_ARRANGEMENT_TAB_GROUPS] = groupArrangement;
}

- (void)restoreTabGroupsFromArrangement:(NSDictionary *)arrangement {
    NSDictionary *groupArrangement = arrangement[TERMINAL_ARRANGEMENT_TAB_GROUPS];
    if (groupArrangement) {
        [self.tabGroupManager restoreFromArrangement:groupArrangement];
    }
}

#pragma mark - Helpers

- (PTYTab *)tabWithGUID:(NSString *)guid {
    for (PTYTab *tab in [self tabs]) {
        if ([tab.stringUniqueIdentifier isEqualToString:guid]) {
            return tab;
        }
    }
    return nil;
}

- (void)updateTabBarForTabGroups {
    // This would trigger a tab bar redraw
    // The actual implementation would depend on how the tab bar handles group display
    [[NSNotificationCenter defaultCenter] postNotificationName:iTermTabGroupManagerDidChangeNotification
                                                        object:self.tabGroupManager];
}

- (NSView *)tabBarView {
    // Return the tab bar control view
    // This is a simplified accessor - the actual implementation would access the real tab bar
    return nil;  // Placeholder - would return actual tab bar view
}

@end
