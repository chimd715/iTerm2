//
//  PSMTabGroup.m
//  PSMTabBarControl
//
//  Chrome-like tab group support for PSMTabBarControl.
//

#import "PSMTabGroup.h"

@implementation PSMTabGroup {
    NSMutableArray *_tabIdentifiers;
}

#pragma mark - Initialization

- (instancetype)initWithName:(NSString *)name {
    return [self initWithIdentifier:[[NSUUID UUID] UUIDString] name:name];
}

- (instancetype)initWithIdentifier:(NSString *)identifier name:(NSString *)name {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _name = [name copy];
        _tabIdentifiers = [[NSMutableArray alloc] init];
        _collapsed = NO;
        _colorType = PSMTabGroupColorTypeGrey;
        _color = [PSMTabGroup colorForType:_colorType];
        _headerFrame = NSZeroRect;
        _groupFrame = NSZeroRect;
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name colorType:(PSMTabGroupColorType)colorType {
    self = [self initWithName:name];
    if (self) {
        _colorType = colorType;
        _color = [PSMTabGroup colorForType:colorType];
    }
    return self;
}

#pragma mark - Properties

- (NSArray *)tabIdentifiers {
    return [_tabIdentifiers copy];
}

- (NSUInteger)tabCount {
    return _tabIdentifiers.count;
}

- (void)setColorType:(PSMTabGroupColorType)colorType {
    _colorType = colorType;
    if (colorType != PSMTabGroupColorTypeCustom) {
        _color = [PSMTabGroup colorForType:colorType];
    }
}

#pragma mark - Tab Management

- (void)addTabIdentifier:(id)identifier {
    if (identifier && ![_tabIdentifiers containsObject:identifier]) {
        [_tabIdentifiers addObject:identifier];
    }
}

- (void)insertTabIdentifier:(id)identifier atIndex:(NSUInteger)index {
    if (identifier && ![_tabIdentifiers containsObject:identifier]) {
        if (index > _tabIdentifiers.count) {
            index = _tabIdentifiers.count;
        }
        [_tabIdentifiers insertObject:identifier atIndex:index];
    }
}

- (void)removeTabIdentifier:(id)identifier {
    [_tabIdentifiers removeObject:identifier];
}

- (BOOL)containsTabIdentifier:(id)identifier {
    return [_tabIdentifiers containsObject:identifier];
}

- (NSUInteger)indexOfTabIdentifier:(id)identifier {
    return [_tabIdentifiers indexOfObject:identifier];
}

#pragma mark - Color Utilities

+ (NSColor *)colorForType:(PSMTabGroupColorType)type {
    // Chrome-like color palette
    switch (type) {
        case PSMTabGroupColorTypeGrey:
            return [NSColor colorWithCalibratedRed:0.62 green:0.62 blue:0.62 alpha:1.0];
        case PSMTabGroupColorTypeBlue:
            return [NSColor colorWithCalibratedRed:0.34 green:0.53 blue:0.93 alpha:1.0];
        case PSMTabGroupColorTypeRed:
            return [NSColor colorWithCalibratedRed:0.92 green:0.36 blue:0.34 alpha:1.0];
        case PSMTabGroupColorTypeYellow:
            return [NSColor colorWithCalibratedRed:0.98 green:0.74 blue:0.18 alpha:1.0];
        case PSMTabGroupColorTypeGreen:
            return [NSColor colorWithCalibratedRed:0.25 green:0.76 blue:0.47 alpha:1.0];
        case PSMTabGroupColorTypePink:
            return [NSColor colorWithCalibratedRed:0.95 green:0.46 blue:0.68 alpha:1.0];
        case PSMTabGroupColorTypePurple:
            return [NSColor colorWithCalibratedRed:0.66 green:0.47 blue:0.87 alpha:1.0];
        case PSMTabGroupColorTypeCyan:
            return [NSColor colorWithCalibratedRed:0.27 green:0.80 blue:0.84 alpha:1.0];
        case PSMTabGroupColorTypeCustom:
        default:
            return [NSColor grayColor];
    }
}

+ (NSArray<NSColor *> *)predefinedColors {
    return @[
        [self colorForType:PSMTabGroupColorTypeGrey],
        [self colorForType:PSMTabGroupColorTypeBlue],
        [self colorForType:PSMTabGroupColorTypeRed],
        [self colorForType:PSMTabGroupColorTypeYellow],
        [self colorForType:PSMTabGroupColorTypeGreen],
        [self colorForType:PSMTabGroupColorTypePink],
        [self colorForType:PSMTabGroupColorTypePurple],
        [self colorForType:PSMTabGroupColorTypeCyan]
    ];
}

+ (PSMTabGroupColorType)colorTypeForColor:(NSColor *)color {
    if (!color) {
        return PSMTabGroupColorTypeGrey;
    }

    // Convert to RGB for comparison
    NSColor *rgbColor = [color colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    if (!rgbColor) {
        return PSMTabGroupColorTypeCustom;
    }

    CGFloat r, g, b, a;
    [rgbColor getRed:&r green:&g blue:&b alpha:&a];

    // Check against predefined colors (with tolerance)
    for (PSMTabGroupColorType type = PSMTabGroupColorTypeGrey; type <= PSMTabGroupColorTypeCyan; type++) {
        NSColor *predefined = [[self colorForType:type] colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
        CGFloat pr, pg, pb, pa;
        [predefined getRed:&pr green:&pg blue:&pb alpha:&pa];

        CGFloat tolerance = 0.05;
        if (fabs(r - pr) < tolerance && fabs(g - pg) < tolerance && fabs(b - pb) < tolerance) {
            return type;
        }
    }

    return PSMTabGroupColorTypeCustom;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<PSMTabGroup: %@ name='%@' tabs=%lu collapsed=%@>",
            self.identifier, self.name, (unsigned long)self.tabCount, self.collapsed ? @"YES" : @"NO"];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[PSMTabGroup class]]) {
        return NO;
    }
    return [self.identifier isEqualToString:((PSMTabGroup *)object).identifier];
}

- (NSUInteger)hash {
    return [self.identifier hash];
}

@end
