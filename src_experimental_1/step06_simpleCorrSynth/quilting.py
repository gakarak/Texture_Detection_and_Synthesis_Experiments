#!/usr/bin/python
__author__ = 'pisarik'

import os
import glob
import sys

import skimage.io as skio

import cv2
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as patches

##########################################

def shortestPath(errors, is_vertical = True):

	used = []
	length = np.zeros(errors.shape, dtype = errors.dtype)
	length[0] = errors[0]
	pred_j = -np.ones(errors.shape, dtype = np.int)
	
	for i in range(1, errors.shape[0]):
		for j in range(errors.shape[1]):
			prev_pts = [j]
			if (j != 0):
				prev_pts.append(j-1)
			if (j != errors.shape[1] - 1):
				prev_pts.append(j+1)
			
			length[i, j] = length[i-1, j] + np.min(errors[i-1, prev_pts])
			pred_j[i, j] = prev_pts[ np.argmin(errors[i-1, prev_pts]) ]

	# with_path = quilled.copy()
	# with_path[path[:,0], path[:, 1]] = with_path[path[:,0], path[:, 1]]*0.7 + 0.3*np.repeat([[255, 0, 0]], path.shape[0], axis=0)
	# plt.imshow(with_path)
	# plt.show()

	# reconstruct path
	cur_j = np.argmin(length[-1,:])
	path = [(length.shape[0] - 1, cur_j)]
	for i in range(pred_j.shape[0] - 1, 0, -1):
		cur_j = pred_j[i, cur_j]
		path += [ [i-1, cur_j] ]

	return np.array(path, dtype=np.int)

def quilting(left_region, right_region, is_vertical = True):
	"""
	performs quilling on two equal-shape regions of image which intersects
		is_vertical - direction of quilling
	"""

	if (left_region.shape != right_region.shape):
		return None

	if (not is_vertical):
		return quilting(left_region.transpose(1, 0, 2), 
										right_region.transpose(1, 0, 2)).transpose(1, 0, 2)

	errors = np.linalg.norm(left_region - right_region, ord=2, axis=2)
	
	path = shortestPath(errors, is_vertical)

	result = left_region.copy()
	for i in range(path.shape[0]):
		result[path[i, 0], path[i, 1]:] = right_region[path[i, 0], path[i, 1]:]

	return result


##########################################
if __name__ == '__main__':
	texture_class = 'wild'
	fidx = '../../data/data04_for_test1_results_v1/%s/cropped_and_results/idx.txt' % texture_class
	
	wdir = os.path.dirname(fidx)
	with open(fidx, 'r') as f:
		lstIdx = f.read().splitlines()
	numImg = len(lstIdx)

	if numImg<1:
		raise Exception('Cant find image Idxs in file [%s]' % fidx)
	
	lstPathImg = [os.path.join(wdir, '%s.jpg' % ii) for ii in lstIdx]

	img = skio.imread(os.path.join(wdir, '%s_texton.jpg') % lstIdx[0])

	shift_x = 88
	shift_y = 7
	size = img.shape[0] - shift_x;
	left = img[:, :size]
	right = img[:, -size:]
	right = np.roll(right, -shift_y, axis = 0) #cyclic vertical shift 

	quilled = quilting(left, right, True)

	plt.subplot(1, 3, 1)
	plt.imshow(left)
	plt.subplot(1, 3, 2)
	plt.imshow(quilled)
	plt.subplot(1, 3, 3)
	plt.imshow(right)
	plt.show()