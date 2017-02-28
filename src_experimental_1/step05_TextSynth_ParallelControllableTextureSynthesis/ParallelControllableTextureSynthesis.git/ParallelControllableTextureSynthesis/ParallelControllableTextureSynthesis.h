//
//  ParallelControllableTextureSynthesis.h
//  ParallelControllableTextureSynthesis
//
//  Created by Rosani Lin on 13/4/12.
//  Copyright (c) 2013年 Rosani Lin. All rights reserved.
//

#ifndef __ParallelControllableTextureSynthesis__ParallelControllableTextureSynthesis__
#define __ParallelControllableTextureSynthesis__ParallelControllableTextureSynthesis__

#include <iostream>
#include <fstream>
#include <map>
//#include "RosaniTools.h"
#include "ext_utils.h"

#include <opencv2/imgproc.hpp>
#include <opencv2/highgui.hpp>

class ParallelControllableTextureSynthesis {
    
public:
    
    // Default constructor
    ParallelControllableTextureSynthesis();
    
    // Default destructor
    ~ParallelControllableTextureSynthesis();
    
    // Begin synthesizing
    cv::Mat synthesis (const std::string& texture_file, double magnify_ratio);
    

    
    
private:
    
    // Initialize arrays including synthesized pyramid and coordinate pyramid
    void initialization (double magnify_ratio);
    
    // Upsampling
    void upsample (int level);
    
    // Basic jitter
    void jitter (int level);
    
    // Basic correction
    void correction (int level);
    
    // Maps coordinate to synthesized texture
    void coordinateMapping (int level);
    
    // Cut off the coordinates outside of texture boundary
    void coordinateTrim (cv::Point& coor);
    
    // Construct similar set of given input sample texture
    void similarSetConstruction ();
    
    cv::Mat sample_texture;
    cv::Mat synthesized_texture;
    std::vector<dynamicArray2D<cv::Point> > syn_coor;
    std::vector<cv::Mat> syn_texture;
    dynamicArray2D<std::vector<cv::Point> > sample_similar_set;
    
    std::string sample_texture_path;
    
    static const int    PYRAMID_LEVEL       =   6;
    static const int    OUTSPACE_FACTOR     =   1;
    static const int    JITTER_AMPLITUDE    =   1;
    static const int    PATCH_WIDTH         =   2;
    static const int    COHERENCE_SEARCH_W  =   5;
    static const int    SIMILAR_NEIGHBOR_N  =  10;
    
    
    
    
};



#endif /* defined(__ParallelControllableTextureSynthesis__ParallelControllableTextureSynthesis__) */
