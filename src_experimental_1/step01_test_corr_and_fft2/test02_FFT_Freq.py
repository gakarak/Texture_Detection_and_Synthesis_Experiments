#!/usr/bin/python
# -*- coding: utf-8 -*-
__author__ = 'ar'

import numpy as np
import matplotlib.pyplot as plt

if __name__ == '__main__':
    xx = np.zeros(5)
    xx[-1]=1.
    yy=np.array([])
    for ii in range(7):
        yy = np.concatenate((yy, xx.copy()))
    #
    yyFFT = np.abs(np.fft.fft(yy))
    yyFrq = np.fft.fftfreq(yyFFT.size, 1./yyFFT.size)
    #
    plt.subplot(3, 1, 1)
    plt.plot(yy)
    plt.subplot(3, 1, 2)
    plt.plot(yyFFT), plt.title('Size: %s' % yyFFT.size)
    plt.subplot(3, 1, 3)
    plt.plot(yyFrq)
    plt.show()