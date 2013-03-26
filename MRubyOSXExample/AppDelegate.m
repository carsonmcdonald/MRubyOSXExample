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
        debugBlock(@"\n");
    }
    else
    {
        debugBlock([NSString stringWithFormat:@"Foo::printMessage => %s\n", mrb_str_ptr(message)->ptr]);
    }
    
    return mrb_nil_value();
}

// Redirect printed output the the output text area.
static mrb_value mrb_printstr(mrb_state *mrb, mrb_value self)
{
    mrb_value message;
    mrb_get_args(mrb, "o", &message);
    
    if(mrb_string_p(message))
    {
        debugBlock([NSString stringWithFormat:@"%s", mrb_str_ptr(message)->ptr]);
    }
    
    return message;
}

@implementation AppDelegate
{
    mrb_state *mrb;
    int irep_number;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    debugBlock = ^(NSString *message) {
        [_outputTextView insertText:[NSString stringWithFormat:@"%@", message]];
    };
    
    irep_number = -1;
}

- (IBAction)runButtonAction:(id)sender
{
    debugBlock(@"Run starting.\n");
    
    // Override the method used to print strings
    mrb_define_method(mrb, mrb->kernel_module, "__printstr__", mrb_printstr, ARGS_REQ(1));
    
    mrb_run(mrb, mrb_proc_new(mrb, mrb->irep[irep_number]), mrb_top_self(mrb));
    
    debugBlock(@"Run complete.\n");
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
        debugBlock(@"Error loading test file from bundle.\n");
        
        [self.runButton setEnabled:originalEnabled];
    }
    else
    {
        irep_number = mrb_read_irep_file(mrb, fp);

        if(irep_number < 0)
        {
            debugBlock(@"Error loading test.\n");
        }
        else
        {
            [self.runButton setEnabled:YES];
            
            debugBlock(@"Test loaded.\n");
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
                debugBlock([NSString stringWithFormat:@"Error loading test file: %@\n", fileDialog.URL.lastPathComponent]);
                
                [self.runButton setEnabled:originalEnabled];
            }
            else
            {
                irep_number = mrb_read_irep_file(mrb, fp);
                
                fclose(fp);
                
                if(irep_number < 0)
                {
                    debugBlock([NSString stringWithFormat:@"Error loading irep from: %@\n", fileDialog.URL.lastPathComponent]);
                }
                else
                {
                    [self.runButton setEnabled:YES];
                    
                    debugBlock([NSString stringWithFormat:@"Loaded: %@\n", fileDialog.URL.lastPathComponent]);
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
