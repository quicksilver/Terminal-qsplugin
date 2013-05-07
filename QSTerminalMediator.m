//
//  QSTerminalMediator.m
//  PlugIns
//
//  Created by Nicholas Jitkoff on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "QSTerminalMediator.h"

@implementation QSRegistry (QSTerminalMediator)

- (NSString *)preferredTerminalMediatorID{
	NSString *key=[[NSUserDefaults standardUserDefaults] stringForKey:kQSTerminalMediators];
	if (![[self tableNamed:kQSTerminalMediators]objectForKey:key])key=@"com.apple.Terminal";
	return key;
}

- (id <QSTerminalMediator>)preferredTerminalMediator{
	id mediator=[prefInstances objectForKey:kQSTerminalMediators];
	if (!mediator){
		mediator=[self instanceForKey:[self preferredTerminalMediatorID]
							  inTable:kQSTerminalMediators];
		if (mediator)
			[prefInstances setObject:mediator forKey:kQSTerminalMediators];
	}
	return mediator;
}
@end


@implementation QSAppleTerminalMediator
- (void)performCommandInTerminal:(NSString *)command{
    
    TerminalApplication *t = [SBApplication applicationWithBundleIdentifier:@"com.apple.Terminal"];
    
    // when tabs are made to work in Terminal, use this (will they ever?)
    /*
    TerminalTab *tab = [[[[t classForScriptingClass:@"tab"] alloc] init] autorelease];
    [[frontmost tabs] insertObject:tab atIndex:0];
     */
    [t activate];
    // developer feature!
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSTerminalUseTabs"]) {
        
        BOOL terminalRunning = [t isRunning];

        TerminalWindow *frontmost = nil;
        SBElementArray *windows = [t windows];
        NSIndexSet *frontmostIndex = [windows indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(TerminalWindow *w, NSUInteger idx, BOOL *stop) {
            return w.index == 1;
        }];
        if ([frontmostIndex count]) {
            frontmost = [windows objectAtIndex:[frontmostIndex lastIndex]];
        }
        
        if (terminalRunning) {
            // simulate CMD-T.
            CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStatePrivate);
            CGEventRef keyDown = CGEventCreateKeyboardEvent (source, (CGKeyCode)17, true); //T
            CGEventSetFlags(keyDown, kCGEventFlagMaskCommand);
            CGEventPost(kCGHIDEventTap, keyDown);
            
            CGEventRef keyUp = CGEventCreateKeyboardEvent (source, (CGKeyCode)17, false); //T key up
            CGEventSetFlags(keyUp, kCGEventFlagMaskCommand);
            CGEventPost(kCGHIDEventTap, keyUp);
            CFRelease(keyDown);
            CFRelease(keyUp);
            CFRelease(source);
        }
        [t doScript:command in:frontmost];
    } else {
        // in the future we should be able to use 'in:tab' to do the script in our new tab... if/when Tabs work in AS/SB
        [t doScript:command in:nil];
    }
}
@end
