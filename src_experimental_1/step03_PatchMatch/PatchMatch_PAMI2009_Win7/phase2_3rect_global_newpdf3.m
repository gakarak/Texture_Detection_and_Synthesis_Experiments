

function [rOriginalMPT,cRegMPT,mIsGood,mIsBoundary,boundary_width,bFail]=phase2_3rect_global_newpdf3(im,cProposalMPT,t1,t2,savepath,fname,markersize,trial)

maxit=3;
fileidx=4;
alpha=5;
beta=5;
ThGoodCnt=2;
boundary_width=400;
reverse_x_coord_warps = zeros(size(im,1) + 2*boundary_width, size(im,2) + 2*boundary_width, 0); %reg towards distorted
reverse_y_coord_warps = zeros(size(im,1) + 2*boundary_width, size(im,2) + 2*boundary_width, 0);
reverse_x_coord_warps=double(reverse_x_coord_warps);
reverse_y_coord_warps=double(reverse_y_coord_warps);


im=im2double(im);
[imgh,imgw,c]=size(im);
imnew=zeros(imgh,imgw,3);
if c==1
    imnew(:,:,1)=im;
    imnew(:,:,2)=im;
    imnew(:,:,3)=im;
    im=imnew;
end
original_bordered_image = add_diffuse_border(im, boundary_width);

original_bordered_image = double(original_bordered_image);



[mh,mw]=size(cProposalMPT);
seed_idx=-1;
t1idx=-1;
t2idx=-1;

mIsGood=zeros(mh,mw);
for y=1:mh
    for x=1:mw
        if ~isempty(cProposalMPT{y,x})
            pt=cProposalMPT{y,x};
            mIsGood(y,x)=1;
            if pt(1)==t1(1,2) && pt(2)==t1(2,2)%x0
                seed_idx=[x;y];
            end
        end
    end
end
cRegMPT=cProposalMPT;


t1=t1+boundary_width;
t2=t2+boundary_width;
x0=t1(1,2);
y0=t1(2,2);
x1=t1(1,1);
y1=t1(2,1);
x2=t2(1,1);
y2=t2(2,1);
%extract rectangular image patch from image centered at x0...
%size about the same as t1,t2 norsms...


t1=t1(:,1)-t1(:,2);
t2=t2(:,1)-t2(:,2);
dw=max(round(max(norm(t1),norm(t2))/2),5)
%dw=max(round((norm(t1)+norm(t2))/2),5)

for y=1:mh
    for x=1:mw
        cRegMPT{y,x}=cProposalMPT{seed_idx(2),seed_idx(1)}+(x-seed_idx(1))*t1+(y-seed_idx(2))*t2;
    end
end


for y=1:mh
    for x=1:mw
        if mIsGood(y,x)==1
            cProposalMPT{y,x}(1)=cProposalMPT{y,x}(1)+boundary_width;
            cProposalMPT{y,x}(2)=cProposalMPT{y,x}(2)+boundary_width;
        else
            cProposalMPT{y,x}=[cRegMPT{y,x}(1)+boundary_width;cRegMPT{y,x}(2)+boundary_width];
        end
        cRegMPT{y,x}(1)=cRegMPT{y,x}(1)+boundary_width;
        cRegMPT{y,x}(2)=cRegMPT{y,x}(2)+boundary_width;
    end
end





template=original_bordered_image(y0-dw:y0+dw,x0-dw:x0+dw,:);
%
% if y0-dw>=boundary_width+1 && y0+dw<imgh+boundary_width && x0-dw>=boundary_width+1 && x0+dw <imgw+boundary_width
%     template=original_bordered_image(y0-dw:y0+dw,x0-dw:x0+dw,:);
% elseif y1-dw>=boundary_width+1 && y1+dw <imgh+boundary_width && x1-dw>=boundary_width+1 && x1+dw <imgw+boundary_width
%     template=original_bordered_image(y1-dw:y1+dw,x1-dw:x1+dw,:);
%     x0=x1;
%     y0=y1;
% elseif y2-dw>=boundary_width+1 && y2+dw <imgh+boundary_width && x2-dw>=boundary_width+1 && x2+dw <imgw+boundary_width
%     template=original_bordered_image(y2-dw:y2+dw,x2-dw:x2+dw,:);
%     x0=x2;
%     y0=y2;
% else
%
%     if mIsGood(seed_idx(2)+1,seed_idx(1)+1)==1
%         pt=cProposalMPT{y,x};
%         template=original_bordered_image(pt(2)-dw:pt(2)+dw,pt(1)-dw:pt(1)+dw,:);
%     else
%         mindist=mh;
%         minidx=-1;
%         for y=1:mh
%             for x=1:mw
%                 if mIsGood(y,x)==1
%                     pt=cProposalMPT{y,x};
%                     if pt(2)-dw>=boundary_width+1 && pt(2)+dw<imgh+boundary_width && pt(1)-dw>=boundary_width+1 && pt(1)+dw <imgw+boundary_width
%                         dist=(y-seed_idx(2))^2+(x-seed_idx(1))^2;
%                         if dist<mindist
%                             mindist=dist;
%                             minpt=pt;
%                         end
%                     end
%                 end
%             end
%         end
%         template=original_bordered_image(minpt(2)-dw:minpt(2)+dw,minpt(1)-dw:minpt(1)+dw,:);
%     end
% end

display=0;

kernelsize=2;%1
Kdxdy=2;
range=min(round(dw/4),7);
MAP=1;
mask=fspecial('gaussian',2*dw+1,30);
mask=mask/max(max(mask));


