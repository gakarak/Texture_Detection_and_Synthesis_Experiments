#!/usr/bin/python
# -*- coding: utf-8 -*-
__author__ = 'ar'

import os
import glob

import skimage.io as skio

import cv2
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from scipy.ndimage.morphology import binary_erosion

##########################################
def MinimizePatternByTemplMatchV1(pattern):
    height = pattern.shape[0]
    width = pattern.shape[1]
    left = pattern[:, :width / 2]
    right = pattern[:, width / 2:]
    top = pattern[:height / 2]
    bottom = pattern[height / 2:]
    # search left on right
    result = cv2.matchTemplate(right, left[:, :left.shape[1] / 3], cv2.TM_CCORR_NORMED)
    maxLoc = cv2.minMaxLoc(result)[3]
    max_x = maxLoc[0] + width / 2 - left.shape[1] / 3 / 2
    # plt.imshow(result)
    # search top on bottom
    result = cv2.matchTemplate(bottom, top[:top.shape[0] / 3, :], cv2.TM_CCORR_NORMED)
    maxLoc = cv2.minMaxLoc(result)[3]
    max_y = maxLoc[1] + height / 2 - top.shape[0] / 3 / 2
    return pattern[:max_y, :max_x]

def MinimizePatternByTemplMatchV2(pattern, brdSize=5, isDebug=False):
    ptrnSize = brdSize+2
    ptrnLef = pattern[:, :ptrnSize]
    ptrnTop = pattern[:ptrnSize, :]
    # ccMapH = cv2.matchTemplate(pattern, ptrnLef, method=cv2.TM_CCOEFF_NORMED).reshape(-1)
    # ccMapV = cv2.matchTemplate(pattern, ptrnTop, method=cv2.TM_CCOEFF_NORMED).reshape(-1)
    ccMapH = 1. - cv2.matchTemplate(pattern, ptrnLef, method=cv2.TM_SQDIFF_NORMED).reshape(-1)
    ccMapV = 1. - cv2.matchTemplate(pattern, ptrnTop, method=cv2.TM_SQDIFF_NORMED).reshape(-1)
    ccMapHflt = ccMapH.copy()
    ccMapVflt = ccMapV.copy()
    ccMapHflt[:-2 * brdSize] = 0
    ccMapVflt[:-2 * brdSize] = 0
    pMaxH = np.argmax(ccMapHflt)
    pMaxV = np.argmax(ccMapVflt)
    if isDebug:
        plt.figure()
        plt.subplot(1, 2, 1)
        plt.hold(True)
        plt.plot(ccMapH)
        plt.plot(ccMapHflt)
        plt.hold(False)
        plt.title('CC-Map-H')
        #
        plt.subplot(1, 2, 2)
        plt.hold(True)
        plt.plot(ccMapV)
        plt.plot(ccMapVflt)
        plt.hold(False)
        plt.title('CC-Map-V')
        plt.show()
    tret = pattern[:pMaxV, :pMaxH]
    return tret

def MinimizePatternByTemplMatchV3(pattern, brdSize=5, isDebug=False, parMethod = cv2.TM_SQDIFF_NORMED):
    ptrnSize = brdSize+2
    brdSizeExt = int(1.7*brdSize)
    ptrnLef = pattern[ptrnSize:-ptrnSize, :ptrnSize]
    ptrnTop = pattern[:ptrnSize, ptrnSize:-ptrnSize]
    ccMapH = cv2.matchTemplate(pattern, ptrnLef, method=parMethod)
    ccMapV = cv2.matchTemplate(pattern, ptrnTop, method=parMethod)
    if parMethod==cv2.TM_SQDIFF or parMethod==cv2.TM_SQDIFF_NORMED:
        ccMapH = 1. - ccMapH
        ccMapV = 1. - ccMapV
    minH = ccMapH.min()
    minV = ccMapV.min()
    ccMapHflt = ccMapH.copy()
    ccMapVflt = ccMapV.copy()
    ccMapHflt[:, :-brdSizeExt] = minH
    ccMapVflt[:-brdSizeExt, :] = minV
    # pMaxH = np.argmax(ccMapHflt)
    # pMaxV = np.argmax(ccMapVflt)
    _, _, _, posMaxH = cv2.minMaxLoc(ccMapHflt)
    _, _, _, posMaxV = cv2.minMaxLoc(ccMapVflt)
    #
    shiftH_X, shiftH_Y = posMaxH
    shiftV_X, shiftV_Y = posMaxV
    tretCrop = pattern[:shiftV_Y, :shiftH_X]
    #
    plt.subplot(2, 2, 1), plt.imshow(ccMapH)
    plt.subplot(2, 2, 2), plt.imshow(ccMapHflt)
    plt.subplot(2, 2, 3), plt.imshow(ccMapV)
    plt.subplot(2, 2, 4), plt.imshow(ccMapVflt)
    plt.show()
    if isDebug:
        plt.figure()
        plt.subplot(1, 2, 1)
        plt.hold(True)
        plt.plot(ccMapH)
        plt.plot(ccMapHflt)
        plt.hold(False)
        plt.title('CC-Map-H')
        #
        plt.subplot(1, 2, 2)
        plt.hold(True)
        plt.plot(ccMapV)
        plt.plot(ccMapVflt)
        plt.hold(False)
        plt.title('CC-Map-V')
        plt.show()
    return (tretCrop, shiftH_Y, shiftV_X)


