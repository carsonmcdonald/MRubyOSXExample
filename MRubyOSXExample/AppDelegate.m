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
    
    if (mrb_nil_p(message)) {
        debugBlock(@"");
    } else {
        debugBlock([NSString stringWithFormat:@"Foo::printMessage => %s", mrb_str_ptr(message)->ptr]);
    }
    
    return mrb_nil_value();
}

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

- (IBAction)runButtonAction:(id)sender
{
    debugBlock = ^(NSString *message){
        [_outputTextView insertText:[NSString stringWithFormat:@"%@\n", message ]];
    };
    
    NSString *bundleLocation = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test.mrb"];
    
    mrb_state *mrb = mrb_open();;
    
    struct RClass *foo_module = mrb_define_module(mrb, "Foo");
    
    // Define a class method not no args
    mrb_define_class_method(mrb, foo_module, "print", foo_print_message, ARGS_REQ(1));
    
    FILE *fp = fopen([bundleLocation UTF8String], "rb");
    if (fp == NULL) {
        NSLog(@"Error loading file...");
    } else {
        int irep_number = mrb_read_irep_file(mrb, fp);
        
        mrb_run(mrb, mrb_proc_new(mrb, mrb->irep[irep_number]), mrb_top_self(mrb));
        
        fclose(fp);
    }
}

@end
