function [pts]=C1_BWKLT(filepath,window,qual,ptNum,auto)
%filepath to the input image.
%window size for the KLT feature
%quality parameter for the KLT feature [for more info see openCV KLT
%feature]
%point number for each block
%automatic setting of quality parameter...
if ismac
    pts=OSX_BlockWiseKLTPropose(filepath,window,qual,ptNum,auto);
else
    pts=BlockWiseKLTPropose(filepath,window,qual,ptNum,auto);
end