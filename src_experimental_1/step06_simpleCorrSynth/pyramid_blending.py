#!/usr/bin/python
__author__ = 'pisarik'

import os

import skimage.io as skio

import cv2
import numpy as np
import matplotlib.pyplot as plt
import math

def pyramidBlending(left_region, right_region, is_vertical = True, is_debug = False):
  """
  performs pyramid blending on two equal-shape regions of image which intersects
    left_region - is also top region for horizontal pyramid blending
    right_region - is also bottom region for horizontal pyramid blending
    is_vertical - direction of blending

  ### code from http://opencv-python-tutroals.readthedocs.io/en/latest/py_tutorials/py_imgproc/py_pyramids/py_pyramids.html
  """

  if (not is_vertical):
    return pyramidBlending(left_region.transpose(1, 0, 2), 
                           right_region.transpose(1, 0, 2), 
                           is_debug = is_debug).transpose(1, 0, 2)
  # calculate pyramid levels count
  PYRAMID_LEVELS = math.floor(math.log(min(left_region.shape[:2]), 2))

  # generate Gaussian pyramid for left_region
  G = left_region.copy()
  gpA = [G]
  for i in range(PYRAMID_LEVELS):
      G = cv2.pyrDown(G)
      gpA.append(G)

  # generate Gaussian pyramid for right_region
  G = right_region.copy()
  gpB = [G]
  for i in range(PYRAMID_LEVELS):
      G = cv2.pyrDown(G)
      gpB.append(G)

  # generate Laplacian Pyramid for left_region
  lpA = [gpA[-1]]
  for i in range(len(gpA)-1,0,-1):
      GE = cv2.pyrUp(gpA[i])
      L = cv2.subtract(gpA[i-1],GE[:gpA[i-1].shape[0], :gpA[i-1].shape[1]])
      lpA.append(L)

  # generate Laplacian Pyramid for right_region
  lpB = [gpB[-1]]
  for i in range(len(gpB)-1,0,-1):
      GE = cv2.pyrUp(gpB[i])
      L = cv2.subtract(gpB[i-1],GE[:gpB[i-1].shape[0], :gpB[i-1].shape[1]])
      lpB.append(L)

  # Now add left and right halves of images in each level
  LS = []
  for la,lb in zip(lpA,lpB):
      rows,cols,dpt = la.shape
      ls = np.hstack((la[:,0:cols/2], lb[:,cols/2:]))
      LS.append(ls)

  # now reconstruct
  ls_ = LS[0]
  for i in range(1,len(LS)):
      ls_ = cv2.pyrUp(ls_)
      ls_ = cv2.add(ls_[:LS[i].shape[0],:LS[i].shape[1]], LS[i])

  return ls_

if __name__=='__main__':
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

  blended = pyramidBlending(left, right, True)
  print(blended.shape)
  print(left.shape)

  plt.subplot(1, 3, 1)
  plt.imshow(left)
  plt.subplot(1, 3, 2)
  plt.imshow(blended)
  plt.subplot(1, 3, 3)
  plt.imshow(right)
  plt.show()