template=rgb2gray(template);

tic
[pdfs]=MexTmpMatching(original_bordered_image,template);
toc
pdftex=pdfs;
edge_template=GetEdge(template);
edgeim=GetEdge(double(rgb2gray(original_bordered_image)));
pdfedge=MexTmpMatching(edgeim,edge_template);
idx=find(pdfedge<0);
pdfs=pdfs.*pdfedge;
%pdfedge(idx)=pdfedge(idx)*-1;


cMPT=cProposalMPT;
[hh,ww]=size(cMPT);
mIsBypass=zeros(hh,ww);

%Now we get projective transformation.......



offset=[0;0];
IsProjSuccessful=1;

[m,n]=find(mIsGood>0);
len=length(m);
UU=[];VV=[];
XX=[];YY=[];
minflag=1000;
minT=[];
for y=1:hh
    for x=1:ww
        if mIsGood(y,x)>0
            UU=[UU;cMPT{y,x}(1)];
            VV=[VV;cMPT{y,x}(2)];
            XX=[XX;cRegMPT{y,x}(1)];
            YY=[YY;cRegMPT{y,x}(2)];
        end
    end
end
minUpt=[];
minXpt=[];
if len>5
    for it=1:300
        
        cnt=0;
        while cnt~=4
            idx=round( rand(1,4)*(len-1)+1);
            idx=unique(idx);
            cnt=length(idx);
        end
        Upt=[cMPT{m(idx(1)),n(idx(1))}';cMPT{m(idx(2)),n(idx(2))}';cMPT{m(idx(3)),n(idx(3))}';cMPT{m(idx(4)),n(idx(4))}'];
        Xpt=[cRegMPT{m(idx(1)),n(idx(1))}';cRegMPT{m(idx(2)),n(idx(2))}';cRegMPT{m(idx(3)),n(idx(3))}';cRegMPT{m(idx(4)),n(idx(4))}'];
        try
            T = maketform('projective',Upt,Xpt);
            if cond(T.tdata.T)<40000
                [X,Y] = tformfwd(T,UU,VV);
                flag=sum(abs(X-XX)+abs(Y-YY));
                if flag <minflag
                    minflag=flag;
                    minT=T;
                    minUpt=Upt;
                    minXpt=Xpt;
                    IsProjSuccessful=1;
                end
            end
        end
    end
else
    IsProjSuccessful=0;
end
if isempty(minT)
    IsProjSuccessful=0;
end

[h,w,c]=size(original_bordered_image);
if IsProjSuccessful==1
    T=minT;
    later=0;
    if later==1
        [X,Y] = tformfwd(T,x0,y0);
        
        minXpt(:,1)=minXpt(:,1)+round(x0-X+boundary_width/2);
        minXpt(:,2)=minXpt(:,2)+round(y0-Y+boundary_width/2);
        [mh,mw]=size(cRegMPT);
        for y=1:mh
            for x=1:mw
                cRegMPT{y,x}=cRegMPT{y,x}+[round(x0-X+boundary_width/2);round(y0-Y+boundary_width/2)];
            end
        end
        
        T = maketform('projective',minUpt,minXpt);
    end
    
    [h,w,c]=size(original_bordered_image);
    [B,X,Y]= imtransform(original_bordered_image,T,'YData',[1 h],'XData',[1 w]);
    % figure(20);imshow(B);drawLatticeFromProposalCell(cRegMPT,'r',5);
    % print('-f20','-djpeg','-r300',sprintf('%s%sProj_est%.2d.jpg',savepath,fname,trial)  );
    %we need new template too.....
    [X0, Y0] = tformfwd(T, x0, y0);
    
    gray_projected_image=rgb2gray(B);
    gray_projected_original_image=gray_projected_image;
    template=gray_projected_original_image(Y0-dw:Y0+dw,X0-dw:X0+dw);
    color_original_bordered_image=B;
else
    gray_projected_image=rgb2gray(original_bordered_image);
    gray_projected_original_image=gray_projected_image;
    color_original_bordered_image=original_bordered_image;
end
%pt=cRegMPT{seed_idx(2),seed_idx(1)}
%template=gray_projected_image(pt(2)-dw:pt(2)+dw,pt(1)-dw:pt(1)+dw,:);
tic
[pdfs]=MexTmpMatching(gray_projected_image,template);
toc
pdftex=pdfs;
edge_template=GetEdge(template);
edgeim=GetEdge(double(gray_projected_image));
pdfedge=MexTmpMatching(edgeim,edge_template);
idx=find(pdfedge<0);
%pdfedge(idx)=pdfedge(idx)*-1;
pdfs=pdfs.*pdfedge;
%[mean_t1, mean_t2, mean_t1t2, t1_std, t2_std] = calc_mean_t(lattice, pcols, prows, max_conn_quads .* valid_quads);

%clear im;
%We form a lattice cell according to t1,t2 proposal....




%Here we already contains the projective transform......


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Now grow lattice.......
gau=fspecial('gaussian',3*dw,10);
%map2=imfilter(map,gau);



[hh,ww]=size(cMPT);
mIsBoundary=zeros(hh,ww);
mIsGoodCnt=mIsGood;
rOriginalMPT=cMPT;
cMPT=cRegMPT;
warping_started=0;

