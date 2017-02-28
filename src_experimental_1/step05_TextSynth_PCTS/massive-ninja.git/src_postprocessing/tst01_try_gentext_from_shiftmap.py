#!/usr/bin/python
# -*- coding: utf-8 -*-
__author__ = 'ar'

import matplotlib.pyplot as plt
import cv2
import numpy as np
import skimage.io as skio

if __name__ == '__main__':
    pathImgShift = '../src/fuck.png'
    # pathImgTexture = '../src/rice_64x64.tga'
    pathImgTexture = '../src/18_64x64.tga'
    # pathImgTexture = '../src/regular.tga'
    timgShift   = (63.*skio.imread(pathImgShift).astype(np.float)/255.).astype(np.uint8)
    # timgShift   = skio.imread(pathImgShift)
    timgTexture = skio.imread(pathImgTexture)[:,:,:3]

    tret = np.zeros(timgShift.shape, np.uint8)
    for rr in range(timgShift.shape[0]):
        for cc in range(timgShift.shape[1]):
            s0 = timgShift[rr, cc, 0]
            s1 = timgShift[rr, cc, 1]
            tret[rr,cc,:] = timgTexture[s0, s1,:]


    plt.figure()
    plt.subplot(1, 3, 1)
    plt.imshow(timgShift*(256/63))
    plt.subplot(1, 3, 2)
    plt.imshow(timgTexture)
    plt.subplot(1, 3, 3)
    plt.imshow(tret)
    plt.show()