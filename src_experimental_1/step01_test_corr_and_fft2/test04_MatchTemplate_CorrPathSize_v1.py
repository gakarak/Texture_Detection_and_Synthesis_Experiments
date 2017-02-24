#!/usr/bin/python
# -*- coding: utf-8 -*-
__author__ = 'ar'


import cv2
import matplotlib.pyplot as plt
import numpy as np
import scipy.signal
import glob
import os

from scipy import ndimage
from skimage.feature import match_template


import peakutils
# from peakdetect import peakdetect

def matchFullyCorr(timg):
    tmatch0 = match_template(timg, timg, pad_input=True)
    # tmatch0 = timg.copy()
    tmatch = tmatch0.copy()
    # tmatch[tmatch < 0] = 0
    tmatch = tmatch ** 2
    tret = np.abs(np.fft.fft2(tmatch))
    return (tret, tmatch0)

def getImgGrad(timg):
    tdx = ndimage.sobel(timg, 1)
    tdy = ndimage.sobel(timg, 0)
    tgrad = np.hypot(tdx, tdy)
    return tgrad

#################################
if __name__ == '__main__':
    wdir = '../../data/data03_for_demo/ex01_simple'
    lstfimg = glob.glob('%s/*.jpg' % wdir)
    numImages = len(lstfimg)
    numSamples  = 12
    sizeMin     = 60
    sizeMax     = 16
    dx = 1
    dy = 1
    for ii, fimg in enumerate(lstfimg):
        timg = cv2.imread(fimg, cv2.IMREAD_GRAYSCALE)
        tsiz = timg.shape
        tmpSiz = 128
        pbnd = 0.2
        #
        timgCrop = timg[int(tsiz[0]*pbnd):-int(tsiz[0]*pbnd), int(tsiz[1]*pbnd):-int(tsiz[1]*pbnd)].copy().astype(np.float32)
        timgCrop /= 255.
        timgCrop = getImgGrad(timgCrop)
        tcorrFFT, tcorrMap = matchFullyCorr(timgCrop)
        sumFX = np.sum(tcorrFFT, axis=1)
        sumFY = np.sum(tcorrFFT, axis=0)
        # (1) search peaks in freq-domain
        pkxIdx = peakutils.indexes(sumFX, min_dist=2)
        pkyIdx = peakutils.indexes(sumFY, min_dist=2)
        pkxX   = sumFX[pkxIdx]
        pkyY   = sumFY[pkyIdx]
        # (2) select low-frequency peaks and transform into spatial shifts
        freqXYMax = np.array([sumFX.size/2, sumFY.size/2])
        freqLoBnd = 0.5*np.ceil(freqXYMax/(float(sizeMax)/2.))
        freqHiBnd = 12*freqLoBnd
        pkxIdxFlt = pkxIdx[(pkxIdx > freqLoBnd[0]) & (pkxIdx < freqHiBnd[0])]
        pkyIdxFlt = pkyIdx[(pkyIdx > freqLoBnd[1]) & (pkyIdx < freqHiBnd[1])]
        isShiftX = len(pkxIdxFlt)
        isShiftY = len(pkyIdxFlt)
        isHasShift = isShiftY | isShiftX
        if isShiftX:
            pkxIdxFltVal = sumFX[pkxIdxFlt]
            tidx = np.argsort(pkxIdxFltVal)
            pkxIdxFltSort = pkxIdxFlt[tidx]
            isShiftX = True
        if isShiftY:
            pkyIdxFltVal = sumFY[pkyIdxFlt]
            tidx = np.argsort(pkyIdxFltVal)
            pkyIdxFltSort = pkyIdxFlt[tidx]
        #
        if isShiftX:
            dx = sumFX.size/pkxIdxFltSort[0]
        elif isShiftY:
            dx = sumFY.size/pkyIdxFltSort[0]
        else:
            print ('*** Cant determine X-Shift for [%s]' % os.path.basename(fimg))
        if isShiftY:
            dy = sumFY.size/pkyIdxFltSort[0]
        elif isShiftX:
            dy = sumFX.size/pkxIdxFltSort[0]
        else:
            print ('*** Cant determine Y-Shift for [%s]' % os.path.basename(fimg))
        pxy0 = [int(timgCrop.shape[1] * 0.1), int(timgCrop.shape[0] * 0.1)]
        #
        plt.figure()
        plt.subplot(2, 3, 1)
        plt.imshow(timgCrop, cmap=plt.gray()), plt.title('Original')
        plt.subplot(2, 3, 2)
        plt.imshow(np.log(tcorrFFT), cmap=plt.gray()), plt.title('CorrFFT')
        plt.subplot(2, 3, 3)
        plt.hold(True)
        plt.plot(sumFX)
        plt.plot(pkxIdx, pkxX, 'o')
        plt.title('Freqs: lo-bnd ~%s, hi-bnd ~%s' % (freqLoBnd, freqHiBnd))
        plt.grid(True)
        plt.hold(False)
        plt.subplot(2, 3, 4)
        plt.hold(True)
        plt.plot(sumFY)
        plt.plot(pkyIdx, pkyY, 'o')
        plt.hold(False)
        plt.grid(True)
        plt.subplot(2, 3, 5)
        plt.imshow(tcorrMap), plt.title('CorrMap')
        plt.subplot(2, 3, 6)
        if timgCrop.ndim<3:
            tmpImage = cv2.cvtColor(255.*timgCrop, cv2.COLOR_GRAY2BGR).astype(np.uint8)
        else:
            tmpImage = timgCrop.copy().astype(np.uint8)
        cv2.rectangle(tmpImage, (pxy0[0], pxy0[1]), (pxy0[0] + int(1*dx), pxy0[1] + int(1*dy)), (0,255,0), 3)
        cv2.rectangle(tmpImage, (pxy0[0], pxy0[1]), (pxy0[0] + int(4*dx), pxy0[1] + int(4*dy)), (255,0,0), 2)
        plt.imshow(tmpImage)
        plt.title('DX=%s, DY=%s, Size=%s' % (dx, dy, tmpImage.shape[:2]))
        plt.show()
