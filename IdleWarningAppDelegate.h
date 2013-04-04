//
//  IdleWarningAppDelegate.h
//  IdleWarning
//
//  Created by Anders Hovmöller on 2011-02-25.
//  Copyright 2011 TriOptima AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IdleWarningAppDelegate : NSObject <NSApplicationDelegate> {
    NSMutableArray *windows;
    long secs;
    BOOL showingWarning;
}

@end
