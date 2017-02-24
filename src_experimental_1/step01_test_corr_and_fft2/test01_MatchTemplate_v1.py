#!/usr/bin/python
# -*- coding: utf-8 -*-
__author__ = 'ar'


import cv2
import matplotlib.pyplot as plt
import numpy as np
import skimage.io as skio

if __name__ == '__main__':
    wdir = '/home/ar/dev-git.git/dev.matlab/DEMO_DATAMOLA/shirts.unzip'
    fimg = '/home/ar/dev-git.git/dev.matlab/DEMO_DATAMOLA/shirts.unzip/2d48586954536851717a414835673866.png'
    timg = cv2.imread(fimg, cv2.IMREAD_GRAYSCALE)
    tsiz = timg.shape
    tmpSiz = 128
    pbnd = 0.2
    #
    timgCrop = timg[int(tsiz[0]*pbnd):-int(tsiz[0]*pbnd), int(tsiz[1]*pbnd):-int(tsiz[1]*pbnd)].copy().astype(np.float32)/255.
    timgFFT = np.fft.fftshift(np.fft.fft2(timgCrop))
    timgTMP = timgCrop[100:100+tmpSiz, 100:100+tmpSiz].copy()
    tmatchT = cv2.matchTemplate(timgCrop, timgTMP, cv2.TM_CCOEFF_NORMED)
    tmatchT[tmatchT<0] = 0
    tmatchT = tmatchT**2
    # val, tmatchT = cv2.threshold(tmatchT, 0.01, 0, cv2.THRESH_TOZERO)
    #
    tmFFT = np.abs(np.fft.fftshift(np.fft.fft2(tmatchT)))
    sumFX = np.sum(tmFFT, axis=1)
    sumFY = np.sum(tmFFT, axis=0)
    #
    plt.figure()
    plt.subplot(3, 3, 1)
    plt.imshow(timgCrop, cmap=plt.gray()), plt.title('Original')
    plt.subplot(3, 3, 2)
    plt.imshow(np.log(np.abs(timgFFT)), cmap=plt.gray()), plt.title('FFT2+FFTShift')
    plt.subplot(3, 3, 3)
    plt.imshow(timgTMP), plt.title('Template')
    plt.subplot(3, 3, 4)
    plt.imshow(tmatchT, cmap=plt.gray()), plt.title('Correlation MAP')
    plt.subplot(3, 3, 5)
    plt.imshow(np.log(np.abs(tmFFT)), cmap=plt.gray()), plt.title('Corr-FFT')
    plt.subplot(3, 3, 6)
    plt.plot(sumFX)
    plt.subplot(3, 3, 7)
    plt.plot(sumFY)
    plt.subplot(3, 3, 8)
    plt.plot(sumFX, sumFY)
    plt.show()
