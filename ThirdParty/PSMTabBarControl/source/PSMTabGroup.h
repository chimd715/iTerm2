//
//  PSMTabGroup.h
//  PSMTabBarControl
//
//  Chrome-like tab group support for PSMTabBarControl.
//

#import <Cocoa/Cocoa.h>

@class PSMTabBarControl;

NS_ASSUME_NONNULL_BEGIN

// Chrome-like predefined group colors
typedef NS_ENUM(NSInteger, PSMTabGroupColorType) {
    PSMTabGroupColorTypeGrey = 0,
    PSMTabGroupColorTypeBlue,
    PSMTabGroupColorTypeRed,
    PSMTabGroupColorTypeYellow,
    PSMTabGroupColorTypeGreen,
    PSMTabGroupColorTypePink,
    PSMTabGroupColorTypePurple,
    PSMTabGroupColorTypeCyan,
    PSMTabGroupColorTypeCustom
};

@interface PSMTabGroup : NSObject

#pragma mark - Properties

// Unique identifier for this group
@property (nonatomic, copy, readonly) NSString *identifier;

// Display name of the group (shown in header when expanded, always shown when collapsed)
@property (nonatomic, copy) NSString *name;

// Group color (applied to header and underline)
@property (nonatomic, strong, nullable) NSColor *color;

// Color type for predefined colors
@property (nonatomic, assign) PSMTabGroupColorType colorType;

// Whether the group is collapsed (only header visible)
@property (nonatomic, assign, getter=isCollapsed) BOOL collapsed;

// Tab identifiers in this group (in order)
@property (nonatomic, copy, readonly) NSArray *tabIdentifiers;

// Number of tabs in group
@property (nonatomic, readonly) NSUInteger tabCount;

#pragma mark - Initialization

// Create a new group with auto-generated identifier
- (instancetype)initWithName:(NSString *)name;

// Create a new group with specific identifier
- (instancetype)initWithIdentifier:(NSString *)identifier name:(NSString *)name;

// Create with color type
- (instancetype)initWithName:(NSString *)name colorType:(PSMTabGroupColorType)colorType;

#pragma mark - Tab Management

// Add a tab identifier to the group
- (void)addTabIdentifier:(id)identifier;

// Insert a tab identifier at specific index
- (void)insertTabIdentifier:(id)identifier atIndex:(NSUInteger)index;

// Remove a tab identifier from the group
- (void)removeTabIdentifier:(id)identifier;

// Check if group contains tab
- (BOOL)containsTabIdentifier:(id)identifier;

// Get index of tab in group
- (NSUInteger)indexOfTabIdentifier:(id)identifier;

#pragma mark - Color Utilities

// Get NSColor for color type
+ (NSColor *)colorForType:(PSMTabGroupColorType)type;

// Get all predefined colors
+ (NSArray<NSColor *> *)predefinedColors;

// Get color type from NSColor (returns PSMTabGroupColorTypeCustom if not predefined)
+ (PSMTabGroupColorType)colorTypeForColor:(NSColor *)color;

#pragma mark - Visual Properties

// Computed frame for the group header (set by tab bar during layout)
@property (nonatomic, assign) NSRect headerFrame;

// Total frame covering all tabs in the group (set by tab bar during layout)
@property (nonatomic, assign) NSRect groupFrame;

@end

NS_ASSUME_NONNULL_END
