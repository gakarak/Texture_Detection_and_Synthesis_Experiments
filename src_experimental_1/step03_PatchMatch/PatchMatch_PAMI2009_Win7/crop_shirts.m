close all;
clear all;

% crop shirts 180:480, 80:420, : for 480x480
% crop shirts 562:1500, 250:1312, : for 1500x1500
%wdir='D:/step03_PatchMatch/data_for_test1/txt01_pxy_S';
wdir='D:/step03_PatchMatch/data_for_test2/txt02_pxy_M';
%wdir='D:/step03_PatchMatch/data_for_test1/txt03_pxy_L';

lstImages = dir(sprintf('%s/*.jpg', wdir));
numImages=numel(lstImages);
for ii=1:numImages
    tfn = lstImages(ii).name;
    tpath = sprintf('%s/%s', wdir, tfn);
    timg = imread(tpath);
    timg = timg(562:1500, 250:1312, :);
    imwrite(timg, sprintf('%s/%s/%s', wdir, 'cropped', tfn));
% %     imshow(timg);
% %     drawnow;
end