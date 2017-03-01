//
//  ParallelControllableTextureSynthesis.cpp
//  ParallelControllableTextureSynthesis
//
//  Created by Rosani Lin on 13/4/12.
//  Copyright (c) 2013年 Rosani Lin. All rights reserved.
//

#include "ParallelControllableTextureSynthesis.h"
#include <sstream>

using namespace std;
using namespace cv;

ParallelControllableTextureSynthesis::ParallelControllableTextureSynthesis () {
    
    srand(1234);
    
}

ParallelControllableTextureSynthesis::~ParallelControllableTextureSynthesis() {
    
}


Mat ParallelControllableTextureSynthesis::synthesis(const string &texture_file, double magnify_ratio) {
    
    sample_texture = imread(texture_file.c_str());
    sample_texture_path = texture_file;
    
    //similarSetConstruction();

    initialization(magnify_ratio);

    for (int level = 1; level <= PYRAMID_LEVEL; level ++) {

        upsample(level);
        //jitter(level);
        coordinateMapping(level);

        if(level>2) {
            for(int kk=0; kk<3; kk++) {
                //correction(level);
            }
        }
//        coordinateMapping(level);
        std::stringstream ss;
        ss << "" << level << "_LEVEL";
        //if (level>2) {
        showMat(syn_textures[level], ss.str());
        //}
    }
//    showMat(synthesized_texture);

    return Mat();//synthesized_texture;
}



void ParallelControllableTextureSynthesis::initialization(double magnify_ratio) {
    
    //just creates array of black textures with appropriate sizes 512,256,128...
    cv::buildPyramid(Mat(sample_texture.rows*magnify_ratio,
                         sample_texture.cols*magnify_ratio, CV_8UC3),
                     syn_textures, PYRAMID_LEVEL);
    
    std::reverse(syn_textures.begin(), syn_textures.end());
    
    //preparing for eache level appropriate arrays with coordinates (S).
    for_each(syn_textures.begin(), syn_textures.end(), [&](Mat texture){
        
        //dynamicArray2D<Point> local_coor (texture.rows, texture.cols);
        //syn_coor.push_back(local_coor);
        syn_coords.emplace_back(texture.rows, texture.cols); // faster
        //showMat(texture);
        
    });
    
    
    // Regular initialization

//TODO FUCK1 not implemented forEach_withCorr()
//    syn_coor[0].forEach_withCorr([=](Point& coor, int i, int j) {
//        coor = Point(j, i);
//    });

//TODO: FUCK1-1 check equality of code '::forEach_withCorr()' and code below...
    int zero_level = 0;
    for (int i = 0; i < syn_coords[zero_level].rows; i++) {
        for (int j = 0; j < syn_coords[zero_level].cols; j++) {
            syn_coords[zero_level].at(i,j) = cv::Point(j, i);
        }
    }
    
    for (int i = 0; i < syn_coords.size(); i ++) {
        cout<<syn_coords[i].rows<<", "<<syn_textures[i].rows<< endl;
    }
    
}


void ParallelControllableTextureSynthesis::upsample(int level) {
    static const array<Point, 4> shifts = {Point(0, 0), Point(1, 0),
                                            Point(0, 1), Point(1, 1)};
    auto &prev_lvl = syn_coords[level - 1];
    auto &cur_lvl = syn_coords[level];

    //TODO: FUCK2-1 - previous version of code
//    for (int i = 0; i < syn_coor[level - 1].rows; i ++) {
//        for (int j = 0; j < syn_coor[level - 1].cols; j ++) {
//              syn_coor[level].at(i*2    , j*2    ) = syn_coor[level - 1].at(i, j)*2;
//              syn_coor[level].at(i*2 + 1, j*2    ) = syn_coor[level - 1].at(i, j)*2 + Point(1, 0);
//              syn_coor[level].at(i*2    , j*2 + 1) = syn_coor[level - 1].at(i, j)*2 + Point(0, 1);
//              syn_coor[level].at(i*2 + 1, j*2 + 1) = syn_coor[level - 1].at(i, j)*2 + Point(1, 1);
//        }
//    }

    //TODO: FUCK2-2 - previous version of code modified
//    for (int i = 0; i < syn_coords[level].rows; i ++) {
//        for (int j = 0; j < syn_coords[level].cols; j ++) {
//            cv::Point texture1 = cv::Point(syn_coords[level - 1].at(i/2, j/2));
//            cv::Point texture2 = texture1*2 + cv::Point(j%2, i%2);
//            coordinateTrim(texture2);
//            syn_coords[level].at(i, j) = texture2;
//        }
//    }

    //TODO: FUCK2-2 - modified first version
    for (int i = 0; i < prev_lvl.rows; i ++) {
        for (int j = 0; j < prev_lvl.cols; j ++) {
          Point pt(j, i);
          for (const auto &shift: shifts){
            cur_lvl.at(2*pt + shift) = prev_lvl.at(pt)*2 + shift;
            coordinateTrim(cur_lvl.at(2*pt + shift));
          }
        }
    }

    /*for (int i = 0; i < cur_lvl.rows; i++){
      for (int j = 0; j < cur_lvl.cols; j++){
        cout << cur_lvl.at(i, j) << ' ';
      }
      cout << endl;
    }*/


    //TODO: FUCK2 unimplemented forEach_withCorr()
//    syn_coor[level].forEach_withCorr([&](Point& texture, int i, int j) {
//        texture = syn_coor[level - 1].at(i/2, j/2)*2 + Point(j%2, i%2);
//        coordinateTrim(texture);
//    });

    
    
    
    
}


