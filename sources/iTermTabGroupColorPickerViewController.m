//
//  iTermTabGroupColorPickerViewController.m
//  iTerm2
//
//  Color picker popover for tab groups.
//

#import "iTermTabGroupColorPickerViewController.h"
#import "iTermTabGroup.h"

static const CGFloat kColorButtonSize = 28.0;
static const CGFloat kColorButtonSpacing = 8.0;
static const NSInteger kColorsPerRow = 5;

@interface iTermTabGroupColorPickerViewController () <NSPopoverDelegate>

@property (nonatomic, copy) iTermTabGroupColorPickerCompletion completion;
@property (nonatomic, strong, nullable) NSColor *currentColor;
@property (nonatomic, strong) NSPopover *popover;

@end

@implementation iTermTabGroupColorPickerViewController {
    NSStackView *_mainStack;
}

+ (void)showColorPickerRelativeToRect:(NSRect)rect
                               ofView:(NSView *)view
                        preferredEdge:(NSRectEdge)edge
                         currentColor:(NSColor *)currentColor
                           completion:(iTermTabGroupColorPickerCompletion)completion {
    iTermTabGroupColorPickerViewController *vc = [[iTermTabGroupColorPickerViewController alloc] init];
    vc.currentColor = currentColor;
    vc.completion = completion;

    vc.popover = [[NSPopover alloc] init];
    vc.popover.contentViewController = vc;
    vc.popover.behavior = NSPopoverBehaviorTransient;
    vc.popover.delegate = vc;

    [vc.popover showRelativeToRect:rect ofView:view preferredEdge:edge];
}

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 200, 150)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)setupUI {
    // Title label
    NSTextField *titleLabel = [NSTextField labelWithString:@"Choose Color"];
    titleLabel.font = [NSFont systemFontOfSize:12 weight:NSFontWeightMedium];
    titleLabel.alignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:titleLabel];

    // Colors grid
    NSArray<NSColor *> *colors = [iTermTabGroup predefinedColors];
    NSView *colorGrid = [self createColorGridWithColors:colors];
    colorGrid.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:colorGrid];

    // Remove color button
    NSButton *removeButton = [self createRemoveColorButton];
    removeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:removeButton];

    // Custom color button
    NSButton *customButton = [self createCustomColorButton];
    customButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:customButton];

    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:12],
        [titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [titleLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],

        [colorGrid.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:12],
        [colorGrid.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        [removeButton.topAnchor constraintEqualToAnchor:colorGrid.bottomAnchor constant:12],
        [removeButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],

        [customButton.topAnchor constraintEqualToAnchor:colorGrid.bottomAnchor constant:12],
        [customButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],

        [self.view.bottomAnchor constraintEqualToAnchor:removeButton.bottomAnchor constant:12],
    ]];

    // Calculate content size
    CGFloat gridWidth = kColorsPerRow * kColorButtonSize + (kColorsPerRow - 1) * kColorButtonSpacing;
    NSInteger rowCount = (colors.count + kColorsPerRow - 1) / kColorsPerRow;
    CGFloat gridHeight = rowCount * kColorButtonSize + (rowCount - 1) * kColorButtonSpacing;

    CGFloat contentWidth = MAX(gridWidth + 24, 200);
    CGFloat contentHeight = 12 + 18 + 12 + gridHeight + 12 + 24 + 12;

    self.preferredContentSize = NSMakeSize(contentWidth, contentHeight);
}

- (NSView *)createColorGridWithColors:(NSArray<NSColor *> *)colors {
    NSStackView *mainStack = [[NSStackView alloc] init];
    mainStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    mainStack.spacing = kColorButtonSpacing;
    mainStack.alignment = NSLayoutAttributeCenterX;

    NSStackView *currentRow = nil;
    NSInteger colorIndex = 0;

    for (NSColor *color in colors) {
        if (colorIndex % kColorsPerRow == 0) {
            currentRow = [[NSStackView alloc] init];
            currentRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
            currentRow.spacing = kColorButtonSpacing;
            [mainStack addArrangedSubview:currentRow];
        }

        NSButton *colorButton = [self createColorButtonWithColor:color];
        [currentRow addArrangedSubview:colorButton];
        colorIndex++;
    }

    return mainStack;
}