frame=0;
hittime=0;
update=0;
prevGood=mIsGood;
obs_thresh=0.7;
display=1;
usemask=0;
% % % % % %     FIXME: check this point!
for kkk=1:15
    %cMPT=cCellStart{pos};
    %cRegMPT=cCellStart{pos};
    %pos=pos-1;
    if kkk>2 && length(find(mIsGood>0))<2
        break;
    end
    
    
    
    IsConverging=0;
    
    
    
    
    for it=1:maxit
        frame=frame+1;
        
        %   figure(2);clf;subplot('Position',[0 0 1 1]);imagesc(pdfs);drawLatticeFromCell(cMPT,'g',mIsBoundary,mIsGood);colormap hot;
        
        
        if 0
            if h>w
                figure(3);clf;subplot('Position',[0 0 0.5 1]);imshow(gray_projected_image);axis off;
                drawLatticeFromCell(cMPT,'b',mIsBoundary,mIsGood,markersize);
                hold on;plot(cMPT{seed_idx(2),seed_idx(1)}(1),cMPT{seed_idx(2),seed_idx(1)}(2),'*');
                figure(3);subplot('Position',[0.5 0 0.5 1]);imshow(color_original_bordered_image)
                ;drawLatticeFromCell(rOriginalMPT,'r',mIsBoundary,mIsGood,markersize);
            else
                figure(3);clf;subplot('Position',[0 0 1 0.5]);imshow(gray_projected_image);axis off;
                drawLatticeFromCell(cMPT,'b',mIsBoundary,mIsGood,markersize);
                hold on;plot(cMPT{seed_idx(2),seed_idx(1)}(1),cMPT{seed_idx(2),seed_idx(1)}(2),'*');
                figure(3);subplot('Position',[0 0.5 1 0.5]);imshow(color_original_bordered_image)
                ;drawLatticeFromCell(rOriginalMPT,'r',mIsBoundary,mIsGood,markersize);
            end
            
        end
        
        [hh,ww]=size(cMPT);
        
        mIsMaxConnected=FindMaximallyConnected(mIsGood);
        idx=find(mIsMaxConnected==1);
        mInferNeeded=0;
        if length(idx)>0
            mInferNeeded=FindInferNeeded(mIsMaxConnected);
            mInferNeeded(seed_idx(2),seed_idx(1))=1;
        else
            mInferNeeded=zeros(size(mIsGood));
            for y=1:mh
                for x=1:mw
                    if y==seed_idx(2) && x== seed_idx(1)
                        mInferNeeded(y-1,x-1)=1;
                        mInferNeeded(y,x-1)=1;
                        mInferNeeded(y+1,x-1)=1;
                        mInferNeeded(y-1,x)=1;
                        mInferNeeded(y,x)=1;
                        mInferNeeded(y+1,x)=1;
                        mInferNeeded(y-1,x+1)=1;
                        mInferNeeded(y,x+1)=1;
                        mInferNeeded(y+1,x+1)=1;
                        break;
                    end
                end
            end
        end
        
        mIsBypass=~(mInferNeeded)|(mIsGoodCnt> ThGoodCnt);
        
        if ismac
            tic;
            [r_mB,r_cMPT]...
                =OSX_MSBPLocalAlignByPass(cMPT,cRegMPT,Kdxdy,MAP,beta,alpha,range,pdfs,0,kernelsize,double(mIsBypass));
            toc
        else
            tic;
            [r_mB,r_cMPT]...
                =MSBPLocalAlignByPass(cMPT,cRegMPT,Kdxdy,MAP,beta,alpha,range,pdfs,0,kernelsize,double(mIsBypass));
            toc
        end
        %clear MSBPLocalAlignByPass;
        
        if cellSADDev(cMPT,r_cMPT) ==0
            cMPT=r_cMPT;
            IsConverging=1;
            break;
        else
            cMPT=r_cMPT;
        end
        
    end
    msg='verify result';
    
    %figure(11);imagesc(gray_projected_image);drawLatticeFromCellDebug(cMPT
    %,'r',mIsBoundary,mIsGood);colormap gray;
    mIsCheck=mInferNeeded|mIsGood;
    [r_cMPT,r_mIsGood,obs_thresh]=VerifyResultCheckGoodNode2(cMPT,mIsCheck,dw,template,cRegMPT,pdfs,pdfedge,gray_projected_image,mIsBypass,obs_thresh);
    %figure(12);imagesc(gray_projected_image);drawLatticeFromCellDebug(r_cMPT,'r',mIsBoundary,r_mIsGood);colormap gray;
    
    
    mNewGoodNode=r_mIsGood &(~mIsGood);
    mOldGoodNode=r_mIsGood & (~mNewGoodNode);
    mOldGoodNode(seed_idx(2),seed_idx(1))=1;
    %     figure(2);clf;subplot('Position',[0 0 1 1]);imagesc(pdfs);
    %     if length(mInferNeeded)==1
    %         drawLatticeFromCellDebug(r_cMPT,'k',mIsBoundary,mIsGood);colormap hot;colorbar
    %         sprintf('size of cMPT is %d by %d',size(mIsGood,1),size(mIsGood,2))
    %     else
    %         drawLatticeFromCellDebug(r_cMPT,'k',mInferNeeded,mIsGood);colormap hot;colorbar
    %         sprintf('size of cMPT is %d by %d',size(mIsGood,1),size(mIsGood,2))
    %     end
    %     print('-f2','-djpeg','-r300',sprintf('%s%s\\%spdfs_trial%.2d_it%.3d%.3d.jpg',savepath,fname,fname,trial,kkk,frame)  );
    %     axis tight;
    
    
    
    obs_thresh
    mIsGood=r_mIsGood;
    
    cMPT=r_cMPT;
    
    
    mIsGood(seed_idx(2),seed_idx(1))=1;
    mIsGoodCnt=mIsGoodCnt+mIsGood;
    mIsGood=mIsGood|(mIsGoodCnt> ThGoodCnt);
    mIsMaxConnected=FindMaximallyConnected(mIsGood);
    mIsGood=mIsMaxConnected;
    mIsGood(seed_idx(2),seed_idx(1))=1;
    if sum(abs(prevGood-mIsGood))==0
        
        hittime=hittime+1;
        msg='ending'
        usemask=1;
        if hittime>=3
            
            display=0;
            if display==1
                sMask=getStatisticMask(gray_projected_image,cMPT,dw,mOldGoodNode);
                [xx,yy]=meshgrid(1:2*dw+1,1:2*dw+1);
                figure(22);surfc(sMask);colormap hot;
                mean(mean(sMask))
                std(std(sMask))
            end
            save(sprintf('%s%s\\debugData%.2d.mat',savepath,fname,kkk),'cMPT','gray_projected_image','mIsGood','template','cRegMPT','pdfs');
            getMedianTemp(gray_projected_image,cMPT,dw,mIsGood,sprintf('%s%s\\patch%.2d.mat',savepath,fname,kkk));
            break;
        end
    else
        %hittime=0;
    end
    
    % figure(1);clf;imshow(gray_projected_image);
    % drawLatticeFromCell(cMPT,'r',mIsHole);
    
    dddd=find(mIsGood>0);
    mTmp=mIsGood;
    [m,n]=find(mTmp>0);
    
    if length(unique(m))>=2 &&length(unique(n))>=2
        
        
        %check center of cMPT and if it is far from the center of image
        %then we need
        
        if 0
            PT=[];
            flag=0;
            for y=1:mh
                for x=1:mh
                    if mIsGood(y,x)>0
                        pt=cMPT{y,x};
                        PT=[PT pt];
                        if pt(1) <= dw || pt(2) <=dw || pt(1) >= w-dw ||pt(2) >=h-dw
                            flag=1;
                        end
                    end
                end
            end
            
            if flag==1
                %                %%keyboard;
                X=[];
                Y=[];
                for y=1:mh
                    for x=1:mw
                        X=[X;rOriginalMPT{y,x}(1)];
                        Y=[Y;rOriginalMPT{y,x}(2)];
                        
                        cRegMPT{y,x}=cRegMPT{y,x}-offset;
                        
                    end
                end
                [U,V] = tforminv(T,X,Y);
                
                
                center=[round(w/2) round(h/2)];
                meanpt=mean(PT');
                offset=center'-round(meanpt');
                tmpXpt=minXpt;
                tmpXpt(:,1)=minXpt(:,1)+offset(1);
                tmpXpt(:,2)=minXpt(:,2)+offset(2);
                
                T = maketform('projective',minUpt,tmpXpt);
                
                [X,Y] = tformfwd(T,U,V);
                cnt=0;
                for y=1:mh
                    for x=1:mw
                        
                        cnt=cnt+1;
                        rOriginalMPT{y,x}=[X(cnt);Y(cnt)];
                        
                        cRegMPT{y,x}=cRegMPT{y,x}+offset;
                    end
                end
                [B,X,Y]= imtransform(original_bordered_image,T,'YData',[1 h],'XData',[1 w]);
                %    figure(20);imshow(B);drawLatticeFromProposalCell(rOriginalMPT,'r',5);
                %    print('-f20','-djpeg','-r300',sprintf('%s%sProj_est%.2d.jpg',savepath,fname,trial)  );
                gray_projected_image=rgb2gray(B);
                gray_projected_original_image=gray_projected_image;
                color_original_bordered_image=B;
                %reset TPS warp...
                reverse_x_coord_warps = zeros(size(im,1) + 2*boundary_width, size(im,2) + 2*boundary_width, 0); %reg towards distorted
                reverse_y_coord_warps = zeros(size(im,1) + 2*boundary_width, size(im,2) + 2*boundary_width, 0);
                reverse_x_coord_warps=double(reverse_x_coord_warps);
                reverse_y_coord_warps=double(reverse_y_coord_warps);
                msg='spline warping'
                tic
                [warped_image, cNewMPT, x_coord_warps, y_coord_warps, rOriginalMPT] = ...
                    fast_reg_tps_warp_thread(rOriginalMPT, cRegMPT,zeros(size(mIsGood)),mIsGood, gray_projected_original_image, reverse_x_coord_warps, reverse_y_coord_warps,boundary_width);
                toc
            else%normal TPS
                msg='spline warping'
                tic
                [warped_image, cNewMPT, x_coord_warps, y_coord_warps, rOriginalMPT] = ...
                    fast_reg_tps_warp_thread(cMPT, cRegMPT,mOldGoodNode,mNewGoodNode, gray_projected_original_image, reverse_x_coord_warps, reverse_y_coord_warps,boundary_width);
                toc
                %clear fast_reg_tps_warp;
                %[r_mIsGood]=FinalizeAddFilterDecide(gray_projected_image,cNewMPT,r_mIsGood,mIsBoundary,seed_idx);
                warping_started=1;
            end
        else
            msg='spline warping'
            tic
            [warped_image, cNewMPT, x_coord_warps, y_coord_warps, rOriginalMPT] = ...
                fast_reg_tps_warp_thread(cMPT, cRegMPT,mOldGoodNode,mNewGoodNode, gray_projected_original_image, reverse_x_coord_warps, reverse_y_coord_warps,boundary_width);
            toc
            %clear fast_reg_tps_warp;
            %[r_mIsGood]=FinalizeAddFilterDecide(gray_projected_image,cNewMPT,r_mIsGood,mIsBoundary,seed_idx);
            warping_started=1;
        end
        
        %         figure(2);clf;subplot('Position',[0 0 1 1]);imagesc(pdfs);
        %         drawLatticeFromCellDebug(cMPT,'k',mIsBoundary,mIsGood);colormap hot;colorbar
        
        reverse_x_coord_warps = x_coord_warps; %the composition of all warps done so far
        reverse_y_coord_warps = y_coord_warps;
        gray_projected_image = warped_image;
        %mIsMaxConnected=FindMaximallyConnected(mIsGood);
        %mIsGood=mIsMaxConnected;
        
        
        cMPT=cNewMPT;
        
        msg='matching'
        pt0=cMPT{seed_idx(2),seed_idx(1)};
        
        template=getMedianTemp(gray_projected_image,cMPT,dw,mIsGood,sprintf('%s%s\\patch%.2d.mat',savepath,fname,kkk));
        figure(12);
        imshow(template);
        imwrite(template, sprintf('%s%s/template.jpg', savepath, fname)) 
        colormap gray;
        tic;
        pdfs=MexTmpMatching(gray_projected_image,template);
        toc
        
        pdftex=pdfs;
        edge_template=GetEdge(template);
        edgeim=GetEdge(double(gray_projected_image));
        pdfedge=MexTmpMatching(edgeim,edge_template);
        pdfs=pdfs.*pdfedge;
        
        %         figure(2);clf;subplot('Position',[0 0 1 1]);imagesc(pdfs);
        %         if length(mInferNeeded)==1
        %             drawLatticeFromCellDebug(cMPT,'k',mIsBoundary,mIsGood);colormap hot;colorbar
        %         else
        %             drawLatticeFromCellDebug(cMPT,'k',mInferNeeded,mIsGood);colormap hot;colorbar
        %         end
        %         print('-f2','-djpeg','-r300',sprintf('%s%s\\%spdfs_trial%.2d_it%.3d.jpg',savepath,fname,fname,trial,kkk)  );
        %         axis tight;
        %pdfedge(idx)=pdfedge(idx)*-1;
        
        
        %clear MexTmpMatching;
        
    else
        %rOriginalMPT=r_cMPT;
        if warping_started==0
            rOriginalMPT=r_cMPT;
        end
        cMPT=r_cMPT;
    end
    [mh,mw]=size(mIsGood);
    if mh <=1 ||mw <=1
        break;
    end
    
    [DoWeEnd,rcMPT,cRegMPT,rOriginalMPT,mIsBoundary,mIsGood,mIsGoodCnt,seed_idx]=GrowLatticeUsingNodeInside(cMPT,cRegMPT,rOriginalMPT,mIsGood,mIsGoodCnt,boundary_width,h,w,seed_idx,dw);%,seedm,seed_xidx,seed_yidx);
    [mh,mw]=size(mIsBoundary);
    mIsBoundary=zeros(mh,mw);
    
    
    
    
    
    
    
    %   hittime=hittime+1;
    %END !!!!!!!!!!
    %   usemask=1;
    %   if hittime>3
    % break;
    %   end
    %end
    cMPT=rcMPT;
    cRegMPT=cRegMPT;
    %figure(4);drawLatticeFromCell(cRegMPT,'b',mIsBoundary,mIsGood);
    %pause;
    %figure(3);imagesc(pdfs);drawLatticeFromCell(cMPT,'b',mIsBoundary,mIsGood);
    %print('-f3','-djpeg','-r300',sprintf('%s\\output_avi\\%.3d\\maps%.3d.jpg',path,fileidx,frame) ) ;
    %g',path,fileidx,frame)  );
    if h>w
        figure(1);clf;subplot('Position',[0 0 0.5 1]);imshow(gray_projected_image);axis off;
        drawLatticeFromCell(cMPT,'b',mIsBoundary,mIsGood,markersize);
        %hold on;plot(cMPT{seed_idx(2),seed_idx(1)}(1),cMPT{seed_idx(2),seed_idx(1)}(2),'*');
        figure(1);subplot('Position',[0.5 0 0.5 1]);imshow(color_original_bordered_image)
        ;drawLatticeFromCell(rOriginalMPT,'r',mIsBoundary,mIsGood,markersize);
    else
        figure(1);clf;subplot('Position',[0 0 1 0.5]);imshow(gray_projected_image);axis off;
        drawLatticeFromCell(cMPT,'b',mIsBoundary,mIsGood,markersize);
        %hold on;plot(cMPT{seed_idx(2),seed_idx(1)}(1),cMPT{seed_idx(2),seed_idx(1)}(2),'*');
        figure(1);subplot('Position',[0 0.5 1 0.5]);imshow(color_original_bordered_image)
        ;drawLatticeFromCell(rOriginalMPT,'r',mIsBoundary,mIsGood,markersize);
    end
    print('-f1','-djpeg','-r300',sprintf('%s%s\\%s_trial%.2d_it%.3d.jpg',savepath,fname,fname,trial,kkk)  );
    
    %ending condition
    prevGood=mIsGood;
