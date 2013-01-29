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
    TerminalApplication *t = [TerminalApplication application];
    /* Can't do anything with windows/tabs atm
    TerminalWindow *frontmost = nil;
    SBElementArray *windows = [t windows];
    NSIndexSet *frontmostIndex = [windows indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(TerminalWindow *w, NSUInteger idx, BOOL *stop) {
        return t.frontmost;
    }];
    if ([frontmostIndex count]) {
        frontmost = [windows objectAtIndex:[frontmostIndex lastIndex]];
    }
    if (frontmost) {
        
    } */
    [t doScript:command in:nil];
    [t activate];
}
@end
