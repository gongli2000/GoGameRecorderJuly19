//
//  ViewController.m
//  GoGameRecorder
//
//  Created by Larry on 6/29/13.
//  Copyright (c) 2013 Larry. All rights reserved.
//
#include "float.h"
#import "ViewController.h"
#import "NSImage+OpenCV.h"
#import "ImageUtils.mm"
#include "Board.h"
#import "Node.h"

enum {LEFT,BOTTOM,RIGHT,TOP};


static int previndex=0;
static int savedindex=0;
#include "ImageUtils.h"



@implementation ViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
        _videoCapture = new cv::VideoCapture(0);
        if (!_videoCapture->open(CV_CAP_AVFOUNDATION))
        {
            NSLog(@"Failed to open video camera");
        }
        
    }
    return self;
}

-(void) loadView{
    [super loadView];
    [self initdata];
    
    _videoCapture = new cv::VideoCapture(0);
    if (!_videoCapture->open(CV_CAP_AVFOUNDATION))
    {
        NSLog(@"Failed to open video camera");
    }
    
    
    self.runTimer = [NSTimer
                     scheduledTimerWithTimeInterval:.1
                     target:self
                     selector:@selector(captureFrames)
                     userInfo:nil
                     repeats:YES];
    self.calibrateView->boardView = self.boardView;
    self.calibrateView->_videoCapture = _videoCapture;
    [self doManualCalibration:nil];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    return YES;
}

void initThresholdValues(int boardsize, int &diffmin , int &diffmax,float&blackthreshold, float &whitethreshold)
{
    blackthreshold = 100;
    whitethreshold=150;
    switch(boardsize){
        case 9:
            diffmax = 4000;
            diffmin = 100;
            break;
        case 13:
            diffmax =3000;
            diffmin =5;
            break;
        case  19:
            diffmax = 1200;
            diffmin = 5;
            break;
    }

}


-(void) initdata{
   
    _docalibrate = true;
  
 
    _blacksmove= true;
    self.boardView->_board.init(_boardsize);
    [self.boardView setNeedsDisplay:true];
    initThresholdValues(_boardsize,_diffmin,_diffmax,_blackthreshold,_whitethreshold);
    //[self.maxArea setIntValue:_diffmax];
    
    
}
-(void) captureFrames{
    cv::Mat image;
    Utils::grabframe(_videoCapture, image, 0);
    //drawpoly(image,_transRect);
    [self.calibrateView setImage:[NSImage imageWithCVMat: image]];
    
    cv::Mat rotboard;
    if(self.calibrateView->_boardRect.size() > 0){
        cv::Mat map =  Utils::getPerspectiveMap(image.size(),self.calibrateView->_boardRect,_orientation);
        cv::warpPerspective(image, rotboard, map, image.size());
        [self.boardView setImage:[NSImage imageWithCVMat: rotboard]];
    }
    
}



-(void) writeImage: (NSImage*)image toFile:(NSString *) filename
{
    NSArray*  representations  = [image representations];
    NSData* bitmapData = [NSBitmapImageRep
                          representationOfImageRepsInArray: representations
                          usingType: NSJPEGFileType properties:nil];
    [bitmapData writeToFile:filename atomically:YES];
}



bool pointinrect(float x, float y , cv::Rect &r)
{
    return !(x < r.x || x > r.x+r.width || y < r.y || y > r.y+r.height);
}

void findrowcol(cv::Rect &r, float row, float col, float dx, float dy,float &newrow, float &newcol)
{

        float dyy[] = {row-1,row,row+1};
        float dxx[]={col-1,col,col+1};
        newrow=row;
        newcol=col;
        bool dobreak=false;
        for(int a=0;a< 3;a++){
            for(int b=0;b<3;b++){
                if(pointinrect(dx*dxx[a],dy * dyy[b],r)){
                    newrow = dyy[b];
                    newcol = dxx[a];
                    dobreak=true;
                    break;
                }
            }
            if(dobreak)break;
        }
}

-(void) initTextView{
    [self.textViewForLog setString:@""];
}

-(void) addToTextView: (NSString*) s{
    
    [self.textViewForLog setString:
     [NSString stringWithFormat:@"%@%@",[self.textViewForLog string],s]];
    [self.textViewForLog   scrollRangeToVisible:
     NSMakeRange([[self.textViewForLog string] length], 0)];
}

-(void) appendToTextView: (NSString*) s{
    
    [self.textViewForLog setString:
      [NSString stringWithFormat:@"%@\n%@",[self.textViewForLog string],s]];
    
    [self.textViewForLog   scrollRangeToVisible:
     NSMakeRange([[self.textViewForLog string] length], 0)];
    
}

-(void) drawboard{
    for(int i=10;i<19;i++){
        for(int j=10;j<19;j++){
            [self addToTextView: [NSString stringWithFormat: @"%d, ", self.boardView->_board.boardData[i][j]]];
        }
        [self addToTextView: @"\n"];
    }
}

