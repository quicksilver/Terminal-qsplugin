#import "QSCLExecutableProvider.h"
#import "QSTerminalMediator.h"
#include "QSTerminalPlugIn.h"

//#define kQSCLExecuteAction @"ShellScriptRunAction"
#define kQSCLExecuteWithArgsAction @"QSShellScriptRunAction"
//#define kQSCLTermExecuteAction @"QSCLTermExecuteAction"
#define kQSCLTermExecuteWithArgsAction @"QSCLTermExecuteWithArgsAction"
#define kQSCLTermExecuteWithRequiredArgsAction @"QSCLTermExecuteWithRequiredArgsAction"
#define kQSCLTermShowDirectoryAction @"QSCLTermShowDirectoryAction"
#define kQSCLTermShowManPageAction @"QSCLTermShowManPageAction"
#define kQSCLTermOpenParentAction @"QSCLTermOpenParentAction"
#define kQSShellScriptRunWithArgsAction @"QSShellScriptRunWithArgsAction"
#define kQSCLExecuteTextAction @"QSCLExecuteTextAction"
#define kQSCLTermExecuteTextAction @"QSCLTermExecuteTextAction"

@implementation QSCLExecutableProvider

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject
{
  if ([dObject objectForType:QSFilePathType])
  {
    NSString *path = [dObject singleFilePath];
    if (!path) return nil;
    
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) return nil;
    
    if (isDirectory) return [NSArray arrayWithObject:kQSCLTermShowDirectoryAction];
    
    if (UTTypeConformsTo((CFStringRef)[dObject fileUTI], (CFStringRef)@"public.script") || UTTypeConformsTo((CFStringRef)[dObject fileUTI], (CFStringRef)@"public.executable"))
    {
        BOOL executable = [[NSFileManager defaultManager] isExecutableFileAtPath:path];
        if (!executable) {
            NSFileHandle * fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
            // Read in the first 5 bytes of the file to see if it contains #! (5 bytes, because some files contain byte order marks (3 bytes)
            NSData * buffer = [fileHandle readDataOfLength:5];
            NSString *string = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
            if ([string containsString:@"#!"]) {
                executable = YES;
            }
            [string release];
        } else {
            if ([dObject isApplication]) // Ignore applications
                return NO;
        }
        
        if (executable) return [NSArray arrayWithObjects:kQSCLExecuteWithArgsAction, kQSCLTermExecuteWithArgsAction, kQSCLTermExecuteWithRequiredArgsAction, kQSCLTermShowManPageAction, kQSCLTermOpenParentAction,kQSShellScriptRunWithArgsAction, nil];
    }
    
    return [NSArray arrayWithObject:kQSCLTermOpenParentAction];
  }
  
  return nil;
}

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject{
    QSObject *proxy=[QSObject textProxyObjectWithDefaultValue:@""];
    return [NSArray arrayWithObject:proxy];
    
}

- (QSObject *) executeObject:(QSObject *)dObject arguments:(QSObject *)iObject{
	NSString *result=[self runExecutable:[(QSObject *)dObject singleFilePath] withArguments:[iObject stringValue] inTerminal:NO];
    if ([result length]) return [QSObject objectWithString:result];
    return nil;
}

- (QSObject *) executeObjectInTerm:(QSObject *)dObject arguments:(QSObject *)iObject{    
    NSString *result=[self runExecutable:[(QSObject *)dObject singleFilePath] withArguments:[iObject stringValue] inTerminal:YES];
    if ([result length]) return [QSObject objectWithString:result];
    return nil;
}

- (NSString *)runExecutable:(NSString *)path withArguments:(NSString *)arguments inTerminal:(BOOL)inTerminal{
    BOOL executable=[[NSFileManager defaultManager] isExecutableFileAtPath:path];
    
    NSString *taskPath=path;
    NSMutableArray *argArray=[NSMutableArray array]; 
    NSCharacterSet *ws = [NSCharacterSet whitespaceCharacterSet];
    
    if (!executable) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
        if (!fileHandle)
            return nil;

        NSData *buffer = [fileHandle readDataOfLength:1024];
        [fileHandle closeFile];
        NSString *contents = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];

        NSScanner *scanner = [NSScanner scannerWithString:contents];
        [contents release];

        /* Doesn't start with a shebang, there's nothing we can do */
        if (![scanner scanString:@"#!" intoString:nil]) {
            return nil;
        }

        /* Scan the shebang line */
        NSString *shellLine = nil;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&shellLine];

        /* Split up the executable path and its parameters... */
        NSArray *shellLineParameters = [shellLine componentsSeparatedByCharactersInSet:ws];
        taskPath = [shellLineParameters head];
        [argArray addObjectsFromArray:[shellLineParameters tail]];

        /* ... and append the path to the actual file to execute */
        [argArray addObject:path];
    }
    
    // include arguments for the command
    if ([arguments length]) {
        NSArray *commandArguments = [arguments componentsSeparatedByCharactersInSet:ws];
        [argArray addObjectsFromArray:commandArguments];
    }
	
    if (inTerminal) {
        NSString *fullCommand=[NSString stringWithFormat:@"%@ %@",[self escapeString:taskPath],[argArray componentsJoinedByString:@" "]];
        [self performCommandInTerminal:fullCommand];      
		///  NSLog(@"Run Shell Script: %@",fullCommand);
    }else{
        
        NSTask *task=[[[NSTask alloc]init]autorelease];
        [task setLaunchPath:taskPath];
        [task setArguments:argArray];
        [task setStandardOutput:[NSPipe pipe]];
        [task launch];
        [task waitUntilExit];
		// NSLog(@"Run Task: %@ %@",taskPath,argArray);
        
        NSString *string=[[[NSString alloc] initWithData:[[[task standardOutput]fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding]autorelease];
        int status = [task terminationStatus];
        if (status == 0) NSLog(@"Task succeeded.");
        else NSLog(@"Task failed.");
        return string;
	}
	return nil;
}
- (NSString *)escapeString:(NSString *)string{
    NSString *escapeString=@"\\!$&\"'*(){[|;<>?~` ";
    
    for (NSUInteger i = 0; i < [escapeString length]; i++) {
        NSString *thisString=[escapeString substringWithRange:NSMakeRange(i,1)];
        string=[[string componentsSeparatedByString:thisString]componentsJoinedByString:[@"\\" stringByAppendingString:thisString]];
        
    }
    return string;
}

- (QSObject *) showManPage:(QSObject *)dObject{
    NSString *path=[dObject singleFilePath];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"x-man-page://%@",[path lastPathComponent]]]];
    return nil;
}