def ReadGraph(pdir, shirt_num):
    wdir = '%s/%s_result/' % (pdir, shirt_num )
    v_x = np.loadtxt(wdir+'pts_x.csv', delimiter=',') - 100 - 1 #FIXME: shift in 100px is automaticaly added by Texture Extraction Algorithm
    v_y = np.loadtxt(wdir+'pts_y.csv', delimiter=',') - 100 - 1
    is_good = np.loadtxt(wdir+'is_good.csv', dtype='bool', delimiter=',')
    return [v_x, v_y, is_good]

##########################################
def getRandomTexton(vx, vy, isGood, sizN=1, numErosionMax=2):
    tmpIsGood = isGood.copy()
    cntErosion = 0
    for ii in range(numErosionMax):
        tmp = binary_erosion(tmpIsGood)
        if np.sum(tmp) > 0:
            tmpIsGood = tmp
            cntErosion += 1
        else:
            break
    rndR, rndC = np.where(tmpIsGood)
    idxRnd = np.random.randint(len(rndR))
    rndRC = (rndR[idxRnd], rndC[idxRnd])
    print(rndRC)
    # plt.subplot(1, 2, 1), plt.imshow(is_good)
    # plt.subplot(1, 2, 2), plt.imshow(tmpIsGood)
    # plt.title('pos = %s, #Erosion=%d' % (list(rndRC), cntErosion))
    print ('pos = %s, #Erosion=%d' % (list(rndRC), cntErosion))
    X = []
    Y = []
    X += [vx[(rndRC[0] + 0   , rndRC[1] + 0)]]
    X += [vx[(rndRC[0] + sizN, rndRC[1] + 0)]]
    X += [vx[(rndRC[0] + 0   , rndRC[1] + sizN)]]
    X += [vx[(rndRC[0] + sizN, rndRC[1] + sizN)]]
    print(X)
    Y += [vy[(rndRC[0] + 0   , rndRC[1] + 0)]]
    Y += [vy[(rndRC[0] + sizN, rndRC[1] + 0)]]
    Y += [vy[(rndRC[0] + 0   , rndRC[1] + sizN)]]
    Y += [vy[(rndRC[0] + sizN, rndRC[1] + sizN)]]
    print(Y)
    min_x = min(X)
    max_x = max(X)
    min_y = min(Y)
    max_y = max(Y)
    # bbox = np.array([[min_y, min_x], [max_y, max_x]])
    bbox = np.array([[min_x, max_x], [min_y, max_y]])
    bbox = np.round(bbox)
    return (bbox, tmpIsGood)

##########################################
def getGoodGridPoints(vx,vy, isGood):
    nr,nc = isGood.shape
    lstXX = []
    lstYY = []
    for rr in range(nr):
        for cc in range(nc):
            if isGood[rr,cc]:
                x0 = vx[rr, cc]
                y0 = vy[rr, cc]
                lstXX.append(x0)
                lstYY.append(y0)
    return np.array([lstXX,lstYY]).transpose()

