% 
% mex -c MexAndCpp.cpp
% mex -c MatlabToOpenCV.cpp
% mex  OSX_CPPRansacToGetAffineClosestN.cpp MexAndCpp.o MatlabToOpenCV.o /Users/opencv/libcv.dylib /Users/opencv/libhighgui.dylib /Users/opencv/libcxcore.dylib
% 
% mex  OSX_BlockWiseKLTPropose.cpp MexAndCpp.o MatlabToOpenCV.o /Users/opencv/libcv.dylib /Users/opencv/libhighgui.dylib /Users/opencv/libcxcore.dylib
% 
% mex OSX_CPPMeanShiftCluster.cpp MexAndCpp.o
% 
% mex OSX_InverseTPSThread.cpp MexAndCpp.o MatlabToOpenCV.o /Users/opencv/libcv.dylib /Users/opencv/libhighgui.dylib /Users/opencv/libcxcore.dylib
% 
% mex OSX_MSBPLocalAlignByPass.cpp
% 
% mex OSX_TemplateMatching.cpp MexAndCpp.o MatlabToOpenCV.o /Users/opencv/libcv.dylib /Users/opencv/libhighgui.dylib /Users/opencv/libcxcore.dylib



mex -c MexAndCpp.cpp
mex -c MatlabToOpenCV.cpp
%mex  OSX_CPPRansacToGetAffineClosestN.cpp MexAndCpp.o MatlabToOpenCV.o /Users/opencv/libcv.dylib /Users/opencv/libhighgui.dylib /Users/opencv/libcxcore.dylib


mex  OSX_CPPRansacToGetAffineClosestN.cpp MexAndCpp.obj MatlabToOpenCV.obj MexAndCpp.obj MatlabToOpenCV.obj cv200.lib cvaux200.lib cxcore200.lib highgui200.lib ml200.lib

mex  OSX_BlockWiseKLTPropose.cpp MexAndCpp.obj MatlabToOpenCV.obj MexAndCpp.obj MatlabToOpenCV.obj cv200.lib cvaux200.lib cxcore200.lib highgui200.lib ml200.lib

mex OSX_CPPMeanShiftCluster.cpp MexAndCpp.obj

mex Win_InverseTPSThread.cpp MexAndCpp.obj MatlabToOpenCV.obj MexAndCpp.obj MatlabToOpenCV.obj cv200.lib cvaux200.lib cxcore200.lib highgui200.lib ml200.lib

mex OSX_MSBPLocalAlignByPass.cpp

mex OSX_TemplateMatching.cpp MexAndCpp.obj MatlabToOpenCV.obj MexAndCpp.obj MatlabToOpenCV.obj cv200.lib cvaux200.lib cxcore200.lib highgui200.lib ml200.lib

%mex  OSX_BlockWiseKLTPropose.cpp MexAndCpp.obj MatlabToOpenCV.obj opencv_calib3d242.lib opencv_contrib242.lib opencv_core242.lib opencv_features2d242.lib opencv_flann242.lib opencv_gpu242.lib opencv_haartraining_engine.lib opencv_highgui242.lib opencv_imgproc242.lib opencv_legacy242.lib opencv_ml242.lib opencv_nonfree242.lib opencv_objdetect242.lib opencv_photo242.lib opencv_stitching242.lib opencv_ts242.lib opencv_video242.lib opencv_videostab242.lib  
mex  OSX_BlockWiseKLTPropose.cpp MexAndCpp.obj MatlabToOpenCV.obj cv200.lib cvaux200.lib cxcore200.lib highgui200.lib ml200.lib