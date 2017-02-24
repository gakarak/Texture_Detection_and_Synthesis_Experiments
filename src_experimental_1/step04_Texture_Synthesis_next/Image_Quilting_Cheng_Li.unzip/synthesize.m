function [imout] = synthesize(imin, sizeout, tilesize, overlap ,  isdebug)
% Matlab code to do Image Quilting as presented in the SIGGRAPH 2002 paper by Efros & Freeman.
% 
% Note: this isn't Efros & Freeman's code, just my implementation of it. 
%
% Texture Synthesize
%     IMOUT = SYNTHESIZE(IMGIN , SIZEOUT, TILESIZE, OVERLAP [, ISDEBUG]) 
%                      returns an image that is Texture Synthesized
%    
%     IMGIN  
%           the code both works on grascale images or color images
%
%     SIZEOUT
%           An 1*2 array , the size of output image
%           e.g.   size(texture)*3
%           
%     TILESIZE
%           TILESIZE of each block
%
%     OVERLAP
%           size of overlap bar between blocks 
%
%     ISDEBUG
%           equals 0 (default) if no debug function
%           the algorithm will shows progress of each step, a little more
%           time will be cost in plotting.
%
%       A little confuse I meet with when the block overlaped with two
%      block, I solved it with a simple way.
%       licheng09@mails.tsinghua.edu.cn


imin = double(imin);

if(size(imin,3) ==1)
    imout = zeros(sizeout);
else
    imout = zeros([sizeout(1:2) size(imin,3)]);
end
imout(1,1,:)=255;


if nargin<5
    isdebug = 0;
end

if isdebug~=0
    h = imshow(uint8(imout));
else
    isdebug = floor(isdebug);
end



sizein = size(imin);
sizein = sizein(1:2);

temp = ones([overlap tilesize]);
errtop = getxcorr2(imin.^2, temp);
temp = ones([tilesize overlap]);
errside = getxcorr2(imin.^2, temp);
temp = ones([tilesize-overlap overlap]);
errsidesmall = getxcorr2(imin.^2, temp);

%B1overlap = zeros(overlap,tilesize);
%B2overlap = zeros(overlap,tilesize);