- (NSButton *)createColorButtonWithColor:(NSColor *)color {
    NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, kColorButtonSize, kColorButtonSize)];
    button.bordered = NO;
    button.wantsLayer = YES;
    button.layer.cornerRadius = kColorButtonSize / 2;
    button.layer.backgroundColor = color.CGColor;
    button.layer.borderWidth = 1.5;
    button.layer.borderColor = [color shadowWithLevel:0.2].CGColor;

    // Highlight current color
    if (self.currentColor && [self colorsAreSimilar:color to:self.currentColor]) {
        button.layer.borderColor = [NSColor selectedContentBackgroundColor].CGColor;
        button.layer.borderWidth = 3.0;
    }

    button.target = self;
    button.action = @selector(colorButtonClicked:);

    // Store color as associated object
    objc_setAssociatedObject(button, "color", color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // Size constraint
    [NSLayoutConstraint activateConstraints:@[
        [button.widthAnchor constraintEqualToConstant:kColorButtonSize],
        [button.heightAnchor constraintEqualToConstant:kColorButtonSize]
    ]];

    return button;
}

- (NSButton *)createRemoveColorButton {
    NSButton *button = [NSButton buttonWithTitle:@"Remove" target:self action:@selector(removeColorClicked:)];
    button.controlSize = NSControlSizeSmall;
    button.bezelStyle = NSBezelStyleRounded;
    return button;
}

- (NSButton *)createCustomColorButton {
    NSButton *button = [NSButton buttonWithTitle:@"Custom..." target:self action:@selector(customColorClicked:)];
    button.controlSize = NSControlSizeSmall;
    button.bezelStyle = NSBezelStyleRounded;
    return button;
}

#pragma mark - Actions

- (void)colorButtonClicked:(NSButton *)sender {
    NSColor *color = objc_getAssociatedObject(sender, "color");
    [self selectColor:color];
}

- (void)removeColorClicked:(id)sender {
    [self selectColor:nil];
}

- (void)customColorClicked:(id)sender {
    NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
    colorPanel.target = self;
    colorPanel.action = @selector(colorPanelColorChanged:);
    colorPanel.showsAlpha = NO;

    if (self.currentColor) {
        colorPanel.color = self.currentColor;
    }

    [colorPanel orderFront:nil];

    // Close the popover but keep the completion handler
    iTermTabGroupColorPickerCompletion completion = self.completion;
    self.completion = nil;  // Prevent calling from popover close

    [self.popover close];

    // Restore completion for color panel
    __weak typeof(self) weakSelf = self;
    colorPanel.action = @selector(colorPanelColorChanged:);

    // Store completion for later use
    objc_setAssociatedObject(colorPanel, "completion", completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)colorPanelColorChanged:(NSColorPanel *)sender {
    iTermTabGroupColorPickerCompletion completion = objc_getAssociatedObject(sender, "completion");
    if (completion) {
        completion(sender.color);
        objc_setAssociatedObject(sender, "completion", nil, OBJC_ASSOCIATION_ASSIGN);
        [sender orderOut:nil];
    }
}

- (void)selectColor:(NSColor *)color {
    if (self.completion) {
        self.completion(color);
    }
    [self.popover close];
}

#pragma mark - Helpers

- (BOOL)colorsAreSimilar:(NSColor *)color1 to:(NSColor *)color2 {
    NSColor *c1 = [color1 colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    NSColor *c2 = [color2 colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];

    if (!c1 || !c2) return NO;

    CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
    [c1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [c2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];

    CGFloat distance = sqrt(pow(r1 - r2, 2) + pow(g1 - g2, 2) + pow(b1 - b2, 2));
    return distance < 0.05;
}

#pragma mark - NSPopoverDelegate

- (void)popoverWillClose:(NSNotification *)notification {
    // If popover closes without selection, call completion with nil to indicate cancellation
    // But only if we haven't already called it
    if (self.completion) {
        // User cancelled by clicking outside
    }
}

@end
