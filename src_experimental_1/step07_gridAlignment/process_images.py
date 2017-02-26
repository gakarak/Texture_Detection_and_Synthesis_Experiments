#!/usr/bin/env python
'''
process_images.py [-i dir_with_idx | --input dir_with_idx: default ../data/data04_for_test1_results_v1/txt02_pxy_M/cropped_and_results]

Creates shifts to regular grid of pattern for each image in idx.txt
'''
import matplotlib.pyplot as plt
import numpy as np
import cv2

import os
import sys
import glob
import argparse

import align_grid

def readIdx(wdir):
    fname = wdir + '/idx.txt'
    with open(fname) as f:
        shirt_nums = f.readlines()
    shirt_nums = [x.strip() for x in shirt_nums]
    return shirt_nums

if __name__ == '__main__':
    print(__doc__)

    parser = argparse.ArgumentParser(description='Creates shifts to regular grid of pattern for each image in idx.txt')
    parser.add_argument("-i","--input", default='../../data/data04_for_test1_results_v1/txt02_pxy_M/cropped_and_results', help="Input directory.")
    parser.add_argument("-d","--draw", action = "store_true", help="Draw figures.")
    args = parser.parse_args()
    wdir = args.input

    shirt_nums = readIdx(wdir)
    for s_num in shirt_nums:
        print('### ' + s_num + ' ###')
        shirt_path = wdir + '/' + str(s_num) + '.jpg'
        result_path = wdir + '/' + str(s_num) + '_result/'
        shirt = cv2.imread(shirt_path)

        [v_x, v_y, is_good] = align_grid.readGrid(wdir, s_num)

        if (args.draw):
            plt.figure('Original')
            plt.imshow(shirt)
            align_grid.drawGrid(v_x, v_y, is_good)
            plt.show()

        rect_is_good = is_good

        if (args.draw):
            plt.figure('Masks difference')
            plt.subplot(1,2,1), plt.imshow(is_good)
            plt.subplot(1,2,2), plt.imshow(rect_is_good)
            plt.show()

        [tx, ty] = align_grid.gatherTaoVectors(v_x, v_y, rect_is_good)
        
        tx_avg = np.average(tx, axis=0)
        ty_avg = np.average(ty, axis=0)
        print('tx average', tx_avg)
        print('ty average', ty_avg)

        [reg_v_x, reg_v_y] = align_grid.alignGrid(v_x, v_y, rect_is_good, tx_avg, ty_avg)
        
        if (args.draw):
            plt.figure('Original')
            align_grid.drawGrid(v_x, v_y, rect_is_good, 'r')
            align_grid.drawGrid(reg_v_x, reg_v_y, rect_is_good, 'b')
            plt.show()

        [values_x, values_y, bbox] = align_grid.interpolateShiftsForPixels(v_x, v_y, reg_v_x, reg_v_y, rect_is_good)

        blob = shirt[bbox[0, 1]:bbox[1, 1] + 1, bbox[0, 0]:bbox[1, 0] + 1]
        print('Blob shape: ', blob.shape)
        print('values_x shape: ', values_x.shape)
        print('values_y shape: ', values_y.shape)

        cv2.imwrite(result_path + 'blob.jpg', blob)
        np.savetxt(result_path + 'shifts_x.csv', values_x)
        np.savetxt(result_path + 'shifts_y.csv', values_y)