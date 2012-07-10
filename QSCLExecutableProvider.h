@interface QSCLExecutableProvider : QSActionProvider {
	IBOutlet NSWindow *window;
}

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject;
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject;
- (QSObject *) executeObject:(QSObject *)dObject arguments:(QSObject *)iObject;
- (QSObject *) executeObjectInTerm:(QSObject *)dObject arguments:(QSObject *)iObject;
- (NSString *)runExecutable:(NSString *)path withArguments:(NSString *)arguments inTerminal:(BOOL)inTerminal;
- (NSString *)escapeString:(NSString *)string;
- (QSObject *) showManPage:(QSObject *)dObject;
- (QSObject *) executeText:(QSObject *)dObject;
- (QSObject *) executeTextInTerminal:(QSObject *)dObject;
- (void)openTerminalAtDirectory:(NSString *)path;
- (QSObject *)showParentDirectoryInTerminal:(QSObject *)dObject;
- (QSObject *)showDirectoryInTerminal:(QSObject *)dObject;
- (void)performCommandInTerminal:(NSString *)command;
- (void)ok:(id)sender;
- (void)cancel:(id)sender;
- (BOOL)sudoIfNeeded;
- (void)setQuickIconForObject:(QSObject *)object;

@end
