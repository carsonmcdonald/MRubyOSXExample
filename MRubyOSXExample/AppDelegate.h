#import <Cocoa/Cocoa.h>

typedef void (^ DebugBlock)(NSString *);

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSButton *runButton;

@property (unsafe_unretained) IBOutlet NSTextView *outputTextView;

- (IBAction)runButtonAction:(id)sender;

- (IBAction)loadTestFileAction:(id)sender;

- (IBAction)openFileDialogAction:(id)sender;

@end