-(void) logGroupInfo: (std::vector< std::vector< cv::Point> > )group
                    withLiberties:(std::vector< int> )groupliberties
{
    [self appendToTextView:@"\n\n After handle dead Black groups: num elements, num liberties"];
    for(int i=0; i< group.size();i++){
        
        [self appendToTextView:
         [NSString stringWithFormat:@"%ld, %d",
          group[i].size(),groupliberties[i]]];
    }
}
-(void) logdata:(float) dx dy:(float)dy  row:(int)row col:(int)col nlibs:(int) nlibs
         center:(cv::Point) centroid
           area:(float) maxarea colorvalue:(float) colorvalue difsaved:(int) diffsaved
{
    //[self initTextView];
    [self drawboard];
    [self appendToTextView: [NSString stringWithFormat:
                             @" dx,dy: %f, %f", dx,dy]];
    [self appendToTextView: [NSString stringWithFormat:
                             @"col,row, center : %d,%d, (%d,%d)",
                             col,row, centroid.x ,centroid.y]];
    [self appendToTextView: [NSString stringWithFormat:@"max contour area:  %f" , maxarea]];
    [self appendToTextView: [NSString stringWithFormat:@"color:  %f" , colorvalue]];
    [self appendToTextView: [NSString stringWithFormat:@"diffsaved:  %d" ,diffsaved]];
    
    [self appendToTextView:[NSString stringWithFormat:@"num libs = %d", nlibs]];
    [self appendToTextView:@"\n\n Black groups: num elements, num liberties"];
    
    for(auto& group: self.boardView->_board._groupsmap._groups){
        [self appendToTextView:
         [NSString stringWithFormat:@"%s , %ld, %d",
          group.second->isblack?"black":"white",
          group.second->elements.size(),
          group.second->numLiberties]];
    }
    [self appendToTextView:@"========================================\n\n"];
}

-(void) capturemovesForDebug
{
    cv::Mat image;
    std::vector<cv::Point> rect;
    vector<cv::Point> convexHull;
    Utils::grabframe(_videoCapture, image, 1);
    cv::Mat rotboard;
    cv::Mat map =  Utils::getPerspectiveMap(image.size(),self.calibrateView->_boardRect,_orientation);
    cv::warpPerspective(image, rotboard, map, image.size());
    NSString* file = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex++];

    [self writeImage: [NSImage imageWithCVMat: rotboard]  toFile:file ];
}



