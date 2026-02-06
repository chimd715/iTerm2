//
//  iTermTabGroupColorPickerViewController.h
//  iTerm2
//
//  Color picker popover for tab groups.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class iTermTabGroup;

typedef void (^iTermTabGroupColorPickerCompletion)(NSColor * _Nullable selectedColor);

@interface iTermTabGroupColorPickerViewController : NSViewController

// Show the color picker popover
+ (void)showColorPickerRelativeToRect:(NSRect)rect
                               ofView:(NSView *)view
                        preferredEdge:(NSRectEdge)edge
                         currentColor:(nullable NSColor *)currentColor
                           completion:(iTermTabGroupColorPickerCompletion)completion;

@end

NS_ASSUME_NONNULL_END
