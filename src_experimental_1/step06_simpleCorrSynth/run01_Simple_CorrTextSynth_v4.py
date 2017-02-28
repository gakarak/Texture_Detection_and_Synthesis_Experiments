#!/usr/bin/python
# -*- coding: utf-8 -*-
__author__ = 'ar'

import os
import glob

#import skimage.io as skio

import cv2
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from scipy.ndimage.morphology import binary_erosion

##########################################
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

def MinimizePatternByTemplMatchV3(pattern, brdSize=5, isDebug=False, parMethod = cv2.TM_SQDIFF):
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
    if isDebug:
        plt.subplot(2, 2, 1), plt.imshow(ccMapH)
        plt.subplot(2, 2, 2), plt.imshow(ccMapHflt)
        plt.subplot(2, 2, 3), plt.imshow(ccMapV)
        plt.subplot(2, 2, 4), plt.imshow(ccMapVflt)
        plt.show()
    posRT = (posMaxH[0], posMaxH[1] - 1*ptrnSize)
    posLB = (posMaxV[0] - 1*ptrnSize, posMaxV[1])
    return (tretCrop, posRT, posLB)

def getBestTexton(timg, vx, vy, isGood, sizN=1, parMethod = cv2.TM_SQDIFF):
    bestTexton = None
    maxCorr = -10005000000
    posRT = (0, 0)
    posLB = (0, 0)

    bestBBox = None

    good_idx = np.transpose(np.where(is_good))
    for i, j in good_idx:
        if (i + sizN >= isGood.shape[0] or j + sizN >= isGood.shape[1]
            or not isGood[i+sizN, j+sizN]):
            continue

        bbox = getTexton(vx, vy, isGood, i, j, sizN)
        bbox = bbox * 1500 / 480

        bbW = np.abs(bbox[0][0] - bbox[0][1])
        bbH = np.abs(bbox[1][0] - bbox[1][1])
        parBorder = int(min(bbH,bbW) * 0.15)
        # parBorder = 5
        print(bbox)
        print ('Border parameter: %s' % parBorder)
        #
        imgTexton = cropTexton(timg, bbox, brdPx=parBorder, brdPrcnt=None)

        ptrnSize = parBorder+2
        brdSizeExt = int(1.7*parBorder)
        ptrnLef = imgTexton[ptrnSize:-ptrnSize, :ptrnSize]
        ptrnTop = imgTexton[:ptrnSize, ptrnSize:-ptrnSize]
        print(imgTexton.shape)
        print(ptrnLef.shape)
        ccMapH = cv2.matchTemplate(imgTexton, ptrnLef, method=parMethod)
        ccMapV = cv2.matchTemplate(imgTexton, ptrnTop, method=parMethod)
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
        _, maxVH, _, posMaxH = cv2.minMaxLoc(ccMapHflt)
        _, maxVV, _, posMaxV = cv2.minMaxLoc(ccMapVflt)

        #print(maxVH + maxVV)
        if (maxCorr < maxVH + maxVV):
            #print('#############################################################')
            bestBBox = bbox
            shiftH_X, shiftH_Y = posMaxH
            shiftV_X, shiftV_Y = posMaxV
            posRT = (posMaxH[0], posMaxH[1] - 1*ptrnSize)
            posLB = (posMaxV[0] - 1*ptrnSize, posMaxV[1])
            maxCorr = maxVH + maxVV
            bestTexton = imgTexton[:shiftV_Y, :shiftH_X]


    #print(posRT, posLB)
    #return (bestTexton, posRT, posLB)
    return bestBBox

def generateTiledTextonV1(texton, dRightY, dBottomX, nr=5, nc=5):
    tsiz = texton.shape[:2]
    sizR, sizC = tsiz
    dRR = np.abs(dRightY  * nr)
    dCC = np.abs(dBottomX * nc)
    sizRT = tsiz[0] * (nr + 2) + dRR
    sizCT = tsiz[1] * (nc + 2) + dCC
    if texton.ndim<3:
        retTexture = np.zeros((sizRT, sizCT), dtype=texton.dtype)
    else:
        nch = texton.shape[-1]
        retTexture = np.zeros((sizRT, sizCT, nch), dtype=texton.dtype)
    r0 = dRR + tsiz[0] / 2
    c0 = dCC + tsiz[1] / 2
    for rri in range(nr):
        rr = r0 + rri*sizR + 1 * dRightY
        for cci in range(nc):
            cc = c0 + cci * sizC + 1 * dBottomX
            if texton.ndim>2:
                retTexture[rr:rr+sizR, cc:cc+sizC,:] = texton.copy()
            else:
                retTexture[rr:rr + sizR, cc:cc + sizC, :] = texton.copy()
    return retTexture