for i=1:tilesize-overlap:sizeout(1)-tilesize+1,
  for j=1:tilesize-overlap:sizeout(2)-tilesize+1,

    if (i > 1) & (j > 1),
    % extract top shared region
      shared = imout(i:i+overlap-1,j:j+tilesize-1,:);
      err = errtop - 2 * getxcorr2(imin, shared) + sum(shared(:).^2);
      
      % trim invalid data at edges, and off bottom where we don't want
      % tiles to go over the edge
      err = err(overlap:end-tilesize+1,tilesize:end-tilesize+1);

      % extract left shared region, skipping bit already checked
      shared = imout(i+overlap:i+tilesize-1,j:j+overlap-1,:);
      err2 = errsidesmall - 2 * getxcorr2(imin, shared) + sum(shared(:).^2);
      % sum(shared(:).^2); trim invalid data at edges, and where we
      % don't want tiles to go over the edges
      err = err + err2(tilesize:end-tilesize+overlap+1, overlap:end-tilesize+1);

      [ibest, jbest] = find(err <= 1.1*1.01*min(err(:)));
      c = ceil(rand * length(ibest));
      pos = [ibest(c) jbest(c)];
      
      
          B1overlaph = imout(i:i+overlap-1,j:j+tilesize-1,:); % shared
          B2overlaph = imin(pos(1):pos(1)+overlap-1,pos(2):pos(2)+tilesize-1,:);

          errmat = sum((B1overlaph-B2overlaph).^2,3);

          fph = zeros(overlap,tilesize);
          pathh = zeros(overlap,tilesize);

          fph(:,tilesize) = errmat(:,tilesize);

          for k = tilesize-1:-1:1
              for l = 1:overlap
                  index =  max(1,l-1):min(overlap,l+1);
                  [fph(l,k), temp_index] = min( fph(index,k+1));
                  fph(l,k) = fph(l,k) + errmat(l,k);
                  pathh(l,k) = index(temp_index);
              end
          end
          
          B1overlap = imout(i:i+tilesize-1,j:j+overlap-1,:); % shared
          B2overlap = imin(pos(1):pos(1)+tilesize-1,pos(2):pos(2)+overlap-1,:);

          errmat = sum((B1overlap-B2overlap).^2,3);

          fp = zeros(tilesize,overlap);
          path = zeros(tilesize,overlap);

          fp(tilesize,:) = errmat(tilesize,:);

          for k = tilesize-1:-1:1
              for l = 1:overlap
                  index =  max(1,l-1):min(overlap,l+1);
                  [fp(k,l), temp_index] = min( fp(k+1,index));
                  fp(k,l) = fp(k,l) + errmat(k,l);
                  path(k,l) = index(temp_index);
              end
          end
          
          allerr = fp(1:overlap,1:overlap) + fph(1:overlap,1:overlap);
          
          [tempmin,tempindminclom] = min(allerr);
          [temp, min_bound_indexj] = min(tempmin);
          min_bound_indexi = tempindminclom(min_bound_indexj);
          
          imout(i+ overlap : i+tilesize-1,j + overlap : j+ tilesize-1,:) = ...
              imin(pos(1)+overlap :pos(1)+tilesize-1,pos(2)+overlap :pos(2)+tilesize-1,:);
          
          
      
          %imout(i:i+tilesize-1,j:j+tilesize-1) = imin(pos(1):pos(1)+tilesize-1,pos(2):pos(2)+tilesize-1);
          
          min_err_bound = zeros(1,tilesize);
          min_err_boundh = zeros(1,tilesize);
      
          min_err_bound(min_bound_indexi) = min_bound_indexj;
          min_err_boundh(min_bound_indexj) = min_bound_indexi;
      
          for k=min_bound_indexi+1 :tilesize
              min_err_bound(k) = path(k-1,min_err_bound(k-1));
          end
          
          for k=min_bound_indexj+1 :tilesize
              min_err_boundh(k) = pathh(min_err_boundh(k-1),k-1);
          end
          
          for k = overlap : tilesize
            imout(i+min_err_boundh(k):i+overlap-1,j+k-1,:) = imin(pos(1)+min_err_boundh(k):pos(1)+overlap-1,pos(2)+k-1,:);
          end
          
          for k = overlap:tilesize
            imout(i+k-1,j+min_err_bound(k):j+overlap-1,:) = imin(pos(1)+k-1,pos(2)+min_err_bound(k):pos(2)+overlap-1,:);
          end
          
          
          for k = min_bound_indexi:overlap-1
              for l = min_bound_indexj:overlap-1
                  if k>=min_err_boundh(l) && l>= min_err_bound(k)
                      imout(i+k,j+l,:) = imin(pos(1)+k,pos(2)+l,:);
                  end
              end
          end
           
    elseif i > 1
      shared = imout(i:i+overlap-1,j:j+tilesize-1,:);
      err = errtop - 2 * getxcorr2(imin, shared) + sum(shared(:).^2);
      
      % trim invalid data at edges
      err = err(overlap:end-tilesize+1,tilesize:end-tilesize+1,:);

      [ibest, jbest] = find(err <= 1.01*1.1*min(err(:)));
      c = ceil(rand * length(ibest));
      pos = [ibest(c) jbest(c)];
      imout(i:i+tilesize-1,j:j+tilesize-1,:) = imin(pos(1):pos(1)+tilesize-1,pos(2):pos(2)+tilesize-1,:);
      
      
      B1overlaph = imout(i:i+overlap-1,j:j+tilesize-1,:); % shared
      B2overlaph = imin(pos(1):pos(1)+overlap-1,pos(2):pos(2)+tilesize-1,:);
      
      errmat = sum((B1overlaph-B2overlaph).^2,3);
      
      fph = zeros(overlap,tilesize);
      pathh = zeros(overlap,tilesize);
      
      fph(:,tilesize) = errmat(:,tilesize);
      
      for k = tilesize-1:-1:1
          for l = 1:overlap
              index =  max(1,l-1):min(overlap,l+1);
              [fph(l,k), temp_index] = min( fph(index,k+1));
              fph(l,k) = fph(l,k) + errmat(l,k);
              pathh(l,k) = index(temp_index);
          end
      end
      
      min_err_boundh = zeros(1,tilesize);
      
      [temp,min_err_boundh(1)] = min(fph(1,:));
      
      for k=2:tilesize
          min_err_boundh(k) = pathh(min_err_boundh(k-1),k-1);
      end
      
      for k = 1:tilesize
          imout(i+min_err_boundh(k):i+tilesize-1,j+k-1,:) = imin(pos(1)+min_err_boundh(k):pos(1)+tilesize-1,pos(2)+k-1,:);
      end
      
      
      
      
    elseif j > 1
      shared = imout(i:i+tilesize-1,j:j+overlap-1,:);
      err = errside - 2 * getxcorr2(imin, shared) + sum(shared(:).^2);
      
      % trim invalid data at edges
      err = err(tilesize:end-tilesize+1,overlap:end-tilesize+1);

      [ibest, jbest] = find(err <= 1.01*1.1*min(err(:)));
      c = ceil(rand * length(ibest));
      pos = [ibest(c) jbest(c)];
      
      B1overlap = imout(i:i+tilesize-1,j:j+overlap-1,:); % shared
      B2overlap = imin(pos(1):pos(1)+tilesize-1,pos(2):pos(2)+overlap-1,:);
      
      errmat = sum((B1overlap-B2overlap).^2,3);
      
      fp = zeros(tilesize,overlap);
      path = zeros(tilesize,overlap);
      
      fp(tilesize,:) = errmat(tilesize,:);
      
      for k = tilesize-1:-1:1
          for l = 1:overlap
              index =  max(1,l-1):min(overlap,l+1);
              [fp(k,l), temp_index] = min( fp(k+1,index));
              fp(k,l) = fp(k,l) + errmat(k,l);
              path(k,l) = index(temp_index);
          end
      end
      
      min_err_bound = zeros(1,tilesize);
      
      [temp,min_err_bound(1)] = min(fp(1,:));
      
      for k=2:tilesize
          min_err_bound(k) = path(k-1,min_err_bound(k-1));
      end
      
      for k = 1:tilesize
          imout(i+k-1,j+min_err_bound(k):j+tilesize-1,:) = imin(pos(1)+k-1,pos(2)+min_err_bound(k):pos(2)+tilesize-1,:);
      end
      
      %imout(i:i+tilesize-1,j:j+tilesize-1) = imin(pos(1):pos(1)+tilesize-1,pos(2):pos(2)+tilesize-1);
    else
      pos = ceil(rand([1 2]) .* (sizein-tilesize+1));
      imout(i:i+tilesize-1,j:j+tilesize-1,:) = imin(pos(1):pos(1)+tilesize-1,pos(2):pos(2)+tilesize-1,:);
    end



    if isdebug~=0
        set(h,'CData',uint8(imout));
        drawnow;
    end
  end
end
