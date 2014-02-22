//
//  ViewController.h
//  GoGameRecorder
//
//  Created by Larry on 6/29/13.
//  Copyright (c) 2013 Larry. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <opencv2/opencv.hpp>
#import "Node.h"
#import "Board.h"
#import "MyImageView.h"
#import "CalibrateView.h"
using namespace cv;
using namespace std;


void ddd(cv::Mat &x);

@interface ViewController : NSViewController{
@public
    int _diffmin;
    int _diffmax;
    float _blackthreshold;
    float _whitethreshold;
    
    NSImageView *imageView;
    VideoCapture* _videoCapture;
    cv::Mat _lastFrame;
    bool _docalibrate;
    cv::Mat _map;
    cv::Mat _prevImage;
    cv::Mat _savedImage;
    cv::Mat _boardImage;
    std::vector<cv::Point> _convexHull;
    //std::vector<Node*> _moves;
    bool _startmotion;
    int _imageindex;
    int _orientation;
    int _boardsize;
    bool _undolastmove;
    int _numfiles;
    bool _blacksmove;
    bool _debug;
    
}


@property (weak) IBOutlet NSImageCell *imageCell;
@property (unsafe_unretained) NSTextView *textViewForLog;
@property (weak) IBOutlet CalibrateView *calibrateView;
@property (weak) IBOutlet MyImageView *boardView;
@property (weak) IBOutlet NSImageView *debugview;
@property (weak) IBOutlet NSImageView *debugview2;
@property (strong) NSString* currentdir;
@property (nonatomic, strong) NSTimer *runTimer;
@property (nonatomic, strong) NSTimer *runTimer2;

- (IBAction)selectBoardSize:(id)sender;
- (IBAction)changeColor:(id)sender;
- (IBAction)stopAutoCalibrate:(id)sender;
- (IBAction)startAutoCalibrate:(id)sender;
- (IBAction)doRecordGame:(id)sender;
- (IBAction)resetSavedView:(id)sender;
- (IBAction)rotateBoard:(id)sender;
- (IBAction)savetoSGF:(id)sender;
- (IBAction)pauseRecording:(id)sender;
- (IBAction)continueRecordingSnaphots:(id)sender;
- (IBAction)continueRecording:(id)sender;
- (IBAction)firstMove:(id)sender;
- (IBAction)prevMove:(id)sender;
- (IBAction)nextMove:(id)sender;
- (IBAction)lastMove:(id)sender;
- (IBAction)undoLastMove:(id)sender;
- (IBAction)recordSnapshots:(id)sender;
- (IBAction)recordSnapshotsForDebug:(id)sender;
- (IBAction)editSnapshots:(id)sender;
-(IBAction) doManualCalibration:(id)sender;
- (IBAction)stopRecording:(id)sender;
-(IBAction) handleNavigateMenus:(id)sender;
-(IBAction) handleDebugMenu:(id)sender;

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;
-(void) capturemovesForEditing;

@end
