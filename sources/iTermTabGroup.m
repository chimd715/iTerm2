//
//  iTermTabGroup.m
//  iTerm2
//
//  Tab group model for grouping tabs with collapse/expand, name, and color support.
//

#import "iTermTabGroup.h"
#import "NSColor+iTerm.h"

NSString *const iTermTabGroupDidChangeNotification = @"iTermTabGroupDidChangeNotification";
NSString *const iTermTabGroupCollapsedStateDidChangeNotification = @"iTermTabGroupCollapsedStateDidChangeNotification";

// Arrangement keys
NSString *const kTabGroupArrangementGUID = @"Tab Group GUID";
NSString *const kTabGroupArrangementName = @"Tab Group Name";
NSString *const kTabGroupArrangementColorData = @"Tab Group Color";
NSString *const kTabGroupArrangementCollapsed = @"Tab Group Collapsed";
NSString *const kTabGroupArrangementTabGUIDs = @"Tab Group Tab GUIDs";

@implementation iTermTabGroup {
    NSMutableArray<NSString *> *_tabGUIDs;
}

#pragma mark - Initialization

- (instancetype)initWithName:(NSString *)name color:(NSColor *)color {
    return [self initWithGUID:[[NSUUID UUID] UUIDString]
                         name:name
                        color:color
                    collapsed:NO];
}

- (instancetype)initWithGUID:(NSString *)guid
                        name:(NSString *)name
                       color:(NSColor *)color
                   collapsed:(BOOL)collapsed {
    self = [super init];
    if (self) {
        _guid = [guid copy];
        _name = [name copy];
        _color = color;
        _collapsed = collapsed;
        _tabGUIDs = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    iTermTabGroup *copy = [[iTermTabGroup alloc] initWithGUID:self.guid
                                                         name:self.name
                                                        color:self.color
                                                    collapsed:self.collapsed];
    [copy->_tabGUIDs addObjectsFromArray:_tabGUIDs];
    return copy;
}

#pragma mark - Properties

- (NSArray<NSString *> *)tabGUIDs {
    return [_tabGUIDs copy];
}

- (NSUInteger)tabCount {
    return _tabGUIDs.count;
}

- (void)setName:(NSString *)name {
    if (![_name isEqualToString:name]) {
        _name = [name copy];
        [self postDidChangeNotification];
    }
}

- (void)setColor:(NSColor *)color {
    if (![_color isEqual:color]) {
        _color = color;
        [self postDidChangeNotification];
    }
}

- (void)setCollapsed:(BOOL)collapsed {
    if (_collapsed != collapsed) {
        _collapsed = collapsed;
        [[NSNotificationCenter defaultCenter] postNotificationName:iTermTabGroupCollapsedStateDidChangeNotification
                                                            object:self];
        [self postDidChangeNotification];
    }
}

#pragma mark - Tab Management

- (void)addTabWithGUID:(NSString *)tabGUID {
    if (![_tabGUIDs containsObject:tabGUID]) {
        [_tabGUIDs addObject:tabGUID];
        [self postDidChangeNotification];
    }
}

- (void)insertTabWithGUID:(NSString *)tabGUID atIndex:(NSUInteger)index {
    if (![_tabGUIDs containsObject:tabGUID]) {
        if (index > _tabGUIDs.count) {
            index = _tabGUIDs.count;
        }
        [_tabGUIDs insertObject:tabGUID atIndex:index];
        [self postDidChangeNotification];
    }
}

- (void)removeTabWithGUID:(NSString *)tabGUID {
    if ([_tabGUIDs containsObject:tabGUID]) {
        [_tabGUIDs removeObject:tabGUID];
        [self postDidChangeNotification];
    }
}

- (BOOL)containsTabWithGUID:(NSString *)tabGUID {
    return [_tabGUIDs containsObject:tabGUID];
}

- (NSUInteger)indexOfTabWithGUID:(NSString *)tabGUID {
    return [_tabGUIDs indexOfObject:tabGUID];
}

- (void)moveTabWithGUID:(NSString *)tabGUID toIndex:(NSUInteger)newIndex {
    NSUInteger currentIndex = [_tabGUIDs indexOfObject:tabGUID];
    if (currentIndex == NSNotFound) {
        return;
    }
    if (currentIndex == newIndex) {
        return;
    }
    [_tabGUIDs removeObjectAtIndex:currentIndex];
    if (newIndex > _tabGUIDs.count) {
        newIndex = _tabGUIDs.count;
    }
    [_tabGUIDs insertObject:tabGUID atIndex:newIndex];
    [self postDidChangeNotification];
}

- (void)removeAllTabs {
    if (_tabGUIDs.count > 0) {
        [_tabGUIDs removeAllObjects];
        [self postDidChangeNotification];
    }
}

#pragma mark - Collapse/Expand

- (void)toggleCollapsed {
    self.collapsed = !self.collapsed;
}

#pragma mark - Notifications

- (void)postDidChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:iTermTabGroupDidChangeNotification
                                                        object:self];
}