end
% verification process...~!!!!!! HOW??? first check each node and extract
% template from gray_projected_image......(from a rectified image)
% compare and select inlier
% from the outliers....let extract emplate from quadratral using
% neighborhoods which are also inlier, then compare with other template
% extracted using inliers
% if there is a good match, it also become a inlier......


% figure(1);clf;imshow(gray_projected_image);
% drawLatticeFromCell(cMPT,'r',mIsHole);
%[r_mIsGood,threshold]=Finalize(cMPT,mIsGood,mIsBoundary,pdfs);


markersize=4;
%figure(3);imshow(gray_projected_image);drawLatticeFromCell(cMPT,'g',mIsHole);
%figure(1);imshow(gray_projected_image);drawLatticeFromCell(cMPT,'b',mIsBoundary,mIsGood,markersize);

bFail=0;

[mh,mw]=size(mIsGood);
if mh <=1 ||mw <=1
    bFail=1;
    return;
end

[ccnt,semicnt]=GetTotalCompleteQuad(mIsGood);
if ccnt<20 || mIsGood(seed_idx(2),seed_idx(1))==0
    bFail=1;
end

%rOriginalMPT should be converted to original....
if IsProjSuccessful==1
    X=[];
    Y=[];
    for y=1:mh
        for x=1:mw
            X=[X;rOriginalMPT{y,x}(1)];
            Y=[Y;rOriginalMPT{y,x}(2)];
        end
    end
    [U,V] = tforminv(T,X,Y);
    cnt=0;
    for y=1:mh
        for x=1:mw
            cnt=cnt+1;
            rOriginalMPT{y,x}=[U(cnt);V(cnt)];
        end
    end
