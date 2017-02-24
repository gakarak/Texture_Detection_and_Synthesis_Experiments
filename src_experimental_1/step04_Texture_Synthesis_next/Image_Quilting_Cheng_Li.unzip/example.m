close all;
clear all;

fimg = 'yogurt.bmp';

% % fimg = '/home/ar/dev-git.git/dev.python/PRJ_DATAMOLA/data/shirts.unzip_textures/128x128_4a475f6e305a6e6a36466b736c57456a.png';
% % fimg = '/home/ar/dev-git.git/dev.python/PRJ_DATAMOLA/data/shirts.unzip_textures/64x64_4a475f6e305a6e6a36466b736c57456a.png';
texture = imread(fimg);

% % figure;

figure('units','normalized','outerposition',[0 0 1 1]);

lstSizes=[8, 16, 24, 32, 64];
numSizes=numel(lstSizes);

outsize = size(texture)*3;
% % tilesize = 12;

subplot(2,3, 1);
imshow(texture), title( sprintf('Texture (%dx%d)', size(texture,1), size(texture,2) ));
drawnow;

for ii=1:numSizes
    tilesize = lstSizes(ii);
    overlapsize = 3;
    isdebug = 0;

    t2 = synthesize(texture,   outsize , tilesize, overlapsize,isdebug);
    subplot(2, 3, ii+1)
    imshow(uint8(t2)), title(sprintf('size= %dx%d', tilesize, tilesize));
    drawnow;
end
