#!/usr/bin/python
# -*- coding: utf-8 -*-
__author__ = 'ar'

import os
import glob
import sys

import skimage.io as skio

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

def generateTiledTextureV1(texton, dRightY, dBottomX, nr=5, nc=5):
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

def generateTiledTextureV2(textonBRD, posXY_RT, posXY_LB, nr=5, nc=5, isDebug=False):
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

def readGrid(pdir, shirt_num):
	wdir = '%s/%s_result/' % (pdir, shirt_num )
	v_x = np.loadtxt(wdir+'pts_x.csv', delimiter=',') - 100 - 1 #FIXME: shift in 100px is automaticaly added by Texture Extraction Algorithm
	v_y = np.loadtxt(wdir+'pts_y.csv', delimiter=',') - 100 - 1
	is_good = np.loadtxt(wdir+'is_good.csv', dtype='bool', delimiter=',')
	return [v_x, v_y, is_good]

##########################################
def maskErosion(mask, percent_of_src = 0.4, min_square = 10):
	"""
		percent_of_src - result square is about percent_of_src of source square
	"""
	eroded_mask = mask.copy()
	
	min_square = max(percent_of_src*np.sum(mask), min_square)
	while np.sum(eroded_mask) > min_square:
		eroded_mask = binary_erosion(eroded_mask)

	return eroded_mask

def getTextonBBox(vx, vy, row, col, sizN=1):
	X = []
	Y = []
	X += [vx[(row + 0   , col + 0)]]
	X += [vx[(row + sizN, col + 0)]]
	X += [vx[(row + 0   , col + sizN)]]
	X += [vx[(row + sizN, col + sizN)]]
	#print(X)
	Y += [vy[(row + 0   , col + 0)]]
	Y += [vy[(row + sizN, col + 0)]]
	Y += [vy[(row + 0   , col + sizN)]]
	Y += [vy[(row + sizN, col + sizN)]]
	#print(Y)
	min_x = min(X)
	max_x = max(X)
	min_y = min(Y)
	max_y = max(Y)
	# bbox = np.array([[min_y, min_x], [max_y, max_x]])
	bbox = np.array([[min_x, max_x], [min_y, max_y]])
	bbox = np.round(bbox)
	
	return bbox


def getRandomTextonBBox(vx, vy, mask, sizN=1):
	rows, cols = np.where(mask)
	idxRnd = np.random.randint(len(rows))

	print ('pos = (%d, %d)' % (rows[idxRnd], cols[idxRnd]))

	return getTextonBBox(vx, vy, rows[idxRnd], cols[idxRnd], sizN)

def getBestTextonBBox(img, vx, vy, mask, sizN=1, parMethod = cv2.TM_SQDIFF, bbox_scale = None):
	maxCorr = -10000500000
	posRT = (0, 0)
	posLB = (0, 0)
	bestBBox = None

	good_idx = np.transpose(np.where(mask))
	for i, j in good_idx:
		if (i + sizN >= mask.shape[0] or j + sizN >= mask.shape[1]):
			continue

		bbox = getTextonBBox(vx, vy, i, j, sizN)
		if bbox_scale:
			bbox = bbox * bbox_scale

		bbW = np.abs(bbox[0][0] - bbox[0][1])
		bbH = np.abs(bbox[1][0] - bbox[1][1])
		parBorder = int(min(bbH,bbW) * 0.15)
		# parBorder = 5
		#print(bbox)
		#print ('Border parameter: %s' % parBorder)
		#
		texton = cropTexton(img, bbox, brdPx=parBorder, brdPrcnt=None)

		if (texton.shape[0] < bbH or texton.shape[1] < bbW):
			continue;

		ptrnSize = parBorder+2
		brdSizeExt = int(1.7*parBorder)
		ptrnLef = texton[ptrnSize:-ptrnSize, :ptrnSize]
		ptrnTop = texton[:ptrnSize, ptrnSize:-ptrnSize]

		# plt.imshow(texton)
		# plt.show()

		ccMapH = cv2.matchTemplate(texton, ptrnLef, method=parMethod)
		ccMapV = cv2.matchTemplate(texton, ptrnTop, method=parMethod)
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

		#print('Corr: ', maxVH + maxVV)
		if (maxCorr < maxVH + maxVV):
			#print('#############################################################')
			bestBBox = bbox
			shiftH_X, shiftH_Y = posMaxH
			shiftV_X, shiftV_Y = posMaxV
			posRT = (posMaxH[0], posMaxH[1] - 1*ptrnSize)
			posLB = (posMaxV[0] - 1*ptrnSize, posMaxV[1])
			maxCorr = maxVH + maxVV
			bestTexton = texton[:shiftV_Y, :shiftH_X]


	#print(posRT, posLB)
	#return (bestTexton, posRT, posLB)
	return bestBBox