end
tmpMPT=rOriginalMPT;
[hh,ww]=size(rOriginalMPT);
for yy=1:hh
    for xx=1:ww
        tmpMPT{yy,xx}=rOriginalMPT{yy,xx}-[300;300];
    end
end
[ih,iw,c]=size(original_bordered_image);
tmpim=ones(ih-600,iw-600,3);

tmpim(101:100+ih-800,101:100+iw-800,:)=original_bordered_image(401:end-400,401:end-400,:);
figure(5);
imshow(tmpim);
drawLatticeFromCell(tmpMPT,'r',mIsBoundary,mIsGood,markersize);
[qx,qy,qg] = saveLatticeFromCell(tmpMPT, mIsBoundary, mIsGood, sprintf('%s%s', savepath, fname));
saveas( gcf, sprintf('%s%s/figure.jpg', savepath, fname));
export_fig( gcf, ...      % figure handle
    sprintf('%s%s/export_figure', savepath, fname),... % name of output file without extension
    '-painters', ...      % renderer
    '-jpg', ...           % file format
    '-r300' );             % resolution in dpi
print('-f5','-djpeg','-r300',sprintf('%s%s_result_trial%.2d.jpg',savepath,fname,trial)  );

function mag=GetEdge(im)

dev=[-1 0 1];
dx=imfilter(im,dev);
dy=imfilter(im,dev');
mag=dx.^2+dy.^2;
mag(1,:)=0;
mag(end,:)=0;
mag(:,1)=0;
mag(:,end)=0;




function mask=getStatisticMask(im,cMPT,dw,mIsGood)
[h,w]=size(im);
[mh,mw]=size(cMPT);
PATCH=zeros(2*dw+1,2*dw+1,1);
cnt=1;
for y=1:mh
    for x=1:mw
        pt=round(cMPT{y,x});
        if pt(1)>dw && pt(1) < w-dw && pt(2) >dw && pt(2) <h-dw
            if mIsGood(y,x)>0
                PATCH(:,:,cnt)= im(pt(2)-dw:pt(2)+dw,pt(1)-dw:pt(1)+dw);
                cnt=cnt+1;
            end
        end
    end
end

mask=zeros(2*dw+1,2*dw+1);
for y=1:2*dw+1
    for x=1:2*dw+1
        mask(y,x)=std(PATCH(y,x,:));
    end
end


function [r_cMPT,r_mIsGood,obs_thresh]=VerifyResultCheckGoodNode2(cMPT,mIsCheck,dw,seed_template,cRegMPT,pdftex,pdfedge,im,mIsBypass,learnedthresh)
%keyboard;
r_cMPT=cMPT;
[mh,mw]=size(cMPT);
r_mIsGood=zeros(mh,mw);
[h,w]=size(pdftex);
goodObs=[];
goodcnt=0;
factor=10;

%figure(11);subplot('position',[0 0.4 0.5 0.4]);imshow(seed_template);axis off;
%subplot('position',[0.5 0.4 0.5 0.4]);imagesc(seedD);colormap hot;axis off;
%%keyboard
score_edgedistance=[];
cntedge=1;

for y=1:mh
    for x=1:mw
        if mIsCheck(y,x)>0
            pt=round(cMPT{y,x});
            if pt(1)>dw && pt(1) < w-dw && pt(2) >dw && pt(2) <h-dw
                
                current_obs=pdftex(pt(2),pt(1));% see if this is peak or not....
                edge_obs=pdfedge(pt(2),pt(1));
                %we want to find nearest higher value than current_obs around pt.......
                wid=round(dw/4);
                
                
                
                
                surrounding=pdftex(max(1,pt(2)-wid):min(pt(2)+wid,h),max(1,pt(1)-wid):min(w,pt(1)+wid));
                [m,n]=find(surrounding>current_obs);
                dist=(wid+1-m).^2+(wid+1-n).^2;
                dist=sort(dist);
                maxval=max(max(surrounding));
                [m,n]=find(surrounding==maxval);
                distToMax=sqrt((wid+1-m).^2+(wid+1-n).^2);
                
                if (isempty(dist)  && current_obs>0.05)% || current_obs>=learnedthresh% &&current_obs2>0) || (isempty(dist2) &&current_obs2>0 )
                    r_mIsGood(y,x)=1;
                    goodcnt=goodcnt+1;
                    goodObs(goodcnt)=current_obs;
                else
                    len=length(dist);
                    iiii=find(dist>wid/2 & dist <wid*wid);
                    
                    if current_obs>0.05 && length(iiii)<1 % &&current_obs2>0||(length(iiii2)<1 && current_obs>0.3 &&current_obs2>0)
                        r_mIsGood(y,x)=1;
                        goodcnt=goodcnt+1;
                    else
                        r_cMPT{y,x}=cRegMPT{y,x};
                        r_mIsGood(y,x)=0;
                    end
                    
                end
            end
        end
    end
