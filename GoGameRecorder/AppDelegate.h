//
//  AppDelegate.h
//  GoGameRecorder
//
//  Created by Larry on 6/28/13.
//  Copyright (c) 2013 Larry. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (weak) IBOutlet NSMenuItem *boardSize;

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSScrollView *textLogView;
@property (unsafe_unretained) IBOutlet NSTextView *textViewForLog;
@property (weak) IBOutlet NSImageView *debugview;
@property (weak) IBOutlet NSImageView *debugview2;

- (IBAction)doitem:(id)sender;
- (IBAction)doAutoCalibrate:(id)sender;
- (IBAction)doRecordGame:(id)sender;
- (IBAction)doStopRecordGame:(id)sender;
- (IBAction)doContinueRecord:(id)sender;
- (IBAction)doRecordSnapshots:(id)sender;
- (IBAction)doRecordSnapshotsDebug:(id)sender;
- (IBAction)doStopRecordSnapshots:(id)sender;
- (IBAction)doContinueRecodSnapshots:(id)sender;
- (IBAction)doEditSnapshots:(id)sender;
- (IBAction)doExportSGF:(id)sender;
- (IBAction)doRotateBoard:(id)sender;
- (IBAction)doResetSavedView:(id)sender;
- (IBAction)doManualCalibration:(id)sender;
- (IBAction)handleNavigateMenus:(id)sender;
- (IBAction)handleBoardSizeMenus:(id)sender;


- (IBAction)handleDebug:(id)sender;



@property (nonatomic,strong) IBOutlet ViewController *viewController;

@end