def generateTiledTextonV2(textonBRD, posXY_RT, posXY_LB, nr=5, nc=5, isDebug=False):
    tsiz = textonBRD.shape[:2]
    sizR, sizC = tsiz
    drShiftTot = posRT[1] * (nc - 0)
    dcShiftTot = posLB[0] * (nr - 0)
    drStep = np.abs(posXY_LB[1] * 1)
    dcStep = np.abs(posXY_RT[0] * 1)
    sizRT = drStep * (nr + 1) + abs(drShiftTot)
    sizCT = dcStep * (nc + 1) + abs(dcShiftTot)
    vRT = np.array((posRT[1],posRT[0]))
    vLB = np.array((posLB[1],posLB[0]))
    if textonBRD.ndim<3:
        retTexture = np.zeros((sizRT, sizCT), dtype=textonBRD.dtype)
    else:
        nch = textonBRD.shape[-1]
        retTexture = np.zeros((sizRT, sizCT, nch), dtype=textonBRD.dtype)
    if drShiftTot<0:
        r0 = abs(drShiftTot)
    else:
        r0 = 0
    if dcShiftTot<0:
        c0 = abs(dcShiftTot)
    else:
        c0 =0
    r00 = np.array((r0,c0))
    for rri in range(nr):
        # rr = r0 + rri * posXY_LB[1]
        for cci in range(nc):
            # cc = c0 + cci * posXY_RT[0] + rri*(posLB[1])
            rr,cc = (r00 + rri*vLB + cci*vRT).tolist()
            if textonBRD.ndim>2:
                retTexture[rr:rr + sizR, cc:cc + sizC, :] = textonBRD.copy()
            else:
                retTexture[rr:rr + sizR, cc:cc + sizC, :] = textonBRD.copy()
    if not isDebug:
        r0 = abs(drShiftTot)
        c0 = abs(dcShiftTot)
        retTexture = retTexture[r0:r0 + (drStep*nr), c0:c0+(dcStep*nc), :]
    return retTexture

def ReadGraph(pdir, shirt_num):
    wdir = '%s/%s_result/' % (pdir, shirt_num )
    v_x = np.loadtxt(wdir+'pts_x.csv', delimiter=',') - 100 - 1 #FIXME: shift in 100px is automaticaly added by Texture Extraction Algorithm
    v_y = np.loadtxt(wdir+'pts_y.csv', delimiter=',') - 100 - 1
    is_good = np.loadtxt(wdir+'is_good.csv', dtype='bool', delimiter=',')
    return [v_x, v_y, is_good]

##########################################
def maskErosion(is_good, percent_of_src = 0.4, min_square = 10):
    """
        percent_of_src - result square is about percent_of_src of source square
    """
    blob_is_good = is_good.copy()
    
    min_square = max(percent_of_src*np.sum(is_good), min_square)
    while np.sum(blob_is_good) > min_square:
        blob_is_good = binary_erosion(blob_is_good)

    return blob_is_good

def getTexton(vx, vy, isGood, row, col, sizN=1):
    X = []
    Y = []
    X += [vx[(row + 0   , col + 0)]]
    X += [vx[(row + sizN, col + 0)]]
    X += [vx[(row + 0   , col + sizN)]]
    X += [vx[(row + sizN, col + sizN)]]
    print(X)
    Y += [vy[(row + 0   , col + 0)]]
    Y += [vy[(row + sizN, col + 0)]]
    Y += [vy[(row + 0   , col + sizN)]]
    Y += [vy[(row + sizN, col + sizN)]]
    print(Y)
    min_x = min(X)
    max_x = max(X)
    min_y = min(Y)
    max_y = max(Y)
    # bbox = np.array([[min_y, min_x], [max_y, max_x]])
    bbox = np.array([[min_x, max_x], [min_y, max_y]])
    bbox = np.round(bbox)
    
    return bbox


def getRandomTexton(vx, vy, isGood, sizN=1):
    rows, cols = np.where(isGood)
    idxRnd = np.random.randint(len(rows))

    print ('pos = (%d, %d)' % (rows[idxRnd], cols[idxRnd]))

    return getTexton(vx, vy, isGood, rows[idxRnd], cols[idxRnd], sizN)

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
    xmin = int(texBBox[0][0])
    xmax = int(texBBox[0][1])
    ymin = int(texBBox[1][0])
    ymax = int(texBBox[1][1])
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
        tret = timg[max(ymin - dr, 0):min(ymax + dr, timg.shape[0]), 
                    max(xmin - dc, 0):min(xmax + dc, timg.shape[1]), :].copy()
    return tret

