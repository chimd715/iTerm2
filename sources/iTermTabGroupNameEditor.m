//
//  iTermTabGroupNameEditor.m
//  iTerm2
//
//  Inline name editor for tab groups.
//

#import "iTermTabGroupNameEditor.h"
#import "iTermTabGroup.h"

@interface iTermTabGroupNameEditorViewController : NSViewController <NSTextFieldDelegate, NSPopoverDelegate>

@property (nonatomic, strong) iTermTabGroup *tabGroup;
@property (nonatomic, copy) iTermTabGroupNameEditorCompletion completion;
@property (nonatomic, strong) NSPopover *popover;
@property (nonatomic, strong) NSTextField *textField;

@end

@implementation iTermTabGroupNameEditorViewController

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 200, 40)];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 180, 22)];
    self.textField.stringValue = self.tabGroup.name ?: @"";
    self.textField.delegate = self;
    self.textField.font = [NSFont systemFontOfSize:13];
    self.textField.placeholderString = @"Group name";
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.textField];

    [NSLayoutConstraint activateConstraints:@[
        [self.textField.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:10],
        [self.textField.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-10],
        [self.textField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:10],
        [self.textField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-10],
    ]];

    self.preferredContentSize = NSMakeSize(200, 42);
}

- (void)viewDidAppear {
    [super viewDidAppear];
    // Focus the text field and select all text
    [self.view.window makeFirstResponder:self.textField];
    [self.textField selectText:nil];
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    NSInteger movement = [notification.userInfo[@"NSTextMovement"] integerValue];
    if (movement == NSReturnTextMovement) {
        NSString *newName = [self.textField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (newName.length > 0) {
            if (self.completion) {
                self.completion(newName);
            }
        }
    }
    [self.popover close];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(cancelOperation:)) {
        // Escape key pressed
        [self.popover close];
        return YES;
    }
    return NO;
}

#pragma mark - NSPopoverDelegate

- (void)popoverWillClose:(NSNotification *)notification {
    // Don't call completion on close - it's called in controlTextDidEndEditing if needed
}

@end

@implementation iTermTabGroupNameEditor

+ (void)editNameForGroup:(iTermTabGroup *)group
          relativeToRect:(NSRect)rect
                  ofView:(NSView *)view
           preferredEdge:(NSRectEdge)edge
              completion:(iTermTabGroupNameEditorCompletion)completion {

    iTermTabGroupNameEditorViewController *vc = [[iTermTabGroupNameEditorViewController alloc] init];
    vc.tabGroup = group;
    vc.completion = completion;

    vc.popover = [[NSPopover alloc] init];
    vc.popover.contentViewController = vc;
    vc.popover.behavior = NSPopoverBehaviorTransient;
    vc.popover.delegate = vc;

    [vc.popover showRelativeToRect:rect ofView:view preferredEdge:edge];
}

@end