-(void) capturemoves
{
    bool isblack;
    float colorvalue;
    int deadgroupindex=INT_MAX;
    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    
    Mat grayImage,curImage,curImage2,diffPrevImage,diffSavedImage,diffSavedImage2;
    cv::Mat framePrev,frameCur,frameDif,transformedImage,frame;
    
    Utils::grabframe(_videoCapture, frame, 1);
    Utils::grabframe(_videoCapture, frame, 1);
    Utils::grabframe(_videoCapture, frame, 1);
    Utils::grabframe(_videoCapture, frame, 1);
    
    cv::Mat map =  Utils::getPerspectiveMap(frame.size(),self.calibrateView->_boardRect,_orientation);
    cv::warpPerspective(frame, curImage, map, frame.size());
    
    int diffprev = Utils::diffFrames(curImage, _prevImage, diffPrevImage);
    int difsaved = Utils::diffFrames(curImage, _savedImage,diffSavedImage);
    
    
    Utils::doDilate(2, diffSavedImage, diffSavedImage);
    Utils::doDilate(2, diffSavedImage, diffSavedImage);
    //doErode(2, diffSavedImage, diffSavedImage);
    //[self.calibrateViewContinuous setImage: [NSImage imageWithCVMat: diffSavedImage]];
    
    if(diffprev >0 || difsaved > 0){
        [self appendToTextView: [NSString stringWithFormat:
                                 @" diff prev = %d, diff saved= %d", diffprev, difsaved]];
    }
    
    Utils::getContoursForMove(diffSavedImage,_map,contours,hierarchy);
    if(contours.size() > 0 && contours.size() < 3){
        cv::Rect r = cv::boundingRect(contours[0]);
        if( diffprev == 0 && difsaved > _diffmin && difsaved < _diffmax  )
        {
            
            //[self.diffView setImage: [NSImage imageWithCVMat: diffSavedImage]];
            float dx = (float)curImage.cols/(_boardsize -1);
            float dy = (float)curImage.rows/(_boardsize -1);
            float maxarea = -1;
            int maxindex = 0;
            for( int i = 0; i< contours.size(); i++ )
            {
                double area =  cv::contourArea(contours[i]);
                cv::drawContours(curImage, contours, i,CV_RGB(255,0,255));
                cv::rectangle(curImage,r.tl(), r.br(), CV_RGB(255,255,255));
                if(area > maxarea){
                    maxarea = area;
                    maxindex = i;
                }
            }
            cv::Point centroid;
            Utils::getContourCentroid(contours[maxindex],centroid);
            float row = round(centroid.y/dy) ;
            float col = round(centroid.x/dx); 
            cv::Point centerCoords(col,row);

            //cv::rectangle(boardImage, r.tl(), r.br(), CV_RGB(255,255,255));
            cv::Rect r = cv::boundingRect(contours[maxindex]);
            cv::Scalar ave = cv::mean(curImage(r));
            colorvalue = ave[0];
            StoneColor color = self.boardView->_board.getColor(colorvalue,100,200);
            isblack = colorvalue < _blackthreshold;
            bool iswhite = colorvalue > _whitethreshold;
            if(isblack || iswhite){
                deadgroupindex=self.boardView->_board.domove(color,centerCoords,self.boardView->_board.moves.end());
                [self.boardView setNeedsDisplay:true];
                self.boardView->_board._currentMoveIndex++;
          
            }else{
                if(![self takebackmove:centerCoords]){
                    return;
                }
            }
            _savedImage = curImage.clone();
            [self.calibrateView setImage: [NSImage imageWithCVMat: _savedImage]];
            if(_debug){
                [self logdata:dx
                           dy:dy
                          row:row
                          col:col
                        nlibs:0
                       center:centroid
                         area:maxarea
                   colorvalue:colorvalue
                     difsaved:difsaved];
            }

        }
    }
    
    _prevImage=curImage.clone();
    //[self.imageWell setImage: [NSImage imageWithCVMat: _prevImage]];
    //[self.boardView setImage: [NSImage imageWithCVMat: _boardImage]];
    if(deadgroupindex!=INT_MAX){
        [self killTimers];
        [self.boardView setNeedsDisplay:true];
        NSAlert* msgBox = [[NSAlert alloc] init];
        [msgBox setMessageText: @"Remove dead stones then click okay."];
        [msgBox addButtonWithTitle: @"OK"];
        [msgBox runModal];
        [self continueRecording:nil];
    }
    
}
-(void) capturemovesForEditing
{
    bool isblack;
    float colorvalue;
    int deadgroupindex=INT_MAX;
    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    
    Mat grayImage,curImage,curImage2,diffPrevImage,diffSavedImage;
    cv::Mat framePrev,frameCur,frameDif,transformedImage;
    
    NSString* filename = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex];
    NSImage * picture =  [[NSImage alloc] initWithContentsOfFile: filename];
    cv::Mat frame = [picture CVMat];
    [self.calibrateView setImage: picture];
    curImage = [picture CVGrayscaleMat];
    
    int diffprev = Utils::diffFrames(curImage, _prevImage, diffPrevImage);
    int difsaved = Utils::diffFrames(curImage, _savedImage,diffSavedImage);
    
    NSString* file = [NSString stringWithFormat:@"%@/saved/diffsaved%d.jpg",self.currentdir,_imageindex-1];
    [self writeImage: [NSImage imageWithCVMat: diffSavedImage]  toFile:file ];
    
    file = [NSString stringWithFormat:@"%@/saved/saved%d.jpg",self.currentdir,_imageindex-1];
    [self writeImage: [NSImage imageWithCVMat: _savedImage]  toFile:file ];
    
//
//    Utils::doDilate(4, diffPrevImage, diffPrevImage);
//    Utils::doDilate(4, diffPrevImage, diffPrevImage);
//    Utils::doDilate(4, diffPrevImage, diffPrevImage);
//
//    Utils::doDilate(4, diffPrevImage, diffPrevImage);

    
    //[self.calibrateViewContinuous setImage: [NSImage imageWithCVMat: diffPrevImage]];
    Utils::getContoursForMove(diffSavedImage,_map,contours,hierarchy);
    cout << "--num contours " << contours.size() << endl;
    cout
        <<  _imageindex-1 << ", "
        <<    savedindex << ", " 
        <<    diffprev << ", "
        <<    difsaved << ", "
       << "--num contours " 
        << endl;
    
    if( difsaved > _diffmin && difsaved < _diffmax  )
    {
        
        if(contours.size() ==1){
            savedindex = _imageindex-1;
            cv::Rect r = cv::boundingRect(contours[0]);
            //[self.diffView setImage: [NSImage imageWithCVMat: diffSavedImage]];
            float dx = (float)curImage.cols/(_boardsize -1);
            float dy = (float)curImage.rows/(_boardsize -1);
            if(contours[0].size ()  > 2){
                cv::Point centroid;
                Utils::getContourCentroid(contours[0],centroid);
                float row = round(centroid.y/dy) ;
                float col = round(centroid.x/dx);
                cv::Point centerCoords(col,row);
                
                //cv::rectangle(boardImage, r.tl(), r.br(), CV_RGB(255,255,255));
                r = cv::boundingRect(contours[0]);
                cv::Scalar ave = cv::mean(curImage(r));
                colorvalue = ave[0];
                StoneColor color = self.boardView->_board.getColor(colorvalue,100,200);
                isblack = colorvalue < _blackthreshold;
                bool iswhite = colorvalue > _whitethreshold;
               
               
                deadgroupindex=self.boardView->_board.domove(color,centerCoords,self.boardView->_board.moves.end());
                [self.boardView setNeedsDisplay:true];
                self.boardView->_board._currentMoveIndex++;
                
                _savedImage = curImage.clone();
            }
           

        }
    }
    
    _prevImage=curImage.clone();
    //[self.imageWell setImage: [NSImage imageWithCVMat: _prevImage]];
    //[self.boardView setImage: [NSImage imageWithCVMat: _boardImage]];
    if(deadgroupindex!=INT_MAX){
        [self killTimers];
        [self.boardView setNeedsDisplay:true];
    }
    //[self.boardView setImage: [NSImage imageWithCVMat: _boardImage]];
}

