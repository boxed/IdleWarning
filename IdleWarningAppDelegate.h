#import <Cocoa/Cocoa.h>

@interface IdleWarningAppDelegate : NSObject <NSApplicationDelegate> {
    NSMutableArray *windows;
    long secs;
    BOOL showingWarning;
}

@end
