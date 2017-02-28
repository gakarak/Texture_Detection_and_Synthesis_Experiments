%batchall

for f=1:120
    filename=sprintf('gb%.3d.jpg',f);
    pathname=sprintf('../ECCV2010_LatticeFeature/GBData/');
    PAMI09(filename,pathname);
 
end