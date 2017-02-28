
function ascore = GetAScoreForCompQuad(cMPT, original_image)




[mh,mw]=size(cMPT);
mIsGood=zeros(mh,mw);

t1=0;
t2=0;
seedxx=0;
seedyy=0;
for yy=1:mh
    for xx=1:mw
        if ~isempty(cMPT{yy,xx})
            mIsGood(yy,xx)=1;
            cMPT{yy,xx}=[cMPT{yy,xx}(1);cMPT{yy,xx}(2)];
        end
        if t1==0 & t2==0
            if xx<=mw-1 && yy<=mh-1
                flag=isempty(cMPT{yy,xx})+isempty(cMPT{yy+1,xx})+isempty(cMPT{yy,xx+1});
                if flag ==0
                    t1= [cMPT{yy,xx+1}(1);cMPT{yy,xx+1}(2)]-[cMPT{yy,xx}(1);cMPT{yy,xx}(2)];
                    t2= [cMPT{yy+1,xx}(1);cMPT{yy+1,xx}(2)]-[cMPT{yy,xx}(1);cMPT{yy,xx}(2)];
                    seedyy=yy;
                    seedxx=xx;
                end
            end
        end
    end
end
wid=norm(t1)+norm(t2);
wid=round(wid/2);
for yy=1:mh
    for xx=1:mw
        if  mIsGood(yy,xx)
            cMPT{yy,xx}=[cMPT{yy,xx}(1);cMPT{yy,xx}(2)];
        end
    end
end

%making cRegMPT;
cRegMPT=cMPT;
for yy=1:mh
    for xx=1:mw
        if mIsGood(yy,xx)
            cRegMPT{yy,xx}=cMPT{seedyy,seedxx}+t1*(xx-seedxx)+t2*(yy-seedyy);
        end
    end
end
wid=50;
numAll=0;
numCompQuad=0;
numSemiQuad=0;
[h,w,c]=size(original_image);
if c==3
    patchr=zeros(1,(wid)^2);
    patchg=zeros(1,(wid)^2);
    patchb=zeros(1,(wid)^2);
else
    patchr=zeros(1,(wid)^2);
end
for yy=1:mh-1
    for xx=1:mw-1
        flag=mIsGood(yy,xx)+mIsGood(yy+1,xx)+mIsGood(yy,xx+1)+mIsGood(yy+1,xx+1);
        if flag==4
            numCompQuad=numCompQuad+1;
            im_corners = [cMPT{yy,xx}'; ...  %(x,y) pairs
                cMPT{yy,xx+1}'; ...
                cMPT{yy+1,xx+1}';...
                cMPT{yy+1,xx}'];
            if im_corners(1,1)==459 && im_corners(1,2)==224
                sprintf('afsadfdsa');
            end
            tmp_corners=[ 0 0;wid 0; wid wid;0 wid];
            tform = maketform('projective', im_corners, tmp_corners);
            [B,xdata,ydata] = imtransform(original_image, tform,'bicubic', 'xdata', [1 wid], 'ydata', [1 wid], 'fill',.5);
            numAll=numAll+1;
            if c==3
                patchr(numAll,:)=reshape(B(:,:,1),1,wid*wid);
                patchr(numAll,:)=(patchr(numAll,:)-mean(patchr(numAll,:)))/std(patchr(numAll,:));
                patchg(numAll,:)=reshape(B(:,:,2),1,wid*wid);
                patchg(numAll,:)=(patchg(numAll,:)-mean(patchg(numAll,:)))/std(patchg(numAll,:));
                patchb(numAll,:)=reshape(B(:,:,3),1,wid*wid);
                patchb(numAll,:)=(patchb(numAll,:)-mean(patchb(numAll,:)))/std(patchb(numAll,:));
            else
                patchr(numAll,:)=reshape(B(:,:),1,wid*wid);
                patchr(numAll,:)=(patchr(numAll,:)-mean(patchr(numAll,:)))/std(patchr(numAll,:));
            end
            % figure(11);imshow(B);pause;
        elseif flag==3
            numSemiQuad=numSemiQuad+1;
            if mIsGood(yy,xx)==0
                tmp=cMPT{yy,xx+1}+cMPT{yy+1,xx}-cMPT{yy+1,xx+1};
                im_corners = [tmp'; ...  %(x,y) pairs
                    cMPT{yy,xx+1}'; ...
                    cMPT{yy+1,xx+1}';...
                    cMPT{yy+1,xx}'];
            elseif mIsGood(yy+1,xx)==0
                tmp=cMPT{yy+1,xx+1}+cMPT{yy,xx}-cMPT{yy,xx+1};
                im_corners = [cMPT{yy,xx}'; ...  %(x,y) pairs
                    cMPT{yy,xx+1}'; ...
                    cMPT{yy+1,xx+1}';...
                    tmp'];
            elseif mIsGood(yy+1,xx+1)==0
                tmp=cMPT{yy+1,xx}+cMPT{yy,xx+1}-cMPT{yy,xx};
                im_corners = [cMPT{yy,xx}'; ...  %(x,y) pairs
                    cMPT{yy,xx+1}'; ...
                    tmp';...
                    cMPT{yy+1,xx}'];
            else
                tmp=cMPT{yy,xx}+cMPT{yy+1,xx+1}-cMPT{yy+1,xx};
                im_corners = [cMPT{yy,xx}'; ...  %(x,y) pairs
                    tmp'; ...
                    cMPT{yy+1,xx+1}';...
                    cMPT{yy+1,xx}'];
            end
            if im_corners(1,1)==459 && im_corners(1,2)==224
               sprintf('afsadfdsa'); 
            end
            tmp_corners=[ 0 0;wid 0; wid wid;0 wid];
            tform = maketform('projective', im_corners, tmp_corners);
            [B,xdata,ydata] = imtransform(original_image, tform,'bicubic', 'xdata', [1 wid], 'ydata', [1 wid], 'fill',.5);
            numAll=numAll+1;
            if c==3
                patchr(numAll,:)=reshape(B(:,:,1),1,wid*wid);
                patchr(numAll,:)=(patchr(numAll,:)-mean(patchr(numAll,:)))/std(patchr(numAll,:));
                patchg(numAll,:)=reshape(B(:,:,2),1,wid*wid);
                patchg(numAll,:)=(patchg(numAll,:)-mean(patchg(numAll,:)))/std(patchg(numAll,:));
                patchb(numAll,:)=reshape(B(:,:,3),1,wid*wid);
                patchb(numAll,:)=(patchb(numAll,:)-mean(patchb(numAll,:)))/std(patchb(numAll,:));
            else
                patchr(numAll,:)=reshape(B(:,:),1,wid*wid);
                patchr(numAll,:)=(patchr(numAll,:)-mean(patchr(numAll,:)))/std(patchr(numAll,:));
            end
        end
    end
end
if numAll>=5
    if c==3
        ascore=mean(std(patchr))+mean(std(patchg))+mean(std(patchb));
    else
        ascore=mean(std(patchr));
    end
    ascore=ascore/(3*numCompQuad+numSemiQuad);
else
    ascore=1000;
end
%maps image texton corners to canonical texton corners


