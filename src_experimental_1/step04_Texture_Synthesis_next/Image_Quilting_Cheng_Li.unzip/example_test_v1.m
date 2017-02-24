close all;
clear all;

% % fimg = 'yogurt.bmp';
fimg = '/home/ar/dev-git.git/dev.python/PRJ_DATAMOLA/data/shirts.unzip_textures/128x128_4a475f6e305a6e6a36466b736c57456a.png';
% % fimg = '/home/ar/dev-git.git/dev.python/PRJ_DATAMOLA/data/shirts.unzip_textures/64x64_4a475f6e305a6e6a36466b736c57456a.png';

% % fimg = '/home/ar/dev-git.git/dev.python/PRJ_DATAMOLA/data01_ex_periodic_textures/bricks1.jpg';
% % fimg = '/home/ar/dev-git.git/dev.python/PRJ_DATAMOLA/data01_ex_periodic_textures/bricks2.jpg';
% % fimg='/home/ar/dev-git.git/dev.python/PRJ_DATAMOLA/data01_ex_periodic_textures/cube_pattern1.png';
% % fimg='/home/ar/dev-git.git/dev.python/PRJ_DATAMOLA/data01_ex_periodic_textures/lattice2.png';

texture = imread(fimg);

% % figure('units','normalized','outerposition',[0 0 1 1]);

isdebug=false;

drawnow;
imgCrop = imcrop(texture);
% % imgCrop = imresize(imgCrop, [128,128]);

outsize0= size(imgCrop)*5;
outsize = [max(outsize0), max(outsize0)];

sizCrop = size(imgCrop);
sizCrop = sizCrop(1:2);
tileSiz     = floor(0.9*sizCrop);
overlapsize = min(floor(0.05*sizCrop));
if overlapsize<2
    overlapsize = 2;
end
% % overlapsize=3;

t2 = synthesize(imgCrop, outsize , min(tileSiz), overlapsize, isdebug);

figure,
subplot(1,3,1),
imshow(texture), title( sprintf('Texture (%dx%d)', size(texture,1), size(texture,2) ));
subplot(1,3,2),
imshow(imgCrop), title( sprintf('Crop: %dx%d', tileSiz(1), tileSiz(2)) );
subplot(1,3,3),
imshow(uint8(t2)), title( sprintf('SYN: %dx%d, overlap=%d', size(t2,1), size(t2,2), overlapsize));
