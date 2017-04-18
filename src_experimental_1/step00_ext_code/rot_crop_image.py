import os
import glob
import numpy as np
import skimage.io as skio
import skimage.transform as sktf
import io
import pandas as pd
import matplotlib.pyplot as plt
import re
import cv2

def cropAndRotateAroundPoint(pimg, pnt, angle, arrPts, rsize=48, pscale=1., isDebug=False, outShape=None):
    size = 2. * rsize
    sizeSqr =  size * np.sq(2.)
    # (1) Shift
    dx1 = -pnt[0] + sizeSqr/2.
    dy1 = -pnt[1] + sizeSqr/2.
    matShift1 = getMatShift(dx1, dy1)
    imgShift1 = cv2.warpAffine(pimg, matShift1, (int(sizeSqr), int(sizeSqr)), None, cv2.INTER_CUBIC)
    ptsShift1 = warpAffinePts(matShift1, arrPts)
    # (2) Rotate
    matRot1 = cv2.getRotationMatrix2D((sizeSqr/2., sizeSqr/2.), angle, pscale)
    imgRot1 = cv2.warpAffine(imgShift1, matRot1, (int(sizeSqr), int(sizeSqr)), None, cv2.INTER_CUBIC)
    ptsRot1 = warpAffinePts(matRot1, ptsShift1)
    # (3)
    dx2 = -(sizeSqr - size)/2.
    dy2 = dx2
    matShift2 = getMatShift(dx2, dy2)
    imgShift2 = cv2.warpAffine(imgRot1, matShift2, (int(size), int(size)), None, cv2.INTER_CUBIC)
    ptsShift2 = warpAffinePts(matShift2, ptsRot1)
    #
    if outShape is not None:
        inpShape = np.array(imgShift2.shape[:2])
        coefXY = np.array(outShape, dtype=np.float)/inpShape
        ptsShift2[:, 0] *= coefXY[0]
        ptsShift2[:, 1] *= coefXY[1]
        imgShift2 = sktf.resize(imgShift2, output_shape=outShape, preserve_range=True).astype(imgShift2.dtype)
    #
    if isDebug:
        plt.subplot(2, 2, 1)
        plt.imshow(pimg)
        plt.plot(arrPts[:,0], arrPts[:,1], 'o')
        plt.subplot(2, 2, 2)
        plt.imshow(imgShift1)
        plt.plot(ptsShift1[:,0], ptsShift1[:,1], 'o')
        plt.subplot(2, 2, 3)
        plt.imshow(imgRot1)
        plt.plot(ptsRot1[:, 0], ptsRot1[:, 1], 'o')
        plt.subplot(2, 2, 4)
        plt.imshow(imgShift2)
        plt.plot(ptsShift2[:, 0], ptsShift2[:, 1], 'o')
        plt.show()
    return (imgShift2, ptsShift2)
