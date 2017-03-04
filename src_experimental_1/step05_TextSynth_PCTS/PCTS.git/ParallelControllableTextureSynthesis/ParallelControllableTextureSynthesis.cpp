//
//  ParallelControllableTextureSynthesis.cpp
//  ParallelControllableTextureSynthesis
//
//  Created by Rosani Lin on 13/4/12.
//  Copyright (c) 2013年 Rosani Lin. All rights reserved.
//

#include "ParallelControllableTextureSynthesis.h"

#include <array>
#include <sstream>
#include <chrono>
#include <omp.h>

using namespace std;
using namespace cv;

using chrono::milliseconds;
using chrono::duration_cast;
using chrono::high_resolution_clock;

const double ParallelControllableTextureSynthesis::RANDOM_STRENGTH = 0.1;
int ParallelControllableTextureSynthesis::PATCH_WIDTH = 2;

ParallelControllableTextureSynthesis::ParallelControllableTextureSynthesis () {

    //mersene_random.seed(123);
    
}

Mat ParallelControllableTextureSynthesis::synthesis(const string &texture_file, double magnify_ratio) {
    
    sample_texture = imread(texture_file.c_str());
    sample_texture_path = texture_file;
    
    //similarSetConstruction();

    initialization(magnify_ratio);

    for (int level = 1; level <= PYRAMID_LEVEL; level ++) {
        cout << "Level: " << level << endl;
        cout << "Size: " << syn_textures[level].size() << endl;
        {
          auto start = high_resolution_clock::now();
          upsample(level);
          auto finish = high_resolution_clock::now();
          cout << "Upsample: "
               << duration_cast<milliseconds>(finish - start).count()
               << "ms" << endl;
        }
        {
          auto start = high_resolution_clock::now();
          jitter(level);
          auto finish = high_resolution_clock::now();
          cout << "Jitter: "
               << duration_cast<milliseconds>(finish - start).count()
               << "ms" << endl;
        }
        {
          auto start = high_resolution_clock::now();
          coordinateMapping(level);
          auto finish = high_resolution_clock::now();
          cout << "Coordinate mapping: "
               << duration_cast<milliseconds>(finish - start).count()
               << "ms" << endl;
        }

        std::stringstream ss;
        ss << "" << level << "_LEVEL";
        if(level>2) {
            showMat(coordsToMat(syn_coords[level]), ss.str() + " coords", false);
            showMat(syn_textures[level], ss.str(), false);
            waitKey(50);
            PATCH_WIDTH = 20;
            for(int kk=0; kk<4; kk++) {
                auto start = high_resolution_clock::now();
                correction(level);
                coordinateMapping(level);
                auto finish = high_resolution_clock::now();

                cout << "Correction: "
                     << duration_cast<milliseconds>(finish - start).count()
                     << "ms" << endl;

                showMat(coordsToMat(syn_coords[level]), ss.str() + " coords", false);
                showMat(syn_textures[level], ss.str(), false);
                waitKey(50);
                PATCH_WIDTH = max(PATCH_WIDTH - 5, 2);
            }
        }
        showMat(coordsToMat(syn_coords[level]), ss.str() + " coords", false);
        showMat(syn_textures[level], ss.str());
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
        syn_coords.emplace_back(texture.rows, texture.cols); // faster
    });
    
    
    // zero level initialization
    int zero_level = 0;
    for (int i = 0; i < syn_coords[zero_level].rows; i++) {
        for (int j = 0; j < syn_coords[zero_level].cols; j++) {
            syn_coords[zero_level].at(i,j) = cv::Point(j, i);
        }
    }
    
    //out sizes
    for (int i = 0; i < syn_coords.size(); i ++) {
        cout<<syn_coords[i].rows<<", "<<syn_textures[i].rows<< endl;
    }
    
}


void ParallelControllableTextureSynthesis::upsample(int level) {
    static const array<Point, 4> shifts = {Point(0, 0), Point(1, 0),
                                            Point(0, 1), Point(1, 1)};
    auto &prev_lvl = syn_coords[level - 1];
    auto &cur_lvl = syn_coords[level];

    for (int i = 0; i < prev_lvl.rows; i ++) {
        for (int j = 0; j < prev_lvl.cols; j ++) {
          Point pt(j, i);
          for (const auto &shift: shifts){
            cur_lvl.at(2*pt + shift) = prev_lvl.at(pt)*2 + shift;
            coordinateTrim(cur_lvl.at(2*pt + shift));
          }
        }
    }
    
}