-(void) capturemovesForSnapshots
{
    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    
    Mat grayImage,curImage,curImage2,diffPrevImage,diffSavedImage,diffSavedImage2;
    cv::Mat framePrev,frameCur,frameDif,transformedImage,frame;
    
    Utils::grabframe(_videoCapture, frame, 1);
    Utils::grabframe(_videoCapture, frame, 1);
    Utils::grabframe(_videoCapture, frame, 1);
    Utils::grabframe(_videoCapture, frame, 1);
    
    cv::Mat map =  Utils::getPerspectiveMap(frame.size(),self.calibrateView->_boardRect,_orientation);
    cv::warpPerspective(frame, curImage, map, frame.size());
    
    int diffprev = Utils::diffFrames(curImage, _prevImage, diffPrevImage);
    int difsaved = Utils::diffFrames(curImage, _savedImage,diffSavedImage);
    
    
    Utils::doDilate(2, diffSavedImage, diffSavedImage);
    Utils::doDilate(2, diffSavedImage, diffSavedImage);
    //doErode(2, diffSavedImage, diffSavedImage);
    //[self.calibrateViewContinuous setImage: [NSImage imageWithCVMat: diffSavedImage]];

    Utils::getContoursForMove(diffSavedImage,_map,contours,hierarchy);
    if(contours.size() > 0 && contours.size() < 3){
        cv::Rect r = cv::boundingRect(contours[0]);
        float ecc = r.width/(float)r.height;
        if( diffprev == 0 && difsaved > _diffmin && difsaved < _diffmax  )
        {
            
            //[self.diffView setImage: [NSImage imageWithCVMat: diffSavedImage]];
            int maxindex = 0;
            float maxarea=-1;
            for( int i = 0; i< contours.size(); i++ )
            {
                double area =  cv::contourArea(contours[i]);
                //cv::drawContours(curImage, contours, i,CV_RGB(255,0,255));
                //cv::rectangle(curImage,r.tl(), r.br(), CV_RGB(255,255,255));
                if(area > maxarea){
                    maxarea = area;
                    maxindex = i;
                }
            }
            
            NSString* file = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex++];
            [self writeImage: [NSImage imageWithCVMat: curImage]  toFile:file ];
            _savedImage = curImage.clone();
            [self.calibrateView setImage: [NSImage imageWithCVMat: _savedImage]];
            self.boardView->_board._currentMoveIndex++;
        }
    }
    _prevImage=curImage.clone();
}


- (void) captureframeForLoop
{
    [self.boardView setDraw:false];
    std::vector< std::vector<cv::Point>> rects;
    std::vector<cv::Point> rect;
    vector<cv::Point> convexHull;
    Mat colorImage;
    double maxarea = -1;
    int maxindex =0;
    cv::Mat image;
    for(int i=0;i<10;i++){
        Utils::grabframe(_videoCapture, image, 1);
        Utils::processFrame1(image,rect,convexHull,_orientation);
        Utils::drawpoly(image,rect);
        [self.calibrateView setImage:[NSImage imageWithCVMat: image]];
        
        cv::Mat rotboard;
        cv::Mat map =  Utils::getPerspectiveMap(image.size(),rect,_orientation);
        cv::warpPerspective(image, rotboard, map, image.size());
        [self.boardView setImage:[NSImage imageWithCVMat: rotboard]];
        
        rects.push_back(rect);
        double area =  cv::contourArea(rect);
        if(area > maxarea){
            maxarea=area;
            maxindex = i;
        }
    }
    _prevImage=image;
    vector<cv::Point> &r  = rects[maxindex];
    self.calibrateView->_boardRect.clear();
    self.calibrateView->_boardRect.clear();
    int ptindex = Utils::findPointClosestToOrigin(r);
    for(int i=0; i< r.size();i++)
    {
        self.calibrateView->_boardRect.push_back(r[(ptindex+i+ [self.calibrateView getRotation]) % r.size()]);
    }


    self.runTimer = [NSTimer
                     scheduledTimerWithTimeInterval:.1
                     target:self
                     selector:@selector(captureFrames)
                     userInfo:nil
                     repeats:YES];
    
}

