//
//  iTermTabGroupNameEditor.h
//  iTerm2
//
//  Inline name editor for tab groups.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class iTermTabGroup;

typedef void (^iTermTabGroupNameEditorCompletion)(NSString * _Nullable newName);

@interface iTermTabGroupNameEditor : NSObject

// Show the name editor popover
+ (void)editNameForGroup:(iTermTabGroup *)group
          relativeToRect:(NSRect)rect
                  ofView:(NSView *)view
           preferredEdge:(NSRectEdge)edge
              completion:(iTermTabGroupNameEditorCompletion)completion;

@end

NS_ASSUME_NONNULL_END
