#!/usr/bin/env python
'''
mouse_and_match.py [-i path | --input path: default ../data/]

Demonstrate using a mouse to interact with an image:
 Read in the images in a directory one by one
 Allow the user to select parts of an image with a mouse
 When they let go of the mouse, it correlates (using matchTemplate) that patch with the image.

 SPACE for next image
 ESC to exit
'''

# Python 2/3 compatibility
from __future__ import print_function

import numpy as np
import cv2

import matplotlib.pyplot as plt

# built-in modules
import os
import sys
import glob
import argparse
from math import *

from skimage.feature import match_template


drag_start = None
sel = (0,0,0,0)

def MinimizePatternByTemplMatch(pattern):
    height = pattern.shape[0]
    width = pattern.shape[1]
    
    left   = pattern[:, :width/2]
    right  = pattern[:, width/2:]
    top    = pattern[:height/2]
    bottom = pattern[height/2:]
    
    #search left on right
    result1 = cv2.matchTemplate(right, left[:, :left.shape[1]/3], cv2.TM_CCORR_NORMED)
    maxLoc = cv2.minMaxLoc(result1)[3]
    max_x = maxLoc[0] + width/2 - left.shape[1]/3/2
    
    #search top on bottom
    result2 = cv2.matchTemplate(bottom, top[:top.shape[0]/3, :], cv2.TM_CCORR_NORMED)

    maxLoc = cv2.minMaxLoc(result2)[3]
    max_y = maxLoc[1] + height/2 - top.shape[0]/3/2

    # plt.subplot(1, 2, 1)
    # plt.plot(result1.reshape(-1))
    # plt.subplot(1, 2, 2)
    # plt.plot(result2.reshape(-1))
    # plt.show(block=False)

    return pattern[:max_y, :max_x]

def AutoCorrPattern(patch):
    return match_template(patch, patch, pad_input=True)

def HugeSelect(sel, bounds):
    res = list(sel)

    h = sel[3] - sel[1] #height
    w = sel[2] - sel[0] #width

    res[1] = max(res[1] - h, 0)
    res[3] = min(res[3] + h, bounds[0])
    res[0] = max(res[0] - w, 0)
    res[2] = min(res[2] + w, bounds[1])
    return res


def onmouse(event, x, y, flags, param):
    global drag_start, sel
    if event == cv2.EVENT_LBUTTONDOWN:
        drag_start = x, y
        sel = 0, 0, 0, 0
    elif event == cv2.EVENT_LBUTTONUP:
        if sel[2] > sel[0] and sel[3] > sel[1]:
            huge_sel = HugeSelect(sel, img.shape)

            patch = img[sel[1]:sel[3], sel[0]:sel[2]]
            huge_patch = img[huge_sel[1]:huge_sel[3], huge_sel[0]:huge_sel[2]]

            min_pattern = MinimizePatternByTemplMatch(patch)
            tiled = np.tile(min_pattern, (7, 7, 1))
            cv2.imshow("result", tiled)

            stupid_tile = np.tile(patch, (7, 7, 1))
            cv2.imshow("stupid", stupid_tile)

            # autocorr = AutoCorrPattern(huge_patch)
            # cv2.imshow("Autocorr", autocorr)
            # result = cv2.matchTemplate(gray,patch,cv2.TM_CCOEFF_NORMED)
            # result = np.abs(result)**3
            # val, result = cv2.threshold(result, 0.01, 0, cv2.THRESH_TOZERO)
            # result8 = cv2.normalize(result,None,0,255,cv2.NORM_MINMAX,cv2.CV_8U)
            # cv2.imshow("result", result8)
        drag_start = None
    elif drag_start:
        # print flags
        if flags & cv2.EVENT_FLAG_LBUTTON:
            minpos = min(drag_start[0], x), min(drag_start[1], y)
            maxpos = max(drag_start[0], x), max(drag_start[1], y)
            sel = minpos[0], minpos[1], maxpos[0], maxpos[1]
            # img = cv2.cvtColor(gray, cv2.COLOR_GRAY2BGR)
            draw_img = img.copy()
            cv2.rectangle(draw_img, (sel[0], sel[1]), (sel[2], sel[3]), (0, 255, 255), 1)
            cv2.imshow("gray", draw_img)
        else:
            print("selection is complete")
            drag_start = None

if __name__ == '__main__':
    print(__doc__)

    parser = argparse.ArgumentParser(description='Demonstrate mouse interaction with images')
    parser.add_argument("-i","--input", default='../../data/data02_simpleCorrSynth', help="Input directory.")
    args = parser.parse_args()
    path = args.input

    cv2.namedWindow("gray",1)
    cv2.setMouseCallback("gray", onmouse)
    '''Loop through all the images in the directory'''
    for infile in glob.glob( os.path.join(path, '*.*') ):
        ext = os.path.splitext(infile)[1][1:] #get the filename extenstion
        if ext == "png" or ext == "jpg" or ext == "bmp" or ext == "tiff" or ext == "pbm":
            print(infile)

            img=cv2.imread(infile,1)
            if img is None:
                continue
            sel = (0,0,0,0)
            drag_start = None
            #gray=cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            #gray = img
            cv2.imshow("gray",img)
            if (cv2.waitKey() & 255) == 27:
                break
    cv2.destroyAllWindows()