def cropTexton(timg, texBBox, brdPrcnt=0.1, brdPx=None):
    tsiz = np.array(timg.shape[:2])
    xmin = texBBox[0][0]
    xmax = texBBox[0][1]
    ymin = texBBox[1][0]
    ymax = texBBox[1][1]
    if brdPrcnt is None:
        if brdPx is not None:
            dr = brdPx
            dc = brdPx
        else:
            dr = 0
            dc = 0
    else:
        dr = int(brdPrcnt * np.abs(ymax - ymin))
        dc = int(brdPrcnt * np.abs(xmax - xmin))
    if timg.ndim<3:
        tret = timg[ymin - dr:ymax + dr, xmin - dc:xmax + dc].copy()
    else:
        tret = timg[ymin - dr:ymax + dr, xmin - dc:xmax + dc, :].copy()
    return tret

##########################################
if __name__ == '__main__':
    fidx = '/home/ar/github.com/Texture_Detection_and_Synthesis_Experiments.git/data/data04_for_test1_results_v1/txt01_pxy_S/cropped_and_results/idx.txt'
    # fidx = '/home/ar/github.com/Texture_Detection_and_Synthesis_Experiments.git/data/data04_for_test1_results_v1/txt02_pxy_M/cropped_and_results/idx.txt'
    wdir = os.path.dirname(fidx)
    with open(fidx, 'r') as f:
        lstIdx = f.read().splitlines()
    numImg = len(lstIdx)
    if numImg<1:
        raise Exception('Cant find image Idxs in file [%s]' % fidx)
    lstPathImg = [os.path.join(wdir, '%s.jpg' % ii) for ii in lstIdx]
    for ii,pathImg in enumerate(lstPathImg):
        print ('[%d/%d] : %s' % (ii, numImg, pathImg))
        tidx = lstIdx[ii]
        timg = skio.imread(pathImg)
        [v_x, v_y, is_good] = ReadGraph(wdir, tidx)
        arrXY = getGoodGridPoints(v_x, v_y, is_good)
        retBBox, isGoodMsk = getRandomTexton(v_x, v_y, is_good, sizN=2)
        print (retBBox)
        bbW = np.abs(retBBox[0][0] - retBBox[0][1])
        bbH = np.abs(retBBox[1][0] - retBBox[1][1])
        parBorder = int(min(bbH,bbW) * 0.2)
        print ('Border parameter: %s' % parBorder)
        #
        imgTexton = cropTexton(timg, retBBox, brdPx=parBorder, brdPrcnt=None)
        # imgTextonCorr = MinimizePatternByTemplMatchV1(imgTexton)
        imgTextonCorr = MinimizePatternByTemplMatchV2(imgTexton, brdSize=parBorder)
        # imgTextonCorr = MinimizePatternByTemplMatchV3(imgTexton, brdSize=parBorder)
        imgTextonCorrTiled   = np.tile(imgTextonCorr, (9, 9, 1))
        imgTextonStupidTiled = np.tile(imgTexton, (9, 9, 1))
        #
        plt.figure()
        tmpH = plt.subplot(2, 3, 1)
        plt.hold(True)
        plt.imshow(timg)
        plt.plot(arrXY[:,0], arrXY[:,1], 'or')
        tp1 = patches.Rectangle((retBBox[0][0], retBBox[1][0]), bbW, bbH,     fill=False, linewidth=3, edgecolor='g')
        tp2 = patches.Rectangle((retBBox[0][0], retBBox[1][0]), 2*bbW, 2*bbH, fill=False, linewidth=2, edgecolor='g')
        tmpH.add_patch(tp1)
        tmpH.add_patch(tp2)
        plt.hold(False)
        plt.title('Corr-Grid-of-Points')
        plt.subplot(2, 3, 2)
        plt.imshow(np.dstack((is_good, isGoodMsk, is_good)))
        plt.title('Good-Mask')
        tmpH = plt.subplot(2, 3, 3)
        plt.hold(True)
        plt.imshow(imgTexton)
        plt.title('Random sampled Texton')
        plt.hold(False)
        plt.subplot(2, 3, 4)
        plt.imshow(imgTextonCorrTiled)
        plt.title('Texture Synth: Simple Correlation')
        plt.subplot(2, 3, 5)
        plt.imshow(imgTextonStupidTiled)
        plt.title('Texture Synth: periodic tiling')
        plt.show()

