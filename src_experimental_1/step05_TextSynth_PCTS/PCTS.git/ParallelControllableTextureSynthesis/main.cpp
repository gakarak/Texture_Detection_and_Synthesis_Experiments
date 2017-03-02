//
//  main.cpp
//  ParallelControllableTextureSynthesis
//
//  Created by Rosani Lin on 13/4/12.
//  Copyright (c) 2013年 Rosani Lin. All rights reserved.
//

#include <iostream>
#include "ParallelControllableTextureSynthesis.h"


int main(int argc, const char * argv[])
{
    if (!_OPENMP){
      std::cerr << "OpenMP is not working" << std::endl;
    }

    ParallelControllableTextureSynthesis textsyn;
    
//    textsyn.synthesis("../ParallelControllableTextureSynthesis/tx.jpg", 4.0);
//    textsyn.synthesis("../ParallelControllableTextureSynthesis/style_v1_64x64.jpg", 4.0);
    textsyn.synthesis("../ParallelControllableTextureSynthesis/texture5_v1.jpg", 4.0);



    return 0;
}

