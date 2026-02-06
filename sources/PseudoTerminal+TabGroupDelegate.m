//
//  PseudoTerminal+TabGroupDelegate.m
//  iTerm2
//
//  iTermTabGroupManagerDelegate implementation for PseudoTerminal.
//

#import "PseudoTerminal+TabGroupDelegate.h"
#import "iTermTabGroup.h"
#import "PTYTab.h"
#import "PTYTabView.h"

@implementation PseudoTerminal (TabGroupDelegate)

#pragma mark - iTermTabGroupManagerDelegate

- (void)tabGroupManager:(id)manager didChangeCollapsedStateForGroup:(iTermTabGroup *)group {
    // When a group's collapsed state changes, we need to update tab visibility
    if (group.collapsed) {
        [self hideTabsInCollapsedGroup:group];
    } else {
        [self showTabsInExpandedGroup:group];
    }

    // Refresh the tab bar display
    [self refreshTabBar];
}

- (void)tabGroupManagerNeedsTabBarUpdate:(id)manager {
    [self refreshTabBar];
}

- (PTYTab *)tabGroupManager:(id)manager tabWithGUID:(NSString *)guid {
    for (PTYTab *tab in [self tabs]) {
        if ([tab.stringUniqueIdentifier isEqualToString:guid]) {
            return tab;
        }
    }
    return nil;
}

- (NSArray<PTYTab *> *)tabGroupManagerAllTabs:(id)manager {
    return [self tabs];
}

#pragma mark - Private Helpers

- (void)hideTabsInCollapsedGroup:(iTermTabGroup *)group {
    // Get all tabs in the group except the first (representative)
    NSArray<NSString *> *tabGUIDs = group.tabGUIDs;
    if (tabGUIDs.count <= 1) {
        return;  // Nothing to hide
    }

    // Skip the first tab (it remains visible as the representative)
    for (NSUInteger i = 1; i < tabGUIDs.count; i++) {
        NSString *guid = tabGUIDs[i];
        PTYTab *tab = [self tabGroupManager:nil tabWithGUID:guid];
        if (tab) {
            [self setTabHidden:YES forTab:tab];
        }
    }

    // Update the representative tab's display to show group info
    PTYTab *representativeTab = [self tabGroupManager:nil tabWithGUID:tabGUIDs.firstObject];
    if (representativeTab) {
        [self updateTabAppearanceForGroupRepresentative:representativeTab inGroup:group];
    }
}

- (void)showTabsInExpandedGroup:(iTermTabGroup *)group {
    // Show all tabs in the group
    for (NSString *guid in group.tabGUIDs) {
        PTYTab *tab = [self tabGroupManager:nil tabWithGUID:guid];
        if (tab) {
            [self setTabHidden:NO forTab:tab];
        }
    }

    // Reset the representative tab's display
    PTYTab *representativeTab = [self tabGroupManager:nil tabWithGUID:group.tabGUIDs.firstObject];
    if (representativeTab) {
        [self resetTabAppearanceForTab:representativeTab];
    }
}

- (void)setTabHidden:(BOOL)hidden forTab:(PTYTab *)tab {
    // Find the tab view item for this tab
    NSTabViewItem *tabViewItem = tab.tabViewItem;
    if (!tabViewItem) {
        return;
    }

    // Note: NSTabView doesn't directly support hiding tabs.
    // In a full implementation, we would need to:
    // 1. Store the hidden state in the tab
    // 2. Filter the tabs when rendering the tab bar
    // 3. Or physically remove/add the tab view item (with proper state management)

    // For now, we'll track this through the tab group manager's visibility tracking
    // The actual hiding will be implemented in the tab bar rendering code
}

- (void)updateTabAppearanceForGroupRepresentative:(PTYTab *)tab inGroup:(iTermTabGroup *)group {
    // When a group is collapsed, the representative tab should display:
    // - The group name
    // - The group color
    // - A count of hidden tabs

    // This would be implemented by updating the tab's display properties
    // or by having the tab bar cell check if the tab is a group representative
}

- (void)resetTabAppearanceForTab:(PTYTab *)tab {
    // Reset the tab's appearance to its normal state
}

- (void)refreshTabBar {
    // Force the tab bar to redraw
    // This triggers an update of all tab cells and group headers

    // Get the tab bar control and ask it to update
    // The actual implementation depends on how the tab bar is accessed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"iTermTabBarNeedsRefresh"
                                                        object:self];
}

@end
