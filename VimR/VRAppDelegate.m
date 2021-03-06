/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <TBCacao/TBCacao.h>
#import <MacVimFramework/MacVimFramework.h>
#import <CocoaLumberjack/DDLog.h>
#import "VRAppDelegate.h"
#import "VRWorkspaceController.h"
#import "VRMainWindowController.h"
#import "VRUtils.h"
#import "VRFileItemManager.h"
#import "VRWorkspace.h"
#import "VROpenQuicklyWindowController.h"
#import "VRDefaultLogSetting.h"


static NSString *const qVimRHelpUrl = @"http://vimdoc.sourceforge.net/htmldoc/";


@interface VRAppDelegate ()

@property VRMainWindowController *mainWindowController;

@end

@implementation VRAppDelegate

@manualwire(workspace)
@manualwire(workspaceController)
@manualwire(fileItemManager)
@manualwire(openQuicklyWindowController)

#pragma mark IBActions
- (IBAction)newDocument:(id)sender {
  [self applicationOpenUntitledFile:self.application];
}

- (IBAction)newTab:(id)sender {
  [self newDocument:sender];
}

- (IBAction)openDocument:(id)sender {
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  openPanel.allowsMultipleSelection = YES;

  if ([openPanel runModal] != NSOKButton) {
    DDLogDebug(@"no files selected");
    return;
  }

  DDLogDebug(@"opening %@", openPanel.URLs);
  [self application:self.application openFiles:openPanel.URLs];
}

- (IBAction)showHelp:(id)sender {
  [self.workspace openURL:[[NSURL alloc] initWithString:qVimRHelpUrl]];
}

- (IBAction)debug3Action:(id)sender {
  [self application:self.application openFiles:@[
      [NSURL fileURLWithPath:@"/Users/hat/Projects/vimr/Podfile"]
  ]];
}

#pragma mark NSObject
- (id)init {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  [[TBContext sharedContext] autowireSeed:self];

  return self;
}

#pragma mark NSApplicationDelegate
- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication {
  [self.workspaceController newWorkspace];
  return YES;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
  [self application:sender openFiles:@[filename]];
  return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
  /**
  * filenames consists of
  * - NSURLs when opening files via NSOpenPanel
  * - NSStrings when opening files via drag and drop on the VimR icon
  */

  if ([filenames[0] isKindOfClass:[NSURL class]]) {
    [self.workspaceController openFiles:filenames];
    return;
  }

  NSMutableArray *urls = [[NSMutableArray alloc] initWithCapacity:filenames.count];
  for (NSString *filename in filenames) {
    [urls addObject:[[NSURL alloc] initFileURLWithPath:filename]];
  }

  [self.workspaceController openFiles:urls];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
  // this cannot be done with TBCacao
  self.application = aNotification.object;

#ifdef DEBUG
  _debug.hidden = NO;
#endif
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  NSApplicationTerminateReply reply = NSTerminateNow;
  BOOL dirtyBuffersExist = NO;

  for (VRWorkspace *workspace in self.workspaceController.workspaces) {
    if (workspace.hasModifiedBuffer) {
      dirtyBuffersExist = YES;
      break;
    }
  }

  if (dirtyBuffersExist) {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSWarningAlertStyle;
    [alert addButtonWithTitle:@"Quit"];
    [alert addButtonWithTitle:@"Cancel"];
    alert.messageText = @"Quit without saving?";
    alert.informativeText = @"There are modified buffers, if you quit now all changes will be lost. Quit anyway?";

    if (alert.runModal != NSAlertFirstButtonReturn) {
      reply = NSTerminateCancel;
    }
  }

  return reply;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
  [self.workspaceController cleanUp];
  [self.fileItemManager cleanUp];
  [self.openQuicklyWindowController cleanUp];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
  return YES;
}

@end