-(void) killTimers{
    [self.runTimer invalidate];
    self.runTimer= NULL;
    
    [self.runTimer2 invalidate];
    self.runTimer2 = NULL;
}
- (IBAction)stopAutoCalibrate:(id)sender {
    [self killTimers];
    _docalibrate=false;
}

- (IBAction)doManualCalibration:(id)sender {
    [self killTimers];
    if(self.calibrateView->_boardRect.size() ==0){
        std::vector<cv::Point> rect;
        vector<cv::Point> convexHull;
        cv::Mat image;
        
        Utils::grabframe(_videoCapture, image, 1);
        Utils::processFrame1(image,rect,convexHull,_orientation);
        [self.calibrateView setImage:[NSImage imageWithCVMat: image]];
        
        cv::Mat rotboard;
        cv::Mat map =  Utils::getPerspectiveMap(image.size(),rect,_orientation);
        cv::warpPerspective(image, rotboard, map, image.size());
        [self.boardView setImage:[NSImage imageWithCVMat: rotboard]];
    
        _prevImage=image;
        self.calibrateView->_boardRect.clear();
        int ptindex = Utils::findPointClosestToOrigin(rect);
        for(int i=0; i< rect.size();i++)
        {
            self.calibrateView->_boardRect.push_back(rect[(ptindex+i+[self.calibrateView getRotation]) % rect.size()]);
        }
    }else{
        //_transRect = self.calibrateView->_boardRect;
    }
    cv::Mat rotboard;
    cv::Mat map =  Utils::getPerspectiveMap(_prevImage.size(),self.calibrateView->_boardRect,_orientation);
    cv::warpPerspective(_prevImage, rotboard, map, _prevImage.size());
    [self.boardView setImage:[NSImage imageWithCVMat: rotboard]];
}

- (IBAction)startAutoCalibrate:(id)sender {
    [self killTimers];
    self.calibrateView->_boardRect.clear();
    _docalibrate=true;
    [self captureframeForLoop];

}


- (NSString*)getDirectory
{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    NSString* retstr=NULL;
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanCreateDirectories:YES];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setAllowsMultipleSelection:NO];
    if ( [openDlg runModal] == NSOKButton ) {
        NSURL* file= [openDlg URL];
        retstr = [file path];
    }
    return retstr;
}

-(void) startRecordingSnapshotsDebug: (bool) newrecording{
    
    if(newrecording){
        NSString* dir = [self getDirectory];
        if(dir!=NULL){
            self.currentdir=dir;
        }else{
            self.currentdir=NULL;
        }
    }
    if(_currentdir!=NULL){
        self.runTimer2 = [NSTimer
                          scheduledTimerWithTimeInterval:.5
                          target:self
                          selector:@selector(capturemovesForDebug)
                          userInfo:nil
                          repeats:YES];
    }
    
    
}


-(void) startRecordingSnapshots: (bool) newrecording{
  
    if(newrecording){
        NSString* dir = [self getDirectory];
        if(dir!=NULL){
            self.currentdir=dir;
        }else{
            self.currentdir=NULL;
        }
    }
    if(_currentdir!=NULL){
        cv::Mat curImage,frame;
        Utils::grabframe(_videoCapture, frame, 1);
        cv::Mat map =  Utils::getPerspectiveMap(frame.size(),self.calibrateView->_boardRect,_orientation);
        cv::warpPerspective(frame, curImage, map, frame.size());
        _savedImage = curImage.clone();
        _prevImage = curImage.clone();
        [self.calibrateView setImage: [NSImage imageWithCVMat: curImage]];
        if(newrecording){
            [self.calibrateView clearBoardRect];
            _boardView->_board.init(_boardsize);
            _undolastmove = false;
            _imageindex=0;
        }
        [self initdata];
        NSString* file = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex++];
        [self writeImage: [NSImage imageWithCVMat: curImage]  toFile:file ];
        
        self.runTimer2 = [NSTimer
                          scheduledTimerWithTimeInterval:.1
                          target:self
                          selector:@selector(capturemovesForSnapshots)
                          userInfo:nil
                          repeats:YES];
    }


}

-(void) startRecording: (bool) newrecording{
    
    if(newrecording){
        [self initdata];
        cv::Mat curImage,frame;
        Utils::grabframe(_videoCapture, frame, 1);
        cv::Mat map =  Utils::getPerspectiveMap(frame.size(),self.calibrateView->_boardRect,_orientation);
        cv::warpPerspective(frame, curImage, map, frame.size());
        _savedImage = curImage.clone();
        _prevImage = curImage.clone();
        _undolastmove = false;
        [self.calibrateView clearBoardRect];
        [self.boardView doinit:_boardsize setdraw:true blacksmove:_blacksmove];
        _imageindex=0;
        self.boardView->_board._currentMoveIndex= self.boardView->_board.moves.begin();
        [self.calibrateView setImage: [NSImage imageWithCVMat: curImage]];
    }
    self.runTimer2 = [NSTimer
                      scheduledTimerWithTimeInterval:.1
                      target:self
                      selector:@selector(capturemoves)
                      userInfo:nil
                      repeats:YES];
}

