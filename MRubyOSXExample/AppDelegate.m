#import "AppDelegate.h"

#include "mruby/mruby.h"
#include "mruby/mruby/proc.h"
#include "mruby/mruby/dump.h"
#include "mruby/mruby/class.h"
#include "mruby/mruby/variable.h"
#include "mruby/mruby/data.h"
#include "mruby/mruby/array.h"
#include "mruby/mruby/string.h"

static DebugBlock debugBlock;

// Message printing class method call
static mrb_value foo_print_message(mrb_state* mrb, mrb_value obj)
{
    mrb_value message;
    mrb_get_args(mrb, "o", &message);
    
    if (mrb_nil_p(message))
    {
        debugBlock(@"");
    }
    else
    {
        debugBlock([NSString stringWithFormat:@"Foo::printMessage => %s", mrb_str_ptr(message)->ptr]);
    }
    
    return mrb_nil_value();
}

@implementation AppDelegate
{
    mrb_state *mrb;
    int irep_number;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    debugBlock = ^(NSString *message) {
        [_outputTextView insertText:[NSString stringWithFormat:@"%@\n", message ]];
    };
    
    irep_number = -1;
}

- (IBAction)runButtonAction:(id)sender
{
    debugBlock(@"Run starting.");
    
    mrb_run(mrb, mrb_proc_new(mrb, mrb->irep[irep_number]), mrb_top_self(mrb));
    
    debugBlock(@"Run complete.");
}

- (IBAction)loadTestFileAction:(id)sender
{
    bool originalEnabled = [self.runButton isEnabled];
    [self.runButton setEnabled:NO];
    
    NSString *bundleLocation = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test.mrb"];
    
    mrb = mrb_open();
    
    struct RClass *foo_module = mrb_define_module(mrb, "Foo");
    
    // Define a class method with no args
    mrb_define_class_method(mrb, foo_module, "print", foo_print_message, ARGS_REQ(1));
    
    FILE *fp = fopen([bundleLocation UTF8String], "rb");
    if (fp == NULL)
    {
        debugBlock(@"Error loading test file from bundle.");
        
        [self.runButton setEnabled:originalEnabled];
    }
    else
    {
        irep_number = mrb_read_irep_file(mrb, fp);

        if(irep_number < 0)
        {
            debugBlock(@"Error loading test.");
        }
        else
        {
            [self.runButton setEnabled:YES];
            
            debugBlock(@"Test loaded.");
        }
        
        [self.runButton setEnabled:YES];

        fclose(fp);
    }
}

- (IBAction)openFileDialogAction:(id)sender
{
    bool originalEnabled = [self.runButton isEnabled];
    [self.runButton setEnabled:NO];
    
    NSOpenPanel *fileDialog = [NSOpenPanel openPanel];
    
    fileDialog.canChooseDirectories = NO;
    fileDialog.canChooseFiles = YES;
    fileDialog.allowsMultipleSelection = NO;
    
    [fileDialog beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
       
        if(result == NSFileHandlingPanelOKButton)
        {
            mrb = mrb_open();
            
            
            FILE *fp = fopen([fileDialog.URL.path UTF8String], "rb");
            if (fp == NULL)
            {
                debugBlock([NSString stringWithFormat:@"Error loading test file: %@", fileDialog.URL.lastPathComponent]);
                
                [self.runButton setEnabled:originalEnabled];
            }
            else
            {
                irep_number = mrb_read_irep_file(mrb, fp);
                
                fclose(fp);
                
                if(irep_number < 0)
                {
                    debugBlock([NSString stringWithFormat:@"Error loading: %@", fileDialog.URL.lastPathComponent]);
                }
                else
                {
                    [self.runButton setEnabled:YES];
                    
                    debugBlock([NSString stringWithFormat:@"Loaded: %@", fileDialog.URL.lastPathComponent]);
                }
            }
        }
        else
        {
            [self.runButton setEnabled:originalEnabled];
        }
        
    }];
}

@end
