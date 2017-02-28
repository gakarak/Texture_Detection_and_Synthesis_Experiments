function [warped_image, cNewMPT, warped_x_coords, warped_y_coords, cOriginalMPT] = fast_reg_tps_warp_thread(cMPT,cRegMPT,mOldGoodNode,mNewGoodNode,original_image, prev_x_coord_warps, prev_y_coord_warps,boundary)

%this function is a bit complicated because it is doing conversions between
%three different coordinate systems, and the transformations I use don't
%necessarily have inverses so things get messy.

%the three different coordinate systems are - the coordinates of the
%original image, the coordinates of the deformed image and lattice,
%and the coordinates of the regularized image and lattice (output).
%On the first iteration the original image and the deformed
%image are the same and thus their coordinates are the same.

%For these different coordinate systems I have several transformations.  I
%need the transformation from regularized image to deformed image in order
%to build the output, regularized image from the deformed input image.  I need the
%inverse of that transformation to move the deformed lattice
%points such that they correspond with the regularized image.  I know of no
%way to compute that inverse so we have to resort to search (or Newton's
%method) instead.  The transformation from deformed to regular coordinates
%is used to initialize this search.  The transformations from regular to
%deformed are aggregated every iteration into a warp from regular to
%original image.

%the spline code is directly derived from the regularized thin plate spline used
%by Serge Belongie in his shape contexts work.

fprintf('\nPerforming regularized thin-plate spline warp on image\n');

t0 = clock;
[mh,mw]=size(mOldGoodNode);
num_peaks = mh*mw; %only consider peaks that are part of the maximum connected component.  Only they have corresponding regular peaks
num_good_peaks = 1;

dist_coords = zeros(num_good_peaks, 2);
reg_coords = zeros(num_good_peaks, 2);

%compress the non mcc peaks out of here.
%need to be able to invert this operation at the end of this function.
current_index = 0;
[ih,iw,c]=size(original_image);
num_good_peaks=0;
Upt=[];
Xpt=[];

idx=find(mOldGoodNode>0);
len=length(idx);
if len>100
    if rand(1,1)>0.5
        sx=1;
        sy=2;
    else
        sx=2;
        sy=1;
    end
    if len>300
        step=3;
    else
        step=2;
    end
else
    step=1;
    sx=1;
    sy=1;
end

for yy=sy:step:mh
    for xx=sx:step:mw
        if mOldGoodNode(yy,xx)>0
            pt=cMPT{yy,xx};
            %if pt(1)>boundary && pt(1) <=iw-boundary && pt(2) >boundary && pt(2) <=ih-boundary
            current_index = current_index + 1;
            num_good_peaks=num_good_peaks+1;
            dist_coords(current_index,:) =cMPT{yy,xx}';
            reg_coords(current_index,:) = cRegMPT{yy,xx}';
            %end
        end
    end
end

for yy=1:mh
    for xx=1:mw
        if mNewGoodNode(yy,xx)>0
            pt=cMPT{yy,xx};
            %if pt(1)>boundary && pt(1) <=iw-boundary && pt(2) >boundary && pt(2) <=ih-boundary
            current_index = current_index + 1;
            num_good_peaks=num_good_peaks+1;
            dist_coords(current_index,:) =cMPT{yy,xx}';
            reg_coords(current_index,:) = cRegMPT{yy,xx}';
            %end
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% estimate regularized TPS transformation
% are the forward and inverse warps misnamed?
image_size = [size(original_image,1) size(original_image,2)];
% beta_k = .1 * (image_size(1)/2 + image_size(2)/2)^2 %play with this  higher = more affine.  range 0 to inf?
beta_k = 1000;


%reg_coords=reg_coords;        %points index compatible to CPP
%dist_coords=dist_coords;
reg_coords=reg_coords-1;
dist_coords=dist_coords-1;
prev_x_coord_warps=prev_x_coord_warps-1;
prev_y_coord_warps=prev_y_coord_warps-1;
tic
[cx  ,cy  ,E] = bookstein(reg_coords , dist_coords, beta_k);  %regular to distorted coordinates
toc
if ismac
    tic
    [descent_new_coords,warped_x_coords,warped_y_coords,imr]=OSX_InverseTPSThread(cx,cy,reg_coords(:,1),reg_coords(:,2),dist_coords(:,1),dist_coords(:,2),prev_x_coord_warps,prev_y_coord_warps,original_image);
    toc
    clear OSX_InverseTPSThread;