-(NSImage*)readJPEG:(NSString*)filename
{
    NSData *data = [NSData dataWithContentsOfFile: filename];
    return [[NSImage alloc] initWithData:data];
}

-(void) startEditing: (bool) newrecording{

        cv::Mat curImage;
        stringstream strm;
        _imageindex=0;
        self.boardView->_board._currentMoveIndex= self.boardView->_board.moves.begin();
        NSString* file = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex];
        
        NSImage* picture = [self readJPEG:file];
        [self.calibrateView setImage:picture ];
        
        curImage = [picture CVGrayscaleMat];
        
        _savedImage = curImage.clone();
        _prevImage = curImage.clone();
        _undolastmove = false;
    
        file = [NSString stringWithFormat:@"%@/saved/saved%d.jpg",self.currentdir,_imageindex-1];
        [self writeImage: [NSImage imageWithCVMat: _savedImage]  toFile:file ];
    
        [self initdata];
        [self.boardView doinit:_boardsize setdraw:true blacksmove:_blacksmove];
        [self.calibrateView clearBoardRect];
     
        NSArray *dirFiles = [[NSFileManager defaultManager]
                             contentsOfDirectoryAtPath:self.currentdir error:nil];
        NSArray *jpgFiles = [dirFiles
                             filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.jpg'"]];
        _numfiles = (int)[jpgFiles count];
        
        for(int i=1;i<_numfiles;i++){
            _imageindex++;
            [self capturemovesForEditing];
        }
}

- (IBAction)doRecordGame:(id)sender {
    [self killTimers];
    [self.textViewForLog setString:@""];
    _startmotion = false;
    _imageindex=0;
    [self startRecording: true];

}

- (IBAction)resetSavedView:(id)sender {
    _savedImage = _prevImage.clone();
    [self.calibrateView setImage: [NSImage imageWithCVMat:_savedImage]];
}

- (IBAction)rotateBoard:(id)sender {
    _orientation = (_orientation+1)%4;
    cv::Mat rotboard;
    cv::Mat map =  Utils::getPerspectiveMap(_prevImage.size(),self.calibrateView->_boardRect,_orientation);
    cv::warpPerspective(_prevImage, rotboard, map, _prevImage.size());
    //[self.diffView setImage:[NSImage imageWithCVMat: rotboard]];
    
}

- (std::string) makeSGFstring{
    std::stringstream s;
    s <<  "(;FF[4]GM[1]SZ[" << _boardsize << "];";
    string alpha = "abcdefghijklmnopqrstuvwxyz";
   // for(int i = 0;i < self.boardView->_board.moves.size();i++){
    for(auto &move : self.boardView->_board.moves){
        if(move->isblack){
            s << "B[";
        }else{
            s<< "W[";
        }
        s << alpha.at(move->coord.x) << alpha.at(move->coord.y) <<  "];";
    }
    s << ")";
    return s.str();
}
- (IBAction)savetoSGF:(id)sender {
    std::string  sgfstring = [self makeSGFstring];
    NSString *sgfNSstring = [[NSString alloc] initWithCString: sgfstring.c_str() encoding:NSMacOSRomanStringEncoding];
    NSSavePanel *panel = [NSSavePanel savePanel];
    NSInteger clicked = [panel runModal];
    
    if (clicked ==   NSFileHandlingPanelOKButton) {
        
        NSString * filename = [panel filename];
        [sgfNSstring writeToFile:filename atomically:YES encoding: NSUTF8StringEncoding error: NULL];
    }
    
}

- (IBAction)pauseRecording:(id)sender {
}



- (IBAction)firstMove:(id)sender {
    _imageindex=0;
    self.boardView->_board._currentMoveIndex=   self.boardView->_board.moves.begin();
    NSString* file = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex];
    NSImage* picture = [self readJPEG:file];
    [self.calibrateView setImage:picture ];
    
   // [self.boardView updateBoard:true currentMove:self.boardView->_board._currentMoveIndex];
}

- (IBAction)prevMove:(id)sender {
    _imageindex--;
    if(_imageindex <0){
        _imageindex=0;
    }
    
    if(self.boardView->_board._currentMoveIndex !=   self.boardView->_board.moves.begin()) {
        self.boardView->_board._currentMoveIndex--;
    }

    NSString* file = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex];
    NSImage* picture = [self readJPEG:file];
    [self.calibrateView setImage:picture ];
   // [self.boardView updateBoard:true currentMove:self.boardView->_board._currentMoveIndex];
}

