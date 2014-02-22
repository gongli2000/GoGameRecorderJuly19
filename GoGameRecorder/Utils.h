//
//  Utils.h
//  GoGameRecorder
//
//  Created by Larry on 7/4/13.
//  Copyright (c) 2013 Larry. All rights reserved.
//

#ifndef __GoGameRecorder__Utils__
#define __GoGameRecorder__Utils__

#include <iostream>
#include <opencv2/opencv.hpp>
using namespace cv;
using namespace std;
#define matdatatype CV_8UC1
#define matdatatypecolor CV_8UC4


class Utils{
public:
    static int findPointClosestToOrigin(std::vector<cv::Point> rect);
    static int findNumLiberties(vector< vector<int> > &boardData, vector< cv::Point> &group);
    static void getContoursForMove(cv::Mat &image,
                                          cv::Mat pmap,
                                          std::vector<std::vector<cv::Point> > &contours,
                                          std::vector<cv::Vec4i> &hierarchy);
    static void getContourCentroid(std::vector<cv::Point> contour, cv::Point &centroid);
    static void grabframe(VideoCapture *cap, Mat &theframe, int scale);
    static void doDilate( int dilation_size , Mat &src, Mat &dst );
    static int diffFrames(Mat &image1, Mat &image2, cv::Mat &diff);
    static void doErode( int erosion_size, Mat &src, Mat &dst );
    static void findMaxAreaContour(std::vector<std::vector<cv::Point> > &contours, int &index, double &maxarea);
    static void findConvexHull(cv::Mat frame,std::vector<cv::Point> &maxAreaContour,std::vector<cv::Point> &convexHull);
    static cv::Mat getPerspectiveMap(cv::Size s, std::vector<cv::Point> &srcVec, int orientation);
    static void drawpoly(Mat& inputImage, std::vector<cv::Point> transRect);
    static void processFrame1( Mat &inputImage, std::vector<cv::Point> &transRect,std::vector<cv::Point> &convexHull,int orientation);
};



#endif /* defined(__GoGameRecorder__Utils__) */
