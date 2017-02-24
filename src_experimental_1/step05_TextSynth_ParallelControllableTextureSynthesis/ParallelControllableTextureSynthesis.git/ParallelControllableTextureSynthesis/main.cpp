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
    ParallelControllableTextureSynthesis textsyn = ParallelControllableTextureSynthesis();
    
    
    textsyn.synthesis("../ParallelControllableTextureSynthesis/tx.jpg", 2.0);
//    textsyn.synthesis("../ParallelControllableTextureSynthesis/style_v1_64x64.jpg", 2.0);



    return 0;
}