- (IBAction)nextMove:(id)sender {
    _imageindex++;
    if(_imageindex >= _numfiles){
        _imageindex = _numfiles;
    }
    if(self.boardView->_board._currentMoveIndex != _boardView->_board.moves.end()){
        self.boardView->_board._currentMoveIndex++;
    }
    NSString* file = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex];
    NSImage* picture = [self readJPEG:file];
    [self.calibrateView setImage:picture ];
    //[self.boardView updateBoard:true currentMove:self.boardView->_board._currentMoveIndex];
}

- (IBAction)lastMove:(id)sender {
    _imageindex=_numfiles;
    self.boardView->_board._currentMoveIndex= self.boardView->_board.moves.end();
    
    NSString* file = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex];
    NSImage* picture = [self readJPEG:file];
    [self.calibrateView setImage:picture ];
    //[self.boardView updateBoard:true currentMove:self.boardView->_board._currentMoveIndex];
}

-(bool) takebackmove:(cv::Point) move{
    bool isgood=false;
    if(self.boardView->_board.moves.size() > 0){
        int n= (int)self.boardView->_board.moves.size();
        cv::Point p = self.boardView->_board.moves.back()->coord;
        if(p.x == move.x && p.y == move.y && self.boardView->_board.boardData[p.y][p.x] != 0){
            self.boardView->_board.moves.pop_back();
            self.boardView->_board.removestone(p);
            self.boardView->_board.setCurrentMove(n-1);
            [self.boardView setNeedsDisplay:YES];
            //[self.boardView setImage: [NSImage imageWithCVMat: _boardImage]];
            isgood=true;
        }
    }
    return isgood;
}

- (IBAction)undoLastMove:(id)sender {

}


- (IBAction)recordSnapshotsForDebug:(id)sender {
    [self killTimers];
    [self startRecordingSnapshotsDebug: true];
}

- (IBAction)recordSnapshots:(id)sender {
    [self killTimers];
    
    [self.textViewForLog setString:@""];
    
    [self.boardView doinit:_boardsize setdraw:false blacksmove:_blacksmove];
    _startmotion = false;
    _imageindex=0;
    [self initdata];
    [self startRecordingSnapshots: true];
}

- (IBAction)editSnapshots:(id)sender {
   
    NSString* dir = [self getDirectory];
    if(dir!=NULL){
        self.currentdir=dir;
    }else{
        self.currentdir=NULL;
    }
    if(_currentdir!=NULL){
        [self initdata];
        [self killTimers];
        [self.textViewForLog setString:@""];
        [self.boardView doinit:_boardsize setdraw:true blacksmove: _blacksmove];

        _startmotion = false;
        _imageindex=0;
        [self startEditing: true];
    }

}
- (IBAction)continueRecordingSnaphots:(id)sender {
    [self startRecordingSnapshots: false];
}

- (IBAction)continueRecording:(id)sender {
    [self startRecording: false];
}
- (IBAction)stopRecording:(id)sender {
    [self killTimers];
}

- (IBAction)changeColor:(id)sender {
    [self->_boardView setColor: _blacksmove];
}

