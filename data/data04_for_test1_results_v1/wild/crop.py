#!/usr/bin/python
__author__ = 'pisarik'

import os
import glob
import sys

#import skimage.io as skio

import skimage.transform
import skimage.io as skio
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as patches

if __name__ == '__main__':
	save_dir = 'cropped'
	fidx = 'idx.txt'

	with open(fidx, 'r') as f:
		shirt_idx = f.read().splitlines()
	shirt_cnt = len(shirt_idx)

	shirt_names = ['%s.png' % ii for ii in shirt_idx]

	for name, idx in zip(shirt_names, shirt_idx):
		shirt = skio.imread(name)

		halfside = int(min(shirt.shape[0], shirt.shape[1]) * 0.7) // 2
		center = (shirt.shape[0] // 2, shirt.shape[1] // 2)

		print(center)
		print(halfside)

		cropped = shirt[center[0] - halfside: center[0] + halfside, 
						center[1] - halfside: center[1] + halfside]

		resized = cropped
		if (halfside > 250):
			resized = skimage.transform.resize(resized, (500, 500))

		skio.imsave(os.path.join(save_dir, '%s.jpg' % idx), resized)
		skio.imsave(os.path.join(save_dir, '%s_big.jpg' % idx), cropped)
		# plt.subplot(1, 3, 1)
		# plt.imshow(shirt)
		# plt.subplot(1, 3, 2)
		# plt.imshow(cropped)
		# plt.subplot(1, 3, 3)
		# plt.imshow(resized)
		# plt.show()

