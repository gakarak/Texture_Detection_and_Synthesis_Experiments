%from clustered feature location
% we want to find t1 t2 vector......
% we are doing RANSAC for this or........
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%    v5 considers shortest t1,t2 vector and make it consistent with
%       supporting members and shows as connected lattice.....
%     And shows the number of complete quads and semi complete quads
%       to see it can be used as criterion to select good proposals...
%     "This version return top 3 w.r.t the number of complete quad+semi
%     quads"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mIdxT1T2,cMember,cCellMPT,mAscores,retClusters]=fastC6v5_TopNAscoreWOTPS(clusters,maxit,error,rgb,topN)

len=length(clusters);
mIdxT1T2Cnt=[];
cMember=cell(1,len);
cCellMPT=cell(1,1);
mAscores=[];
retClusters=cell(1,1);
rgb=im2double(rgb);
imgray=rgb2gray(rgb);
pcnt=0;

for i=1:len %len

    pts=clusters{i};
    [m,n]=size(pts);
    if 1

        if ismac
        [ret_i,tmp,membercnt,mX,mY]=OSX_CPPRansacToGetAffineClosestN(pts,maxit,error,8,20);
        else
        [ret_i,tmp,membercnt,mX,mY]=CPPRansacToGetAffineClosestN(pts,maxit,error,8,20);
        end
        [mh,mw]=size(mX);
        cMPT=cell(mh,mw);
        for yy=1:mh

            for xx=1:mw
                if mX(yy,xx)==-1
                    cMPT{yy,xx}=[];
                else
                    cMPT{yy,xx}=[mX(yy,xx);mY(yy,xx)];
                end
            end
        end

        [ddd,cnt]=size(tmp);
        if cnt>3
            pcnt=pcnt+1;
            cMember{pcnt}=tmp;
            mIdxT1T2(pcnt,1:3)=ret_i;
            mIdxT1T2(pcnt,4)=membercnt;
            cCellMPT{pcnt}=cMPT;
            retClusters{pcnt}=pts;
            %cMPT sometimes has two points.......that is weird
            %check it later.....


            %figure(9);
            %imshow(rgb); drawLatticeFromProposalCell(cMPT,'r',5);
            %pause;
            try
            ascore= GetAScoreForCompQuad(cMPT, rgb)
            catch
               ascore=1000; 
            end
            mAscores(pcnt)=ascore;


            %[ccnt,semicnt]=GetNumberOfCompleteQuadAndSemiQuad(cMPT);
            %CompQuadCnt(i)=ccnt;
            %SemiQuadCnt(i)=semicnt;

        end
    end
end

%we do the TPS WARPING and get A-score.......



[sorted,oidx]=sortrows(mAscores');

topN=topN;
cCellNewMPT=cell(1,1);
newRetClusters=cell(1,1);
mNewIdxT1T2=[];
newmAscores=[];
cNewMember=cell(1,1);

% ratio_thresh = 0.5;
% k = 1;
% while k < min(topN, pcnt+1) %top3..... if
%     pt_sel=retClusters{oidx(k)};
%     reti=mIdxT1T2(oidx(k),1:3);
%     t1=[pt_sel(:,reti(2)) pt_sel(:,reti(1))]; %[x1 x2; y1 y2]
%     t2=[pt_sel(:,reti(3)) pt_sel(:,reti(1))];
%     t1_len = sqrt((t1(1, 1) - t1(1, 2))^2 + (t1(2, 1) - t1(2, 2))^2);
%     t2_len = sqrt((t2(1, 1) - t2(1, 2))^2 + (t2(2, 1) - t2(2, 2))^2);
%     ratio = min(t1_len, t2_len)/max(t1_len, t2_len)
%     if  ratio > ratio_thresh
%         mNewIdxT1T2(k,1:4)=mIdxT1T2(oidx(k),1:4);
%         newmAscores(k)=mAscores(oidx(k));
%         cCellNewMPT{k}=cCellMPT{oidx(k)};
%         newRetClusters{k}=retClusters{oidx(k)};
%         cNewMember{k}=cMember{oidx(k)};
%     end
%     k = k + 1;
% end

for k=1:topN %top3..... if
    if k<=pcnt
        mNewIdxT1T2(k,1:4)=mIdxT1T2(oidx(k),1:4);
        newmAscores(k)=mAscores(oidx(k));
        cCellNewMPT{k}=cCellMPT{oidx(k)};
        newRetClusters{k}=retClusters{oidx(k)};
        cNewMember{k}=cMember{oidx(k)};
    end
end

mAscores=newmAscores;
cCellMPT=cCellNewMPT;
mIdxT1T2=mNewIdxT1T2;
cMember=cNewMember;
retClusters=newRetClusters;


function [ccnt,semicnt]=GetNumberOfCompleteQuadAndSemiQuad(cMPT)
%first looking for complete quadratirals......
ccnt=0;
semicnt=0;
[h,w]=size(cMPT);
for y=1:h-1
    for x=1:w-1
        flag=isempty(cMPT{y,x})+isempty(cMPT{y+1,x})+isempty(cMPT{y,x+1});
        flag=flag+isempty(cMPT{y+1,x+1});
        if flag ==0
            ccnt=ccnt+1;
            semicnt=semicnt+1;
        elseif flag==1
            semicnt=semicnt+1;
        end
    end
end


%then transform all the points to the same coordinate for
%comparisons........