-(IBAction) handleNavigateMenus:(id)sender
{

    NSMenuItem* item = (NSMenuItem*)sender;
    
    switch([item tag]){
        case 1:{ // first
            self.boardView->_board._currentMoveIndex=self.boardView->_board.moves.begin();
            [self.boardView updateboardstate: self.boardView->_board._currentMoveIndex];
           // [self.boardView updateBoard:true currentMove:_currentMoveIndex];
            
            _imageindex=0;
            NSString* file = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex];
            NSImage* picture = [self readJPEG:file];
            [self.calibrateView setImage:picture ];
            
            file = [NSString stringWithFormat:@"%@/saved/diffsaved%d.jpg",self.currentdir,_imageindex];
            picture = [self readJPEG:file];
            [self.debugview setImage:picture ];
            break;
        }
        case 2:{ // prev
           
            if(_imageindex >0){
                _imageindex--;
            }
            NSString* file = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex];
            NSImage* picture = [self readJPEG:file];
            
            if(self.boardView->_board._currentMoveIndex != self.boardView->_board.moves.begin()) {
                self.boardView->_board._currentMoveIndex--;
            }
            [self.boardView updateboardstate: self.boardView->_board._currentMoveIndex];
            [self.calibrateView setImage:picture ];
            
            file = [NSString stringWithFormat:@"%@/saved/diffsaved%d.jpg",self.currentdir,_imageindex];
            picture = [self readJPEG:file];
            [self.debugview setImage:picture ];
            
            break;
        }
        case 3:{ // next
           
            if(_imageindex < _numfiles-1){
                _imageindex++;
            }
            NSString* file = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex];
            NSImage* picture = [self readJPEG:file];
             [self.calibrateView setImage:picture ];
            
            file = [NSString stringWithFormat:@"%@/saved/diffsaved%d.jpg",self.currentdir,_imageindex];
            picture = [self readJPEG:file];
            [self.debugview setImage:picture ];
            
            if(self.boardView->_board._currentMoveIndex != _boardView->_board.moves.end()){
                self.boardView->_board._currentMoveIndex++;
            }
             [self.boardView updateboardstate: self.boardView->_board._currentMoveIndex];
           
           

            break;
        }
        case 4:{ // last
            _imageindex=_numfiles-1;
            NSString* file = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex];
            NSImage* picture = [self readJPEG:file];
            [self.calibrateView setImage:picture ];
            
            file = [NSString stringWithFormat:@"%@/saved/diffsaved%d.jpg",self.currentdir,_imageindex];
            picture = [self readJPEG:file];
            [self.debugview setImage:picture ];
            
            self.boardView->_board._currentMoveIndex= self.boardView->_board.moves.end();
            [self.boardView updateboardstate: self.boardView->_board._currentMoveIndex];
            //[self.boardView updateBoard:true currentMove:self.boardView->_board._currentMoveIndex];
            break;
        }
            
            
        case 5:{ // first move
            self.boardView->_board._currentMoveIndex=self.boardView->_board.moves.begin();
            [self.boardView updateboardstate:self.boardView->_board._currentMoveIndex];
            // [self.boardView updateBoard:true currentMove:_currentMoveIndex];
            break;
        }
        case 6:{ // prev move
            if(self.boardView->_board._currentMoveIndex != self.boardView->_board.moves.begin()) {
                self.boardView->_board._currentMoveIndex--;
            }
            [self.boardView updateboardstate: self.boardView->_board._currentMoveIndex];
            break;
        }
        case 7:{ // next move
            if(self.boardView->_board._currentMoveIndex != self.boardView->_board.moves.end()){
                self.boardView->_board._currentMoveIndex++;
            }
            [self.boardView updateboardstate: self.boardView->_board._currentMoveIndex];

            break;
        }
        case 8:{ // last
            self.boardView->_board._currentMoveIndex= self.boardView->_board.moves.end();
           // [self.boardView updateBoard:true currentMove:self.boardView->_board._currentMoveIndex];
            break;
        }
            
            
        case 9:{ // first image
            _imageindex=0;
            NSString* file = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex];
            NSImage* picture = [self readJPEG:file];
            [self.calibrateView setImage:picture ];
            
            file = [NSString stringWithFormat:@"%@/saved/diffsaved%d.jpg",self.currentdir,_imageindex];
            picture = [self readJPEG:file];
            [self.debugview setImage:picture ];
            
            file = [NSString stringWithFormat:@"%@/saved/saved%d.jpg",self.currentdir,_imageindex];
            picture = [self readJPEG:file];
            [self.debugview2 setImage:picture ];
            
            break;
        }
        case 10:{ // prev image
            _imageindex--;
            if(_imageindex <0){
                _imageindex=0;
            }
            NSString* file = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex];
            NSImage* picture = [self readJPEG:file];
            [self.calibrateView setImage:picture ];
            
            file = [NSString stringWithFormat:@"%@/saved/diffsaved%d.jpg",self.currentdir,_imageindex];
            picture = [self readJPEG:file];
            [self.debugview setImage:picture ];
            
            file = [NSString stringWithFormat:@"%@/saved/saved%d.jpg",self.currentdir,_imageindex];
            picture = [self readJPEG:file];
            [self.debugview2 setImage:picture ];
            
            
            break;
        }
        case 11:{ // next image
            _imageindex++;
            if(_imageindex >= _numfiles){
                _imageindex = _numfiles-1;
            }
            NSString* file = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex];
            NSImage* picture = [self readJPEG:file];
            [self.calibrateView setImage:picture ];
            
            file = [NSString stringWithFormat:@"%@/saved/diffsaved%d.jpg",self.currentdir,_imageindex];
            picture = [self readJPEG:file];
            [self.debugview setImage:picture ];
            
            file = [NSString stringWithFormat:@"%@/saved/saved%d.jpg",self.currentdir,_imageindex];
            picture = [self readJPEG:file];
            [self.debugview2 setImage:picture ];
            
            break;
        }
        case 12:{ // last image
            _imageindex=_numfiles-1;
            NSString* file = [NSString stringWithFormat:@"%@/image%d.jpg",self.currentdir,_imageindex];
            NSImage* picture = [self readJPEG:file];
            [self.calibrateView setImage:picture ];
            
            file = [NSString stringWithFormat:@"%@/saved/diffsaved%d.jpg",self.currentdir,_imageindex];
            picture = [self readJPEG:file];
            [self.debugview setImage:picture ];
            file = [NSString stringWithFormat:@"%@/saved/saved%d.jpg",self.currentdir,_imageindex];
            picture = [self readJPEG:file];
            [self.debugview2 setImage:picture ];
            break;
        }
    }
    [self.boardView setNeedsDisplay:true];
}

-(IBAction)handleDebugMenu:(id)sender
{
    NSMenuItem* item = (NSMenuItem*)sender ;
    [item setState: [item state]==NSOnState? NSOffState: NSOnState];
    _debug = [item state]==NSOnState;
}

@end