- (QSObject *) executeText:(QSObject *)dObject{
	NSString *string=[dObject objectForType:QSShellCommandType];
	if (!string)string=[dObject stringValue];
	
	if ([string rangeOfString:@"sudo" options:NSCaseInsensitiveSearch].location!=NSNotFound){
#ifdef DEBUG
		NSLog(@"sudo in %@",string);
#endif
		if (![self sudoIfNeeded]){
			NSBeep();
			return nil;
		}
	}
    NSTask *task=[[[NSTask alloc]init]autorelease];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:[NSArray arrayWithObjects:@"-c",string,nil]];
    [task setStandardOutput:[NSPipe pipe]];
    [task launch];
    [task waitUntilExit];
	
    NSString *result=[[[NSString alloc] initWithData:[[[task standardOutput]fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding]autorelease];
    int status = [task terminationStatus];
    if (status == 0) NSLog(@"Task succeeded.");
    else NSLog(@"Task failed.");
    
    if ([result length]) 
        return [QSObject objectWithString:result];
    
    return nil;
}

- (QSObject *) executeTextInTerminal:(QSObject *)dObject{
	NSString *string=[dObject objectForType:QSShellCommandType];
	if (!string)string=[dObject stringValue];
    [self performCommandInTerminal:string];
	return nil;
}

- (void)openTerminalAtDirectory:(NSString *)path
{
  BOOL isDir = NO;
  while (!([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir))
  {
    NSArray *comps = [path pathComponents];
    path = [NSString pathWithComponents:[comps subarrayWithRange:(NSRange){0, [comps count] - 1}]];
  }
  [self performCommandInTerminal:[NSString stringWithFormat:@"cd %@", [self escapeString:path]]];
}

-(void)displayOpenTerminalError {
    NSBeep();
    QSShowAppNotifWithAttributes(@"TerminalNotif", NSLocalizedStringFromTableInBundle(@"Terminal Plugin", nil, [NSBundle bundleForClass:[self class]], @""), NSLocalizedStringFromTableInBundle(@"Could not open directory", nil, [NSBundle bundleForClass:[self class]], @""));
}

- (QSObject *)showParentDirectoryInTerminal:(QSObject *)dObject
{
  NSString *path = [dObject singleFilePath];
    if (!path) {
        [self displayOpenTerminalError];
        return nil;
    }
  NSArray *comps = [path pathComponents];
  if ([comps count] > 1) path = [NSString pathWithComponents:[comps subarrayWithRange:(NSRange){0, [comps count] - 1}]];
  [self openTerminalAtDirectory:path];
  return nil;
}

- (QSObject *)showDirectoryInTerminal:(QSObject *)dObject
{
  NSString *path = [dObject singleFilePath];
    if (!path) {
        [self displayOpenTerminalError];
        return nil;
    }
  [self openTerminalAtDirectory:path];
  return nil;
}

- (void)performCommandInTerminal:(NSString *)command{
	[[QSReg preferredTerminalMediator] performCommandInTerminal:(NSString *)command];
}
- (void)ok:(id)sender{[NSApp stopModalWithCode:1];}
- (void)cancel:(id)sender{[NSApp stopModalWithCode:0];}



- (BOOL)sudoIfNeeded{
	int status=1;
	while (status) {
		NSTask *task=[NSTask taskWithLaunchPath:@"/usr/bin/sudo" arguments:[NSArray arrayWithObjects:@"-v",@"-S",nil]];
		[task setStandardInput:[NSPipe pipe]];
		[task setStandardError:[NSPipe pipe]];
		[task launch];
		NSData *data= [[[task standardError] fileHandleForReading] availableData];

		// Password is required
		if ([data length]) {
			__block NSModalResponse result = 0;
			__block NSString *string = nil;
			QSGCDMainSync(^{
				if (!window) {
					[NSBundle loadNibNamed:@"QSSudoPasswordAlert" owner:self];
				}
				[window makeKeyAndOrderFront:self];
				result = [NSApp runModalForWindow:window];
				if (result) {
					// Obtains the password from the window, initial first responder is always the secure text field
					string = [[[(NSSecureTextField *)[window initialFirstResponder] stringValue] stringByAppendingString:@"\n"] copy];
				}
				[window close];
			});
			
			if (!result){
				[task interrupt];
				return NO;
			}
			
			NSData *writeData = [string dataUsingEncoding:NSUTF8StringEncoding];
			[[[task standardInput]fileHandleForWriting] writeData:writeData];
			[[[task standardInput]fileHandleForWriting] closeFile];
		}
		
		usleep(250000);	
		if ([task isRunning])
			[task interrupt];
		else
			status=[task terminationStatus];
		if (status)
			NSBeep();
		//NSLog(@"term %d",status);
	}
	return !status;
}


- (void)setQuickIconForObject:(QSObject *)object{
	[object setIcon:[QSResourceManager imageNamed:@"ExecutableBinaryIcon"]];	
}

@end