##########################################
def getGoodGridPoints(vx,vy, mask):
	nr,nc = mask.shape
	lstXX = []
	lstYY = []
	for rr in range(nr):
		for cc in range(nc):
			if mask[rr,cc]:
				x0 = vx[rr, cc]
				y0 = vy[rr, cc]
				lstXX.append(x0)
				lstYY.append(y0)
	return np.array([lstXX,lstYY]).transpose()

def cropTexton(img, texBBox, brdPrcnt=0.1, brdPx=None):
	tsiz = np.array(img.shape[:2])
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
	if img.ndim<3:
		tret = img[ymin - dr:ymax + dr, xmin - dc:xmax + dc].copy()
	else:
		tret = img[max(ymin - dr, 0):min(ymax + dr, img.shape[0]), 
				   max(xmin - dc, 0):min(xmax + dc, img.shape[1]), :].copy()
	return tret

##########################################
if __name__ == '__main__':
	texture_class = 'w-texton'
	fidx = '../../data/data04_for_test1_results_v1/%s/idx.txt' % texture_class
	# fidx = '/home/ar/github.com/Texture_Detection_and_Synthesis_Experiments.git/data/data04_for_test1_results_v1/txt02_pxy_M/cropped_and_results/idx.txt'
	
	wdir = os.path.dirname(fidx)
	with open(fidx, 'r') as f:
		lstIdx = f.read().splitlines()
	numImg = len(lstIdx)

	if numImg<1:
		raise Exception('Cant find image Idxs in file [%s]' % fidx)
	
	lstPathImg = [os.path.join(wdir, '%s.png' % ii) for ii in lstIdx]
	
	for ii,pathImg in enumerate(lstPathImg):
		#if ii!=21:
		#      continue
		print ('[%d/%d] : %s' % (ii, numImg, pathImg))

		##### READ INPUT
		img_idx = lstIdx[ii]
		texton = np.array(skio.imread(pathImg))
		min_side = min(texton.shape[0], texton.shape[1])
		#texton = texton[:min_side, :min_side]

		##### PROCESS TEXTON
		# corr_texton = MinimizePatternByTemplMatchV1(texton)
		# corr_texton = MinimizePatternByTemplMatchV2(texton, brdSize=parBorder)
		# corr_texton, pdRightY, pdBottomX = MinimizePatternByTemplMatchV3(texton, brdSize=parBorder)
		parBorder = int(min_side*0.16)
		corr_texton, posRT, posLB = MinimizePatternByTemplMatchV3(texton, brdSize=parBorder)
		
		##### TILE TEXTON
		nrow_tile = 3
		ncol_tile = 3
		stupid_tiled_texture = np.tile(texton, (nrow_tile, ncol_tile, 1))
		corr_tiled_texture   = np.tile(corr_texton, (nrow_tile, ncol_tile, 1))
		generated_texture = generateTiledTextureV2(corr_texton, posRT, posLB, nrow_tile, ncol_tile)
		big_generated_texture = generateTiledTextureV2(corr_texton, posRT, posLB, 
								nrow_tile*nrow_tile, ncol_tile*ncol_tile)

		##### PLOT RESULTS
		mng = plt.get_current_fig_manager()
		plt.figure(figsize = (20, 10))

		tmpH = plt.subplot(2, 3, 1)
		plt.title('Texton')
		plt.imshow(texton)

		tmpH = plt.subplot(2, 3, 2)
		plt.title('Minimized texton')
		plt.imshow(corr_texton)

		plt.subplot(2, 3, 3)
		plt.title('Corr-Synth: arbitrary shifts(x2)')
		plt.imshow(big_generated_texture)
		#plt.imshow(np.dstack((mask, eroded_mask, mask)))


		plt.subplot(2, 3, 4)
		plt.title('Texture Synth: periodic tiling')
		plt.imshow(stupid_tiled_texture)

		plt.subplot(2, 3, 5)
		plt.title('Corr-Synth: horiz, vert shifts')
		plt.imshow(corr_tiled_texture)

		plt.subplot(2, 3, 6)
		plt.title('Corr-Synth: arbitrary shifts')
		plt.imshow(generated_texture)

		#mng.window.showMaximized()

		plt.savefig(os.path.join(wdir, '../report/%s_%s_result.jpg' % (texture_class, img_idx)), format='jpg')
		#skio.imwrite(os.path.join(wdir, '../../report/%s_%s_texture.png' % (texture_class, img_idx)), texton)
		#plt.show()

