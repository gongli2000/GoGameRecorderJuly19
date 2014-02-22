//
//  CalibrateView.h
//  GoGameRecorder
//
//  Created by Larry on 7/7/13.
//  Copyright (c) 2013 Larry. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyImageView.h"
#include <opencv2/opencv.hpp>

@class ViewController;

@interface CalibrateView : NSImageView
{
@public
    std::vector<cv::Point> _boardRect;
    MyImageView* boardView;
    VideoCapture* _videoCapture;
    
}
-(int) getRotation;
-(void) clearBoardRect;

-(void) setBoardRect: (std::vector<cv::Point>&)  r;

@property (assign) NSTrackingRectTag trackingRect;

@property (assign) NSPoint _mouseLoc;
@end