else
    tic
    [descent_new_coords,warped_x_coords,warped_y_coords,imr]=InverseTPSThread(cx,cy,reg_coords(:,1),reg_coords(:,2),dist_coords(:,1),dist_coords(:,2),prev_x_coord_warps,prev_y_coord_warps,original_image);
    toc
    clear InverseTPS;
end

reg_coords=reg_coords+1;
dist_coords=dist_coords+1;
descent_new_coords=descent_new_coords+1;
warped_x_coords=warped_x_coords+1;
warped_y_coords=warped_y_coords+1;
prev_x_coord_warps=prev_x_coord_warps+1;
prev_y_coord_warps=prev_y_coord_warps+1;

%reg_coords=reg_coords+1;%points index compatible to MATLAB
%dist_coords=dist_coords+1;
warped_image=original_image;
clear original_image;
warped_image=imr;

all_new_coords = zeros(num_peaks,2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%we need to re-expand the lattice coordinates.  We compressed
%them to take out the non-mcc ones earlier.
current_index = 0;
cNewMPT=cMPT;
for yy=sy:step:mh
    for xx=sx:step:mw
        if mOldGoodNode(yy,xx)>0
            pt=cMPT{yy,xx};
            %if pt(1)>boundary && pt(1) <=iw-boundary && pt(2) >boundary && pt(2) <=ih-boundary
            
            current_index = current_index + 1;
            cNewMPT{yy,xx}=descent_new_coords(current_index,:)';
            %end
        end
    end
end


for yy=1:mh
    for xx=1:mw
        if mNewGoodNode(yy,xx)>0
            pt=cMPT{yy,xx};
            %if pt(1)>boundary && pt(1) <=iw-boundary && pt(2) >boundary && pt(2) <=ih-boundary
            current_index = current_index + 1;
            cNewMPT{yy,xx}=descent_new_coords(current_index,:)';
            %end
        end
    end
end


clear descent_new_coords;
clear prev_x_coord_warps;
clear prev_y_coord_warps;

%original_lattice_coords = zeros(num_peaks,2);
cOriginalMPT=cMPT;
for yy=1:mh
    for xx=1:mw
        cOriginalMPT{yy,xx}(1) = MyInterp2D(warped_x_coords,cNewMPT{yy,xx}(1), cNewMPT{yy,xx}(2));
        cOriginalMPT{yy,xx}(2) = MyInterp2D(warped_y_coords,cNewMPT{yy,xx}(1), cNewMPT{yy,xx}(2));
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%we need to re-expand the lattice coordinates.  We compressed
%them to take out the non-mcc ones earlier.
%current_index = 0;
%cOriginalMPT=cMPT;
%for yy=1:mh
%    for xx=1:mw
%        current_index=current_index +1;
%        cOriginalMPT{yy,xx} = original_lattice_coords(current_index,:)';
%%    end
%end

fprintf(' %.2f seconds elapsed \n', etime(clock,t0));

function ret=MyInterp2D(mapping,x,y)
[h,w]=size(mapping);
if x<=0 ||x>w ||y<=0 || y>h
    ret=-10;
    return;
end
xlow=floor(x);
xhigh=ceil(x);
ylow=floor(y);
yhigh=ceil(y);
val_ll=mapping(ylow,xlow);
val_lh=mapping(ylow,xhigh);
val_hh=mapping(yhigh,xhigh);
val_hl=mapping(yhigh,xlow);


diffx=abs(x-xlow);
diffy=abs(y-ylow);
ly_val=(1-diffx)*val_ll+diffx*val_lh;
hy_val=(1-diffx)*val_hl+diffx*val_hh;
ret= (ly_val*(1-diffy)+hy_val*diffy);