#pragma mark - Arrangement (Persistence)

- (NSDictionary *)arrangement {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[kTabGroupArrangementGUID] = self.guid;
    dict[kTabGroupArrangementName] = self.name ?: @"";
    dict[kTabGroupArrangementCollapsed] = @(self.collapsed);
    dict[kTabGroupArrangementTabGUIDs] = [_tabGUIDs copy];

    if (self.color) {
        NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:self.color
                                                  requiringSecureCoding:NO
                                                                  error:nil];
        if (colorData) {
            dict[kTabGroupArrangementColorData] = colorData;
        }
    }

    return dict;
}

+ (instancetype)tabGroupFromArrangement:(NSDictionary *)arrangement {
    NSString *guid = arrangement[kTabGroupArrangementGUID];
    NSString *name = arrangement[kTabGroupArrangementName];

    if (!guid || !name) {
        return nil;
    }

    NSColor *color = nil;
    NSData *colorData = arrangement[kTabGroupArrangementColorData];
    if (colorData) {
        color = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class]
                                                  fromData:colorData
                                                     error:nil];
    }

    BOOL collapsed = [arrangement[kTabGroupArrangementCollapsed] boolValue];

    iTermTabGroup *group = [[iTermTabGroup alloc] initWithGUID:guid
                                                          name:name
                                                         color:color
                                                     collapsed:collapsed];

    NSArray *tabGUIDs = arrangement[kTabGroupArrangementTabGUIDs];
    if ([tabGUIDs isKindOfClass:[NSArray class]]) {
        for (NSString *tabGUID in tabGUIDs) {
            if ([tabGUID isKindOfClass:[NSString class]]) {
                [group->_tabGUIDs addObject:tabGUID];
            }
        }
    }

    return group;
}

#pragma mark - Predefined Colors

+ (NSArray<NSColor *> *)predefinedColors {
    static NSArray<NSColor *> *colors;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colors = @[
            [NSColor colorWithCalibratedRed:0.85 green:0.35 blue:0.35 alpha:1.0],  // Red
            [NSColor colorWithCalibratedRed:0.95 green:0.55 blue:0.25 alpha:1.0],  // Orange
            [NSColor colorWithCalibratedRed:0.95 green:0.80 blue:0.25 alpha:1.0],  // Yellow
            [NSColor colorWithCalibratedRed:0.45 green:0.75 blue:0.40 alpha:1.0],  // Green
            [NSColor colorWithCalibratedRed:0.30 green:0.70 blue:0.85 alpha:1.0],  // Cyan
            [NSColor colorWithCalibratedRed:0.40 green:0.50 blue:0.85 alpha:1.0],  // Blue
            [NSColor colorWithCalibratedRed:0.70 green:0.45 blue:0.85 alpha:1.0],  // Purple
            [NSColor colorWithCalibratedRed:0.85 green:0.45 blue:0.65 alpha:1.0],  // Pink
            [NSColor colorWithCalibratedRed:0.55 green:0.55 blue:0.55 alpha:1.0],  // Gray
        ];
    });
    return colors;
}

+ (NSString *)nameForColor:(NSColor *)color {
    NSArray<NSColor *> *predefined = [self predefinedColors];
    NSArray<NSString *> *names = @[@"Red", @"Orange", @"Yellow", @"Green",
                                    @"Cyan", @"Blue", @"Purple", @"Pink", @"Gray"];

    CGFloat minDistance = CGFLOAT_MAX;
    NSUInteger bestIndex = 0;

    NSColor *deviceColor = [color colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    if (!deviceColor) {
        return @"Custom";
    }

    CGFloat r1, g1, b1, a1;
    [deviceColor getRed:&r1 green:&g1 blue:&b1 alpha:&a1];

    for (NSUInteger i = 0; i < predefined.count; i++) {
        NSColor *predefinedDevice = [predefined[i] colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
        if (!predefinedDevice) continue;

        CGFloat r2, g2, b2, a2;
        [predefinedDevice getRed:&r2 green:&g2 blue:&b2 alpha:&a2];

        CGFloat distance = sqrt(pow(r1 - r2, 2) + pow(g1 - g2, 2) + pow(b1 - b2, 2));
        if (distance < minDistance) {
            minDistance = distance;
            bestIndex = i;
        }
    }

    if (minDistance < 0.1) {
        return names[bestIndex];
    }
    return @"Custom";
}

#pragma mark - Description

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p guid=%@ name=%@ tabCount=%lu collapsed=%@>",
            NSStringFromClass([self class]),
            self,
            self.guid,
            self.name,
            (unsigned long)self.tabCount,
            self.collapsed ? @"YES" : @"NO"];
}

@end
