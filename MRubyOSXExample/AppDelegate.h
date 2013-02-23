#import <Cocoa/Cocoa.h>

typedef void (^ DebugBlock)(NSString *);

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (unsafe_unretained) IBOutlet NSTextView *outputTextView;

- (IBAction)runButtonAction:(id)sender;

@end
