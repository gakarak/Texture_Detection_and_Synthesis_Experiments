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
import peakutils
# from peakdetect import peakdetect

def getImgGrad(timg):
    tdx = ndimage.sobel(timg, 1)
    tdy = ndimage.sobel(timg, 0)
    tgrad = np.hypot(tdx, tdy)
    return tgrad

def matchRandomTemplate(timg, paramSizeMin=60, paramSizeMax=64):
    tsiz = timg.shape
    tmpSiz = np.random.randint(paramSizeMin, paramSizeMax)
    tr = np.random.randint(0, tsiz[0] - tmpSiz - 1)
    tc = np.random.randint(0, tsiz[1] - tmpSiz - 1)
    tmp = timg[tr:tr+tmpSiz, tc:tc+tmpSiz]
    tmatch = cv2.matchTemplate(timg, tmp, cv2.TM_CCOEFF_NORMED)
    tmatch[tmatch<0] = 0
    tmatch = tmatch ** 2
    tmatch = tmatch[:tsiz[0] - paramSizeMax, :tsiz[1] - paramSizeMax]
    # tret = np.abs(np.fft.fftshift(np.fft.fft2(tmatch)))
    tret = np.abs(np.fft.fft2(tmatch))
    tmatch = np.roll(tmatch, shift=-tr, axis=0)
    tmatch = np.roll(tmatch, shift=-tc, axis=1)
    return (tret, tmatch)

#################################
if __name__ == '__main__':
    wdir = '/home/ar/dev-git.git/dev.matlab/DEMO_DATAMOLA/shirts.unzip'
    # fimg = '/home/ar/dev-git.git/dev.matlab/DEMO_DATAMOLA/shirts.unzip/2d48586954536851717a414835673866.png'
    lstfimg = glob.glob('%s/*.png' % wdir)
    numImages = len(lstfimg)
    numSamples  = 12
    sizeMin     = 60
    sizeMax     = 64
    for ii, fimg in enumerate(lstfimg):
        timg = cv2.imread(fimg, cv2.IMREAD_GRAYSCALE)
        tsiz = timg.shape
        tmpSiz = 128
        pbnd = 0.2
        #
        timgCrop = timg[int(tsiz[0]*pbnd):-int(tsiz[0]*pbnd), int(tsiz[1]*pbnd):-int(tsiz[1]*pbnd)].copy().astype(np.float32)
        timgCrop /= 255.
        # timgCrop = getImgGrad(timgCrop)
        timgFFT = np.fft.fftshift(np.fft.fft2(timgCrop))
        timgTMP = timgCrop[100:100+tmpSiz, 100:100+tmpSiz].copy()
        tmatchT = cv2.matchTemplate(timgCrop, timgTMP, cv2.TM_CCOEFF_NORMED)
        # tmatchT[tmatchT<0] = 0
        tmatchT = tmatchT**2
        # val, tmatchT = cv2.threshold(tmatchT, 0.01, 0, cv2.THRESH_TOZERO)
        #
        tmFFT = np.abs(np.fft.fftshift(np.fft.fft2(tmatchT)))
        # sumFX = np.sum(tmFFT, axis=1)
        # sumFY = np.sum(tmFFT, axis=0)
        sumFX = None
        sumFY = None
        tmatchSum = None
        for ss in range(numSamples):
            tret, tmpm = matchRandomTemplate(timgCrop, )
            # tret = np.log(tret)
            if sumFX is None:
                sumFX = np.sum(tret, axis=1)
                sumFY = np.sum(tret, axis=0)
                tmatchSum = tmpm
            else:
                sumFX += np.sum(tret, axis=1)
                sumFY += np.sum(tret, axis=0)
                tmatchSum += tmpm
        sumFX /= np.sum(sumFX)
        sumFY /= np.sum(sumFY)
        tmatchSum /= numSamples
        tmatchSum[:10,:10]=0
        tmatchSum[-10:, -10:] = 0
        #
        # pkxIdx = scipy.signal.find_peaks_cwt(sumFX, np.arange(1,5))
        # pkyIdx = scipy.signal.find_peaks_cwt(sumFY, np.arange(1,5))
        # (1) search peaks in freq-domain
        pkxIdx = peakutils.indexes(sumFX, min_dist=3)
        pkyIdx = peakutils.indexes(sumFY, min_dist=3)
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
        plt.hold(True)
        plt.plot(sumFX)
        plt.plot(pkxIdx, pkxX, 'o')
        plt.title('Freqs: lo-bnd ~%s, hi-bnd ~%s' % (freqLoBnd, freqHiBnd))
        plt.grid(True)
        plt.hold(False)
        plt.subplot(3, 3, 7)
        plt.hold(True)
        plt.plot(sumFY)
        plt.plot(pkyIdx, pkyY, 'o')
        plt.hold(False)
        plt.grid(True)
        plt.subplot(3, 3, 8)
        plt.imshow(tmatchSum)
        plt.subplot(3, 3, 9)
        if timgCrop.ndim<3:
            tmpImage = cv2.cvtColor(255.*timgCrop, cv2.COLOR_GRAY2BGR).astype(np.uint8)
        else:
            tmpImage = timgCrop.copy().astype(np.uint8)
        cv2.rectangle(tmpImage, (pxy0[0], pxy0[1]), (pxy0[0] + int(1*dx), pxy0[1] + int(1*dy)), (0,255,0), 3)
        cv2.rectangle(tmpImage, (pxy0[0], pxy0[1]), (pxy0[0] + int(4*dx), pxy0[1] + int(4*dy)), (255,0,0), 2)
        plt.imshow(tmpImage)
        plt.title('DX=%s, DY=%s, Size=%s' % (dx, dy, tmpImage.shape[:2]))
        # plt.scatter(pkx)
        plt.show()
