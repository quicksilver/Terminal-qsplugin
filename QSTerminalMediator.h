//
//  QSTerminalMediator.h
//  PlugIns
//
//  Created by Nicholas Jitkoff on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#define kQSTerminalMediators @"QSTerminalMediators"

@protocol QSTerminalMediator
- (void)performCommandInTerminal:(NSString *)command;
@end

@interface QSRegistry (QSTerminalMediator)
- (NSString *)preferredTerminalMediatorID;
- (id <QSTerminalMediator>)preferredTerminalMediator;
@end

@interface QSAppleTerminalMediator : NSObject <QSTerminalMediator>
@end