//
//  IdleWarningAppDelegate.m
//  IdleWarning
//
//  Created by Anders Hovmöller on 2011-02-25.
//  Copyright 2011 TriOptima AB. All rights reserved.
//

#import "IdleWarningAppDelegate.h"
#include <IOKit/IOKitLib.h>

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/graphics/IOGraphicsLib.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

/* 10^9 --  number of ns in a second */
#define NS_SECONDS 1000000000

long SystemIdleTime() {
    long result;
    mach_port_t masterPort;
    io_iterator_t iter;
    io_registry_entry_t curObj;
    
    IOMasterPort(MACH_PORT_NULL, &masterPort);
    
    /* Get IOHIDSystem */
    IOServiceGetMatchingServices(masterPort,
                                 IOServiceMatching("IOHIDSystem"),
                                 &iter);
    if (iter == 0) {
        printf("Error accessing IOHIDSystem\n");
        exit(1);
    }
    
    curObj = IOIteratorNext(iter);
    
    if (curObj == 0) {
        printf("Iterator's empty!\n");
        exit(1);
    }
    
    CFMutableDictionaryRef properties = 0;
    CFTypeRef obj;
    
    if (IORegistryEntryCreateCFProperties(curObj, &properties,
                                          kCFAllocatorDefault, 0) ==
        KERN_SUCCESS && properties != NULL) {
        
        obj = CFDictionaryGetValue(properties, CFSTR("HIDIdleTime"));
        CFRetain(obj);
    } else {
        printf("Couldn't grab properties of system\n");
        obj = NULL;
    }
    
    if (obj) {
        uint64_t tHandle;
        
        CFTypeID type = CFGetTypeID(obj);
        
        if (type == CFDataGetTypeID()) {
            CFDataGetBytes((CFDataRef) obj,
                           CFRangeMake(0, sizeof(tHandle)),
                           (UInt8*) &tHandle);
        }  else if (type == CFNumberGetTypeID()) {
            CFNumberGetValue((CFNumberRef)obj,
                             kCFNumberSInt64Type,
                             &tHandle);
        } else {
            printf("%d: unsupported type\n", (int)type);
            exit(1);
        }
        
        CFRelease(obj);
        
        // essentially divides by 10^9
        tHandle >>= 30;
        result = tHandle;
    } else {
        printf("Can't find idle time\n");
    }
    
    /* Release our resources */
    IOObjectRelease(curObj);
    IOObjectRelease(iter);
    CFRelease((CFTypeRef)properties);
    
    return result;
}

NSString* RunAndReturnStdOut(NSString* input)
{
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/bash"];
    
    NSArray *arguments;
    arguments = [NSArray arrayWithObjects:@"-c", input, nil];
    [task setArguments:arguments];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *string;
    string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    return string;
}


@implementation IdleWarningAppDelegate

- (void)recreateWindows {
    NSArray* screens = [NSScreen screens];
    self->windows = [NSMutableArray arrayWithCapacity:[screens count]];
    for (id screen in screens) {
        NSRect frame = [screen frame];
        NSWindow* window = [[NSWindow alloc] initWithContentRect:frame styleMask: NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        [window setLevel:NSFloatingWindowLevel];
        [window setIgnoresMouseEvents:TRUE];
        frame.origin.x = frame.origin.y = 0;
        [window setBackgroundColor:[NSColor blackColor]];
        [self->windows addObject:window];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
    
    NSString* idleTimeout1_secs = RunAndReturnStdOut(@"defaults -currentHost read com.apple.screensaver | grep idleTime | sed 's/    idleTime = //' | sed 's/;//'");
    NSString* idleTimeout2_mins = RunAndReturnStdOut(@"cat /Library/Preferences/SystemConfiguration/com.apple.PowerManagement.plist | grep -A 1 'Display Sleep Timer' | grep 'integer' | sed 's/<integer>//' | sed 's/<\\/integer>//' | sed 's/^[[:space:]]*\\(.*\\)[[:space:]]*$/\\1/'");
    secs = MIN([idleTimeout1_secs longLongValue], [idleTimeout2_mins longLongValue]*60);

}

- (void)hideWarning {
    if (!self->showingWarning)
        return;
    self->showingWarning = NO;
    for (NSWindow* window in self->windows) {
        [window setAlphaValue:0.0];
        [window setIsVisible:FALSE];
    }
}


- (void)showWarning {
    if (self->showingWarning)
        return;
    self->showingWarning = YES;
    [self recreateWindows];
    for (NSWindow* window in self->windows) {
        [window setIsVisible:TRUE];
        [[window animator] setAlphaValue:0.6];
        [window setLevel:2000];
    }
}

- (void)timer:(id)sender {
    long timeLeft = secs-SystemIdleTime();
    //[idleTime setStringValue:[NSString stringWithFormat:@"%d", timeLeft]];
    //NSLog(@"Time left: %ld", timeLeft);
    if (timeLeft > 40) // 40
    {
        [self hideWarning];
    }
    else
    {
        [self showWarning];
    }
}

@end