end
obs_thresh=median(goodObs);

function temp=getMedianTemp(im,cMPT,dw,mIsGood,path)
[h,w]=size(im);
[mh,mw]=size(cMPT);
PATCH=zeros(2*dw+1,2*dw+1,1);
cnt=1;
for y=1:mh
    for x=1:mw
        pt=round(cMPT{y,x});
        if pt(1)>dw && pt(1) < w-dw && pt(2) >dw && pt(2) <h-dw
            if mIsGood(y,x)>0
                PATCH(:,:,cnt)= im(pt(2)-dw:pt(2)+dw,pt(1)-dw:pt(1)+dw);
                cnt=cnt+1;
            end
        end
    end
end
%save(path,'PATCH');
temp=zeros(2*dw+1,2*dw+1);
for y=1:2*dw+1
    for x=1:2*dw+1
        temp(y,x)=median(PATCH(y,x,:));
    end
end




function [map]=TmpMatching(im,tmp)

[h,w,c]=size(im);

[th,tw,tc]=size(tmp);
if c>1
    im=rgb2gray(im);
end
if tc>1
    tmp=rgb2gray(tmp);
end
if mean(tmp)<=1
    im=uint8(im*255);
    tmp=uint8(tmp*255);
end
im=double(im);
tmp=double(tmp);


