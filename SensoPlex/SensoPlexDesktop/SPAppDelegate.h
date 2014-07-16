//
//  ADAppDelegate.h
//  CODesk
//
//  Created by Karthik Thirumalasetti on 16/07/14.
//  Copyright (c) 2014 alphadevs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SensoPlex.h"

@interface SPAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;


// flag that we set while we are displaying
@property (assign) BOOL isDisplaying;

// the SensoPlex object to work with to interact with the SP-10BN Module
@property (strong, nonatomic, retain) SensoPlex *sensoPlex;

// method that can be overidden to customize the UI display for specific
// connection states
- (void) showConnectionState:(SensoPlexState) state;

// show a status message (for a specified amount of time before auto-hiding)
- (void) showStatus:(NSString*)status for:(NSTimeInterval)forTime;


@end