void ParallelControllableTextureSynthesis::jitter (int level) {
    
//TODO: FUCK3 unimplemented forEach()
//    syn_coor[level].forEach([=](Point& coor) {
//        coor = coor + Point(ceil((rand()%3 - 1) + 0.5), ceil((rand()%3 - 1) + 0.5))*JITTER_AMPLITUDE;
//        coordinateTrim(coor);
//    });

//TODO: FUCK3-1 check equality of code '::forEach()' and code below...
    for (int i = 0; i < syn_coords[level].rows; i++) {
        for (int j = 0; j < syn_coords[level].cols; j++) {
            cv::Point tmpP = this->syn_coords[level].at(i,j);
            //tmpP += cv::Point(ceil((rand()%3 - 1) + 0.5), ceil((rand()%3 - 1) + 0.5))*JITTER_AMPLITUDE;
            tmpP += cv::Point(rand()%3, rand()%3)*JITTER_AMPLITUDE;
            coordinateTrim(tmpP);
            this->syn_coords[level].at(i,j) = tmpP;
        }
    }
}


void ParallelControllableTextureSynthesis::correction(int level) {
    double local_shrink_ratio = (double)syn_textures[level].rows/sample_texture.rows;
    //TODO: check Uncommented CODE
    Mat re_texture = sample_texture.clone();
    if ( syn_coords[level].rows < sample_texture.rows ) {
        resize(sample_texture, re_texture, syn_textures[level].size());
    }
    dynamicArray2D<Point> temp_coor(syn_coords[level].rows, syn_coords[level].cols);
    for (int i = 0; i < syn_textures[level].rows; i ++) {
        for (int j = 0; j < syn_textures[level].cols; j ++) {
            double min_cost = INFINITY;
            Point min_loc(0);
            for (int m = -COHERENCE_SEARCH_W; m <= COHERENCE_SEARCH_W; m ++) {
                for (int n = -COHERENCE_SEARCH_W; n <= COHERENCE_SEARCH_W; n ++) {
                    double local_cost = 0;
                    int valid_count = 0;
                    for (int p = -PATCH_WIDTH; p <= PATCH_WIDTH; p ++) {
                        for (int q = -PATCH_WIDTH; q <= PATCH_WIDTH; q ++) {

                            if ( (syn_coords[level].at(i, j).y + m + p) >= 0 && (syn_coords[level].at(i, j).y + m + p) < syn_textures[level].rows
                                && (syn_coords[level].at(i, j).x + n + q) >= 0 && (syn_coords[level].at(i, j).x + n + q) < syn_textures[level].cols
                                && (i + p) >= 0 && (i + p) < syn_textures[level].rows
                                && (j + q) >= 0 && (j + q) < syn_textures[level].cols ) {

                                local_cost += Vec3bDiff(syn_textures[level].at<Vec3b>(i + p, j + q), re_texture.at<Vec3b>(syn_coords[level].at(i, j).y + m + p, syn_coords[level].at(i, j).x + n + q));
                                valid_count ++;
                            }
                        }
                    }
                    local_cost /= valid_count;
                    if ( local_cost < min_cost ) {
                        min_cost = local_cost;
                        min_loc = Point(syn_coords[level].at(i, j).x + n, syn_coords[level].at(i, j).y + m);
                    }
                }
            }
            temp_coor.at(i, j) = min_loc;
        }
    }
    syn_coords[level] = temp_coor;
}


void ParallelControllableTextureSynthesis::coordinateMapping(int level) {
    
    
    Mat re_texture = sample_texture.clone();
    if ( syn_coords[level].rows < sample_texture.rows ) {
        cv::resize(sample_texture, re_texture, syn_textures[level].size());
    }
    cv::imshow("resize", re_texture);

    /*for (int l = 0; l <= PYRAMID_LEVEL; l++){
      auto &pyr_lev = syn_coor[l];
      for (int i = 0; i < pyr_lev.rows; i++)
        for (int j = 0; j < pyr_lev.cols; j++){
          Point &pt = pyr_lev.at(i, j);
          if (pt.x < 0 || pt.x >= re_texture.cols ||
              pt.y < 0 || pt.y >= re_texture.rows){
            std::cerr << "ERRORO" << std::endl;
          }
        }
    }*/
    
    for (int i = 0; i < syn_textures[level].rows; i ++) {
        for (int j = 0; j < syn_textures[level].cols; j ++) {
            
            Point &pt = syn_coords[level].at(i, j);

            if (pt.x < 0 || pt.x >= re_texture.rows ||
                pt.y < 0 || pt.y >= re_texture.cols){
              syn_textures[level].at<Vec3b>(i, j) = Vec3b(255, 0, 0);
              cerr << "Error: " << pt << endl;
              continue;
            }
            syn_textures[level].at<Vec3b>(i, j) = re_texture.at<Vec3b>(pt);
            
        }
    }
    
}


