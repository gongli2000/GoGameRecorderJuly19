//
//  Utils.cpp
//  GoGameRecorder
//
//  Created by Larry on 7/8/13.
//  Copyright (c) 2013 Larry. All rights reserved.
//

#include "Utils.h"

void Utils::doErode( int erosion_size, Mat &src, Mat &dst )
{
    int types[] = {MORPH_RECT,MORPH_CROSS,MORPH_ELLIPSE};
    
    int erosion_elem =MORPH_RECT;
    int erosion_type = types[erosion_elem];
    
    Mat element = getStructuringElement( erosion_type,
                                        cv::Size( 2*erosion_size + 1, 2*erosion_size+1 ),
                                        cv::Point( erosion_size, erosion_size ) );
    erode( src, dst, element );
}


int Utils::diffFrames(Mat &image1, Mat &image2, cv::Mat &diff)
{
    absdiff(image1, image2, diff);
    threshold(diff,diff,30,256,CV_THRESH_BINARY);
    cv::dilate(diff, diff, Mat(), cv::Point(-1,-1), 3);

    cv::erode(diff, diff, Mat(), cv::Point(-1,-1), 7);
    //cv::erode(diff, diff, Mat(), cv::Point(-1,-1), 5);
    return countNonZero(diff);
}


void Utils::doDilate( int dilation_size , Mat &src, Mat &dst )
{
    int types[] = {MORPH_RECT,MORPH_CROSS,MORPH_ELLIPSE};
    int erosion_elem=MORPH_RECT;
    int dilation_type = types[erosion_elem];
    
    Mat element = getStructuringElement( dilation_type,
                                        cv::Size( 2*dilation_size + 1, 2*dilation_size+1 ),
                                        cv::Point( dilation_size, dilation_size ) );
    dilate( src, dst, element );
}

void Utils::grabframe(VideoCapture *cap, Mat &theframe, int scale)
{
    Mat frame,grayframe;
    (*cap) >> frame;
    
    //grabframe(cap, frame);
    cvtColor(frame, grayframe, CV_BGR2GRAY);
    transpose(grayframe,theframe);
    flip(theframe,theframe,0);
    //cv::pyrDown(grayframe,theframe);
    
    float sigma = 1.0;
    //GaussianBlur(theframe, theframe, Size(0,0), sigma, sigma);
}


void Utils::getContourCentroid(std::vector<cv::Point> contour, cv::Point &centroid)
{
    CvMoments moments = cv::moments(contour);
    double M00, M01, M10;
    M00 = cvGetSpatialMoment(&moments,0,0);
    M10 = cvGetSpatialMoment(&moments,1,0);
    M01 = cvGetSpatialMoment(&moments,0,1);
    centroid.x = M10/M00;
    centroid.y = M01/M00;
    
}
void Utils::getContoursForMove(cv::Mat &image,
                        cv::Mat pmap,
                        std::vector<std::vector<cv::Point> > &contours,
                        std::vector<cv::Vec4i> &hierarchy)
{
    
    cv::Mat diff2clone = image.clone();
    findContours(diff2clone, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );
}
int Utils::findPointClosestToOrigin(std::vector<cv::Point> rect)
{
    
    int i =0,retindex=0;
    float maxdist = -1;
    for(auto &p : rect){
        float dist = p.x*p.x+p.y+p.y;
        if(dist > maxdist){
            maxdist = dist;
            retindex=i;
        }
        i++;
    }
    return retindex;
}

int Utils::findNumLiberties(vector< vector<int> > &boardData, vector< cv::Point> &group)
{
    std::set<int> pts;
    for(int i=0;i< group.size();i++){
        cv::Point &p = group[i];
        int x[] = {p.x-1,p.x+1,p.x,p.x};
        int y[] = {p.y,p.y,p.y-1,p.y+1};
        for(int a =0;a<4;a++){
            if(x[a]<0 || x[a] >= boardData.size() || y[a]<0 || y[a] >= boardData.size())continue;
            if(boardData[y[a]][x[a]] == 0){
                int val=y[a]*100+x[a];
                pts.insert(val);
            }
        }
    }
    return (int)pts.size();
}

void Utils::findMaxAreaContour(std::vector<std::vector<cv::Point> > &contours, int &index, double &maxarea)
{
    maxarea = 0;
    index =0;
    
    for(int i=0;i< contours.size();i++){
        double area = cv::contourArea(contours[i]);
        if(area > 100.0){
            
            if(area > maxarea ){
                index=i;
                maxarea = area;
            }
        }
    }
    
}

void Utils::findConvexHull(cv::Mat frame,std::vector<cv::Point> &maxAreaContour,std::vector<cv::Point> &convexHull)
{
    std::vector<cv::Point> hull;
    cv::convexHull( maxAreaContour, hull, false );
    
    double peri = cv::arcLength(hull,true);
    cv:: approxPolyDP( hull, convexHull, 0.01*peri, true );
    
    //    std::vector<std::vector<cv::Point> >  contours_poly;
    //    contours_poly.push_back(convexHull);
    //    cv::fillPoly(frame, contours_poly, CV_RGB(255,0,0));
}

cv::Mat Utils::getPerspectiveMap(cv::Size s, std::vector<cv::Point> &srcVec, int orientation)
{
    //    int  botIndices[]= {0,1,2,3} ;
    //    int rightIndices[] = {1,2,3,0};
    //    int leftIndices[] = {2,3,0,1};
    //    int topIndices[] = {3,0,1,2};
    //    int* indicesArray[] = {rightIndices,botIndices,leftIndices,topIndices};
    //    int *indices = indicesArray[orientation];
    
    
    cv::Point2f dst[]={
        cv::Point2f(0,0),
        cv::Point(s.width,0),
        cv::Point(s.width,s.height),
        cv::Point(0,s.height)};
    //cv::Point2f src[]={srcVec[indices[0]],srcVec[indices[1]],srcVec[indices[2]],srcVec[indices[3]]};
    cv::Point2f src[]={srcVec[0],srcVec[1],srcVec[2],srcVec[3]};
    
    return cv::getPerspectiveTransform(src,dst);
}


void Utils::drawpoly(Mat& inputImage, std::vector<cv::Point> transRect){
    for(int i=0;i<transRect.size();i++){
        cv::Point p = transRect[i];
        cv::line(inputImage,p, transRect[(i+1)%transRect.size()],CV_RGB(255,0,0),2);
    }
    
}
void Utils::processFrame1( Mat &inputImage, std::vector<cv::Point> &transRect,std::vector<cv::Point> &convexHull,int orientation)
{
    Mat  outerBox,test;
    Mat grayFrame = inputImage.clone();
    
    cv::adaptiveThreshold(grayFrame,grayFrame,255,1,1,11,2);
    
    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    //cv::Mat x = grayFrame.clone();
    findContours(grayFrame, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );
    
    int index;
    double maxarea;
    convexHull.clear();
    findMaxAreaContour(contours,index,maxarea);
    findConvexHull(grayFrame,contours[index],convexHull);
    
    transRect.clear();
    for(int i=0;i<4;i++){
        //cv::Point p = convexHull[indices[i]];
        //cv::line(inputImage,p, convexHull[indices[(i+1)%4]],CV_RGB(255,0,0),2);
        transRect.push_back(convexHull[i]);
    }
}