ROI=-1;
map=TemplateMatching(im,tmp,ROI);


function [r_cMPT]=RefineProposalInside(im,cMPT,cRegMPT,dw,seedidx,obs,x0,y0,dx,dy,IsMap,range,alpha,beta,boundary)

maxit=3;
kernelsize=1;
Kdxdy=3;

for it=1:maxit
    
    [hh,ww]=size(cMPT);
    IsBypass=zeros(hh,ww);
    
    
    tic;
    [r_mB,r_cMPT]...
        =MSBPLocalAlignByPass(cMPT,cRegMPT,Kdxdy,IsMap,beta,alpha,range,obs,0,kernelsize,IsBypass);
    
    t=toc;
    
    if cellSADDev(cMPT,r_cMPT) ==0
        
        cMPT=r_cMPT;
        
        IsConverging=1;
        break;
    else
        cMPT=r_cMPT;
        
    end
end

function [DoWeEnd,cResult,r_cRegMPT,r_cOriginalMPT,r_mIsBoundary,r_mIsGood,r_mIsGoodCnt,rseed_idx]=GrowLatticeUsingNodeInside(cMPT,cRegMPT,cOriginalMPT,mIsGood,mIsGoodCnt,boundary,h,w,seed_idx,dw)
rseed_idx=seed_idx;
rseed_idx(1)=rseed_idx(1)+1;
rseed_idx(2)=rseed_idx(2)+1;
[m,n]=size(cMPT);
r_mIsBoundary=zeros(m+2,n+2);
r_mIsGood=zeros(m+2,n+2);
r_mIsGoodCnt=zeros(m+2,n+2);

m=m+2;
n=n+2;
cResult=cell(m,n);
r_cRegMPT=cell(m,n);
r_cOriginalMPT=cell(m,n);
%keyboard;
for y=2:m-1
    for x=2:n-1
        cResult{y,x}=cMPT{y-1,x-1};
        r_cRegMPT{y,x}=cRegMPT{y-1,x-1};
        %        r_mIsHole(y,x)= 0;
        r_mIsGood(y,x)=mIsGood(y-1,x-1);
        r_mIsGoodCnt(y,x)=mIsGoodCnt(y-1,x-1);
        r_cOriginalMPT{y,x}=cOriginalMPT{y-1,x-1};
    end
end
fa=1;

for x=2:n-1
    cResult{1,x}=cResult{2,x}+(cResult{2,x}-cResult{3,x})*fa;
    cResult{m,x}=cResult{m-1,x}+(cResult{m-1,x}-cResult{m-2,x})*fa;
    r_cRegMPT{1,x}=2*r_cRegMPT{2,x}-r_cRegMPT{3,x};
    r_cRegMPT{m,x}=2*r_cRegMPT{m-1,x}-r_cRegMPT{m-2,x};
    r_cOriginalMPT{1,x}=2*r_cOriginalMPT{2,x}-r_cOriginalMPT{3,x};
    r_cOriginalMPT{m,x}=2*r_cOriginalMPT{m-1,x}-r_cOriginalMPT{m-2,x};
end

for y=2:m-1
    cResult{y,1}=cResult{y,2}+(cResult{y,2}-cResult{y,3})*fa;
    cResult{y,n}=cResult{y,n-1}+(cResult{y,n-1}-cResult{y,n-2})*fa;
    r_cRegMPT{y,1}=2*r_cRegMPT{y,2}-r_cRegMPT{y,3};
    r_cRegMPT{y,n}=2*r_cRegMPT{y,n-1}-r_cRegMPT{y,n-2};
    r_cOriginalMPT{y,1}=2*r_cOriginalMPT{y,2}-r_cOriginalMPT{y,3};
    r_cOriginalMPT{y,n}=2*r_cOriginalMPT{y,n-1}-r_cOriginalMPT{y,n-2};