##########################################
if __name__ == '__main__':
    fidx = '../../data/data04_for_test1_results_v1/txt02_pxy_M/cropped_and_results/idx.txt'
    # fidx = '/home/ar/github.com/Texture_Detection_and_Synthesis_Experiments.git/data/data04_for_test1_results_v1/txt02_pxy_M/cropped_and_results/idx.txt'
    wdir = os.path.dirname(fidx)
    with open(fidx, 'r') as f:
        lstIdx = f.read().splitlines()
    numImg = len(lstIdx)
    if numImg<1:
        raise Exception('Cant find image Idxs in file [%s]' % fidx)
    lstPathImg = [os.path.join(wdir, '%s.jpg' % ii) for ii in lstIdx]
    paramSizTexton=2
    for ii,pathImg in enumerate(lstPathImg):
        # if ii!=9:
        #     continue
        print ('[%d/%d] : %s' % (ii, numImg, pathImg))
        tidx = lstIdx[ii]
        timg = np.array(cv2.imread(pathImg))
        big_img = np.array(cv2.imread(os.path.join(wdir, '%s_big.jpg' % tidx)))

        [v_x, v_y, is_good] = ReadGraph(wdir, tidx)
        # arrXY = getGoodGridPoints(v_x, v_y, is_good)
        #FIxME: remove buttons
        # is_good[:, is_good.shape[1] / 2] = False
        isGoodMsk = maskErosion(is_good, percent_of_src = 0.6, min_square = 10)
        retBBox = getBestTexton(big_img, v_x, v_y, isGoodMsk, sizN=paramSizTexton)
        # retBBox = getRandomTexton(v_x, v_y, isGoodMsk, sizN=paramSizTexton)
        print (retBBox)
        bbW = np.abs(retBBox[0][0] - retBBox[0][1])
        bbH = np.abs(retBBox[1][0] - retBBox[1][1])
        parBorder = int(min(bbH,bbW) * 0.15)
        # parBorder = 5
        print ('Border parameter: %s' % parBorder)
        #
        arrXY = getGoodGridPoints(v_x, v_y, isGoodMsk)
        imgTexton = cropTexton(big_img, retBBox, brdPx=parBorder, brdPrcnt=None)

        # imgTextonCorr = MinimizePatternByTemplMatchV1(imgTexton)
        # imgTextonCorr = MinimizePatternByTemplMatchV2(imgTexton, brdSize=parBorder)
        # imgTextonCorr, pdRightY, pdBottomX = MinimizePatternByTemplMatchV3(imgTexton, brdSize=parBorder)
        imgTextonCorr, posRT, posLB = MinimizePatternByTemplMatchV3(imgTexton, brdSize=parBorder)
        # genTexture = generateTiledTextonV2(imgTextonCorr, posRT)
        genTexture = generateTiledTextonV2(imgTexton, posRT, posLB)
        imgTextonCorrTiled   = np.tile(imgTextonCorr, (9, 9, 1))
        # imgTextonCorrTiled = genTexture
        imgTextonStupidTiled = np.tile(imgTexton, (9, 9, 1))
        #
        plt.figure()
        tmpH = plt.subplot(2, 3, 1)
        plt.hold(True)
        plt.imshow(timg)
        plt.plot(arrXY[:,0], arrXY[:,1], 'or')
        small_bbox = retBBox * 480 / 1500
        sbbW = np.abs(small_bbox[0][0] - small_bbox[0][1])
        sbbH = np.abs(small_bbox[1][0] - small_bbox[1][1])
        tp1 = patches.Rectangle((small_bbox[0][0], small_bbox[1][0]), sbbW, sbbH,     fill=False, linewidth=3, edgecolor='g')
        tp2 = patches.Rectangle((small_bbox[0][0], small_bbox[1][0]), 2*sbbW, 2*sbbH, fill=False, linewidth=2, edgecolor='g')
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
        plt.title('Random Texton [%dx%d]' % (paramSizTexton,paramSizTexton))
        plt.hold(False)
        plt.subplot(2, 3, 4)
        plt.imshow(imgTextonCorrTiled)
        plt.title('Corr-Synthesis V1')
        plt.subplot(2, 3, 5)
        plt.imshow(genTexture)
        plt.title('Corr-Synthesis V2')
        plt.subplot(2, 3, 6)
        plt.imshow(imgTextonStupidTiled)
        plt.title('Texture Synth: periodic tiling')
        plt.show()