void ParallelControllableTextureSynthesis::jitter (int level) {
    uniform_real_distribution<double> uniform(-1, 1);
    auto &rnd = mersene_random;

    auto &cur_lvl_coords = syn_coords[level];
    for (int i = 0; i < cur_lvl_coords.rows; i++) {
        for (int j = 0; j < cur_lvl_coords.cols; j++) {
            auto &tex_pt = cur_lvl_coords.at(i, j);
            tex_pt += cv::Point(floor(uniform(rnd)*RANDOM_STRENGTH + 0.5),
                                floor(uniform(rnd)*RANDOM_STRENGTH + 0.5))*JITTER_AMPLITUDE;

            //checking bounds, they should not exceed cur level size
            tex_pt.x = max(tex_pt.x, 0);
            tex_pt.x = min(tex_pt.x, cur_lvl_coords.cols - 1);
            tex_pt.y = max(tex_pt.y, 0);
            tex_pt.y = min(tex_pt.y, cur_lvl_coords.rows - 1);

            //trim to sample, when cur level size > sample size
            coordinateTrim(tex_pt);
        }
    }
}


void ParallelControllableTextureSynthesis::correction(int level) {
    auto &cur_lvl_tex = syn_textures[level];
    auto &cur_lvl_coords = syn_coords[level];

    Mat re_texture = sample_texture.clone();
    if ( cur_lvl_tex.rows < sample_texture.rows ) {
        resize(sample_texture, re_texture, cur_lvl_tex.size());
    }

    dynamicArray2D<Point> temp_coor = cur_lvl_coords;

    const int BORDER = PATCH_WIDTH;

    #pragma omp parallel
    #pragma omp for
    for (int i = BORDER; i < cur_lvl_tex.rows - BORDER; i ++) {
        for (int j = BORDER; j < cur_lvl_tex.cols - BORDER; j ++) {
            //taking patch
            Point patch_tl( max(j - PATCH_WIDTH, 0),
                            max(i - PATCH_WIDTH, 0) );
            Point patch_br( min(j + PATCH_WIDTH, cur_lvl_tex.cols),
                            min(i + PATCH_WIDTH, cur_lvl_tex.rows) );
            Mat tex_patch = cur_lvl_tex(Rect(patch_tl, patch_br));


            //find best fit
            Mat result;
            cv::matchTemplate(re_texture, tex_patch, result, cv::TM_SQDIFF);

            Point min_loc;
            cv::minMaxLoc(result, 0, 0, &min_loc);

            //save it
            temp_coor.at(i, j) = min_loc + Point(PATCH_WIDTH, PATCH_WIDTH);
        }
    }
    cur_lvl_coords = temp_coor;
}


void ParallelControllableTextureSynthesis::coordinateMapping(int level) {
    auto &cur_lvl_tex = syn_textures[level];
    auto &cur_lvl_coords = syn_coords[level];
    
    Mat re_texture = sample_texture.clone();
    if ( cur_lvl_tex.rows < sample_texture.rows ) {
        cv::resize(sample_texture, re_texture, cur_lvl_tex.size());
    }
    cv::imshow("resize", re_texture);
    
    for (int i = 0; i < cur_lvl_tex.rows; i ++) {
        for (int j = 0; j < cur_lvl_tex.cols; j ++) {
            
            Point &pt = cur_lvl_coords.at(i, j);

            if (pt.x < 0 || pt.x >= re_texture.rows ||
                pt.y < 0 || pt.y >= re_texture.cols){
              cur_lvl_tex.at<Vec3b>(i, j) = Vec3b(255, 0, 0);
              cerr << "Error at (" << i << ", " << j << "): " << pt << endl;
              continue;
            }

            cur_lvl_tex.at<Vec3b>(i, j) = re_texture.at<Vec3b>(pt);
        }
    }
    
}


void ParallelControllableTextureSynthesis::coordinateTrim(Point &coor) {
    coor = Point(coor.x % sample_texture.cols,
                 coor.y % sample_texture.rows);
}

Mat ParallelControllableTextureSynthesis::coordsToMat(const dynamicArray2D<Point> &coords)
{
    Mat result(coords.rows, coords.cols, CV_8UC3);

    for (int i = 0; i < result.rows; i++){
        for (int j = 0; j < result.cols; j++){
            const auto &tex_pt = coords.at(i, j);
            result.at<Vec3b>(i, j) = Vec3b(0, tex_pt.x * 255.0 / coords.cols,
                                              tex_pt.y * 255.0 / coords.rows);
        }
    }

    cv::normalize(result, result, 0, 255, cv::NORM_MINMAX, CV_8U);

    return result;
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