end

cResult{1,1}=cResult{2,1}+(cResult{2,2}-cResult{3,2})*fa;
cResult{1,n}=cResult{2,n}+(cResult{2,n-1}-cResult{3,n-1})*fa;
cResult{m,1}=cResult{m-1,1}+(cResult{m-1,2}-cResult{m-2,2})*fa;
cResult{m,n}=cResult{m-1,n}+(cResult{m-1,n-1}-cResult{m-2,n-1})*fa;



r_cRegMPT{1,1}=r_cRegMPT{2,1}+(r_cRegMPT{2,2}-r_cRegMPT{3,2});
r_cRegMPT{1,n}=r_cRegMPT{2,n}+(r_cRegMPT{2,n-1}-r_cRegMPT{3,n-1});
r_cRegMPT{m,1}=r_cRegMPT{m-1,1}+(r_cRegMPT{m-1,2}-r_cRegMPT{m-2,2});
r_cRegMPT{m,n}=r_cRegMPT{m-1,n}+(r_cRegMPT{m-1,n-1}-r_cRegMPT{m-2,n-1});


r_cOriginalMPT{1,1}=r_cOriginalMPT{2,1}+(r_cOriginalMPT{2,2}-r_cOriginalMPT{3,2});
r_cOriginalMPT{1,n}=r_cOriginalMPT{2,n}+(r_cOriginalMPT{2,n-1}-r_cOriginalMPT{3,n-1});
r_cOriginalMPT{m,1}=r_cOriginalMPT{m-1,1}+(r_cOriginalMPT{m-1,2}-r_cOriginalMPT{m-2,2});
r_cOriginalMPT{m,n}=r_cOriginalMPT{m-1,n}+(r_cOriginalMPT{m-1,n-1}-r_cOriginalMPT{m-2,n-1});

%now checking for the lattice which hitting the boundary.....


if nargin>1
    for y=1:m
        for x=1:n
            pt=r_cOriginalMPT{y,x};
            if pt(1) < dw || pt(1) >w-dw ||pt(2) <dw || pt(2) > h-dw
                r_mIsBoundary(y,x)=1;
            end
        end
    end
end
% the below has lots of redundancy but leave it that way...!!
checky=zeros(1,m);
for y=1:m
    prod=1;
    for x=1:n
        prod=prod*r_mIsBoundary(y,x);
    end
    if prod==1
        checky(y)=1;
    end
end


checkx=zeros(1,n);
for x=1:n
    prod=1;
    for y=1:m
        prod=prod*r_mIsBoundary(y,x);
    end
    if prod==1
        checkx(x)=1;
    end
end
if checkx(1)==1 || checky(1)==1 || checkx(n)==1 || checky(m)==1
    %we hit 4 the boundaries
    DoWeEnd=1;
else
    DoWeEnd=0;
end
downEdgeIdxY=-1;
upEdgeIdxY=-1
for i=2:m
    if checky(i-1)==0 && checky(i)==1
        if upEdgeIdxY==-1
            upEdgeIdxY=i-1;
        end
    end
    if checky(i-1)==1 && checky(i)==0
        if downEdgeIdxY==-1
            downEdgeIdxY=i;
        end
    end
end
if downEdgeIdxY==-1
    downEdgeIdxY=1;
end
if upEdgeIdxY==-1
    upEdgeIdxY=m;
end
downEdgeIdxX=-1;
upEdgeIdxX=-1
for i=2:n
    if checkx(i-1)==0 && checkx(i)==1
        if upEdgeIdxX==-1
            upEdgeIdxX=i-1;
        end
    end
    if checkx(i-1)==1 && checkx(i)==0
        if downEdgeIdxX==-1
            downEdgeIdxX=i;
        end
    end
end
if downEdgeIdxX==-1
    downEdgeIdxX=1;
end
if upEdgeIdxX==-1
    upEdgeIdxX=n;
end


newH=upEdgeIdxY -downEdgeIdxY+1;
newW=upEdgeIdxX -downEdgeIdxX+1;
cNewResult=cell(newH,newW);
cNewReg=cell(newH,newW);
cNewOriginal=cell(newH,newW);
mNewBoundary=zeros(newH,newW);
mNewGood=zeros(newH,newW);
mNewGoodCnt=zeros(newH,newW);
yy=1;
for y=downEdgeIdxY:upEdgeIdxY
    xx=1;
    for x=downEdgeIdxX:upEdgeIdxX
        cNewResult{yy,xx}=cResult{y,x};
        cNewOriginal{yy,xx}=r_cOriginalMPT{y,x};
        cNewReg{yy,xx}=r_cRegMPT{y,x};
        mNewBoundary(yy,xx)=r_mIsBoundary(y,x);
        mNewGood(yy,xx)=r_mIsGood(y,x);
        mNewGoodCnt(yy,xx)=r_mIsGoodCnt(y,x);
        if rseed_idx(1)==x && rseed_idx(2)==y
            rseed_idx=[xx;yy];
        end
        xx=xx+1;
    end
    yy=yy+1;
end
r_mIsBoundary=mNewBoundary;
r_mIsGood=mNewGood;
r_mIsGoodCnt=mNewGoodCnt;
cResult=cNewResult;
r_cRegMPT=cNewReg;
r_cOriginalMPT=cNewOriginal;
[h,w]=size(r_mIsGood)
for y=1:h
    for x=1:w
        if r_mIsGood(y,x)==0
            cResult{y,x}=r_cRegMPT{y,x};
        end
    end
end




