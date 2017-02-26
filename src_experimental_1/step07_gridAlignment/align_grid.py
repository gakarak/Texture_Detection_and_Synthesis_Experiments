#!/usr/bin/env python
import matplotlib.pyplot as plt
import numpy as np
import cv2
import queue

from scipy.ndimage.morphology import binary_erosion
from scipy.interpolate import griddata

def readGrid(wdir, shirt_num):
    wdir = wdir + '/' + str(shirt_num) + '_result/'
    v_x = np.loadtxt(wdir+'pts_x.csv', delimiter=',') - 100 - 1
    v_y = np.loadtxt(wdir+'pts_y.csv', delimiter=',') - 100 - 1
    is_good = np.loadtxt(wdir+'is_good.csv', dtype='bool', delimiter=',')
    return [v_x, v_y, is_good]

def drawGrid(v_x, v_y, is_good, color = 'r'):
    for i, row in enumerate(v_x):
        for j, elem in enumerate(v_x[i]):
            if (i < v_x.shape[0] - 1):
                if (is_good[i, j] and is_good[i+1, j]):
                    plt.plot([v_x[i, j], v_x[i+1, j]],
                             [v_y[i, j], v_y[i+1, j]],
                             color, linewidth=1)

            if (j < v_x.shape[1] - 1):
                if (is_good[i, j] and is_good[i, j+1]):
                    plt.plot([v_x[i, j], v_x[i, j+1]],
                             [v_y[i, j], v_y[i, j+1]],
                             color, linewidth=1)

def extractMaximalRect(is_good):
    blob_is_good = is_good.copy()
    while np.sum(blob_is_good) > max(0.4*np.sum(is_good), 10):
        blob_is_good = binary_erosion(blob_is_good)

    return blob_is_good

def gatherTaoVectors(v_x, v_y, is_good):
    tx = []
    ty = []

    for i, row in enumerate(v_x):
        for j, elem in enumerate(v_x[i]):
            if (j < v_x.shape[1] - 1):
                if (is_good[i, j] and is_good[i, j+1]):
                    tx.append([v_x[i, j+1] - v_x[i, j], v_y[i, j+1] - v_y[i, j]])
                    
            if (i < v_x.shape[0] - 1):
                if (is_good[i, j] and is_good[i+1, j]):
                    ty.append([v_x[i+1, j] - v_x[i, j], v_y[i+1, j] - v_y[i, j]])
                    
    tx = np.array(tx) # [x, y]
    ty = np.array(ty) # [x, y]
    return [tx, ty]

def alignGrid(v_x, v_y, is_good, tx, ty):
    reg_v_x = np.empty_like(v_x)
    reg_v_x.fill(-1)
    reg_v_y = np.empty_like(v_y)
    reg_v_y.fill(-1)

    que = queue.Queue()

    blob_good_idx = np.transpose(np.where(is_good))
    start = blob_good_idx[blob_good_idx.shape[0]//2 - 1]

    reg_v_x[start[0], start[1]] = v_x[start[0], start[1]]
    reg_v_y[start[0], start[1]] = v_y[start[0], start[1]]
    que.put(start)

    while not que.empty():
        [i, j] = que.get()
        
        if (i > 0 and reg_v_x[i-1, j] == -1 and is_good[i-1, j]): # -ty, because i-1
            reg_v_x[i-1, j] = reg_v_x[i, j] - ty[0] 
            reg_v_y[i-1, j] = reg_v_y[i, j] - ty[1]
            que.put([i-1, j])
        if (i < is_good.shape[0] - 1 and reg_v_x[i+1, j] == -1 and is_good[i+1, j]): # +ty, because i+1
            reg_v_x[i+1, j] = reg_v_x[i, j] + ty[0] 
            reg_v_y[i+1, j] = reg_v_y[i, j] + ty[1]
            que.put([i+1, j])
        if (j > 0 and reg_v_x[i, j-1] == -1 and is_good[i, j-1]): # -tx, because j-1
            reg_v_x[i, j-1] = reg_v_x[i, j] - tx[0]
            reg_v_y[i, j-1] = reg_v_y[i, j] - tx[1]
            que.put([i, j-1])
        if (j < is_good.shape[1] - 1 and reg_v_x[i, j+1] == -1 and is_good[i, j+1]): # +tx, because j+1
            reg_v_x[i, j+1] = reg_v_x[i, j] + tx[0]
            reg_v_y[i, j+1] = reg_v_y[i, j] + tx[1]
            que.put([i, j+1])

    return [reg_v_x, reg_v_y]

def getBBoxOfGridInPixels(v_x, v_y, is_good):
    good_idx = np.transpose(np.where(is_good))

    X = v_x[is_good]
    Y = v_y[is_good]

    min_x = min(X)
    max_x = max(X)
    min_y = min(Y)
    max_y = max(Y)

    bbox = np.array([[min_x, min_y], [max_x, max_y]])
    bbox = np.round(bbox)

    return bbox.astype(np.int)

def interpolateShiftsForPixels(v_x, v_y, reg_v_x, reg_v_y, is_good):
    points = np.transpose( (v_x[is_good], v_y[is_good]) )
    dx = reg_v_x[is_good] - v_x[is_good]
    dy = reg_v_y[is_good] - v_y[is_good]

    bbox = getBBoxOfGridInPixels(v_x, v_y, is_good)
    grid_x, grid_y = np.mgrid[bbox[0, 0]:bbox[1, 0] + 1, bbox[0, 1]:bbox[1, 1] + 1]

    # .T, because x, y and i, j
    values_x = griddata(points, dx, (grid_x, grid_y), method='linear').T
    values_y = griddata(points, dy, (grid_x, grid_y), method='linear').T

    return [values_x, values_y, bbox]