void ParallelControllableTextureSynthesis::coordinateTrim(Point &coor) {
    // I think there is should be module by current size of level texture
    coor = Point(coor.x % sample_texture.cols, coor.y % sample_texture.rows);
    /*if (coor.x < 0){
      coor.x = sample_texture.rows + coor.x;
    }
    if (coor.y < 0){
      coor.y = sample_texture.cols + coor.y;
    }*/
}



/*void ParallelControllableTextureSynthesis::similarSetConstruction() {
    
    sample_similar_set = dynamicArray2D<vector<Point> > (sample_texture.rows, sample_texture.cols);
    
    string file_path = sample_texture_path.substr(0, sample_texture_path.find_last_of("/") + 1);
    string file_name = sample_texture_path.substr(sample_texture_path.rfind("/") + 1).substr(0, sample_texture_path.find_last_of(".") - file_path.size());

    
    ifstream read_file(file_path.append(file_name).append(".txt").c_str());
    


    if ( read_file.fail() ) {
        
        for (int i = 0; i < sample_texture.rows; i ++) {
            for (int j = 0; j < sample_texture.cols; j ++) {
                std::cout << i << "/" << sample_texture.rows << ", " << j << "/" << sample_texture.cols << std::endl;
                multimap<double, Point> local_similar_set;
                
                for (int p = 0; p < sample_texture.rows; p ++) {
                    for (int q = 0 ; q < sample_texture.cols; q ++) {
                        
                        double local_cost = 0.0;
                        int valid_count = 0;
                        
                        for (int m = -PATCH_WIDTH; m <= PATCH_WIDTH; m ++) {
                            for (int n = -PATCH_WIDTH; n <= PATCH_WIDTH; n ++) {
                                
                                if ( (i + m) >= 0 && (i + m) < sample_texture.rows
                                    && (j + n) >= 0 && (j + n) < sample_texture.cols
                                    && (p + m) >= 0 && (p + m) < sample_texture.rows
                                    && (q + n) >= 0 && (q + n) < sample_texture.cols ) {
                                    
                                    local_cost += Vec3bDiff(sample_texture.at<Vec3b>(i + m, j + n), sample_texture.at<Vec3b>(p + m, q + n));
                                    
                                    valid_count ++;
                                    
                                }
                                
                            }
                        }
                        
                        local_similar_set.insert(pair<double, Point> (local_cost/valid_count, Point(q, p)));
                        
                    }
                }
                
                
                int temp_counter = 0;
                
                for_each(local_similar_set.begin(), local_similar_set.end(), [&](pair<double, Point> candidate) {
                    
                    temp_counter ++;
                    if ( temp_counter <= SIMILAR_NEIGHBOR_N ) {
                        sample_similar_set.at(i, j).push_back(candidate.second);
                    }
                    
                });
                
                
                local_similar_set.clear();
            }
        }

        
        ofstream write_file(file_path.c_str());
        
        write_file << SIMILAR_NEIGHBOR_N;
        
        for (int i = 0; i < sample_similar_set.rows; i ++) {
            for (int j = 0; j < sample_similar_set.cols; j ++) {
                
                write_file << endl;
                
                write_file << i <<" "<< j <<" ";
                
                for (int p = 0; p < sample_similar_set.at(i, j).size(); p ++) {
                    write_file << sample_similar_set.at(i, j)[p].x<<" "<< sample_similar_set.at(i, j)[p].y<<" ";
                }
                
                
            }
        }
        
    }
    
    else {
        
        if (!read_file.eof()) {
            
            int similar_num = 0;
            read_file >> similar_num;
            
            int i = 0, j = 0, nx = 0, ny = 0;
            
            while ( read_file >> i && read_file >> j ) {
                
                for (int k = 0; k < similar_num; k ++) {
                    
                    read_file >> nx; read_file >> ny;
                    
                    sample_similar_set.at(i, j).push_back(Point(nx, ny));
                    
                }
                
            }
            std::cout << "---------" << std::endl;
        }
        
        
        
        
    }
    
    
    
//    for (int i = 0; i < sample_similar_set.rows; i ++) {
//        for (int j = 0; j < sample_similar_set.cols; j ++) {
//            
//            for (int p = 0; p < sample_similar_set.at(i, j).size(); p ++) {
//                cout<<sample_similar_set.at(i, j)[p]<<", ";
//            }
//            
//            cout<<endl;
//            
//        }
//    }
    
    

    
    
}

*/










