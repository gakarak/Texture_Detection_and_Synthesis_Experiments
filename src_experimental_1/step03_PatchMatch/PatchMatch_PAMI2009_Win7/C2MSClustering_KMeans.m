function clusters=C2MSClustering_KMeans(rgb,pts,s,param1)%s=7,param1=50
%rgb: input image array
%pts: interesting point
%s: smoothing parameter for meanshift clustering....
%param1: if a cluster has more than param1, the cluster should be divided
%for that we use K-means...
gim=rgb2gray(rgb);
pts=round(pts);
gim=double(gim);
cnt=0;
newpt=[];
wid=5;
[h,w,c]=size(rgb);
for i=1:size(pts,2)
    if pts(1,i)-wid>=1 &&pts(1,i)+wid<=w && pts(2,i)-wid>=1 && pts(2,i)+wid<=h
        tmp=gim(pts(2,i)-wid:pts(2,i)+wid,pts(1,i)-wid:pts(1,i)+wid);
        tmp=reshape(tmp,1,(wid*2+1)*(wid*2+1));
        tmp=(tmp-mean(tmp))/std(tmp);
        cnt=cnt+1;
        vec(1:(wid*2+1)*(wid*2+1),cnt)=tmp;
        newpt(:,cnt)=pts(:,i);
    end
end
pts=newpt;

if ismac
    tic
    [mu,c,band]=OSX_CPPMeanShiftCluster(vec,s);
    toc
else
    tic
    [mu,c,band]=CPPMeanShiftCluster(vec,s);
    toc
end

icnt=1;
clusters=cell(1,1);
groupCnt=size(mu,2);
for i=1:groupCnt
    groupi=find(c==i);
    len=length(groupi);
    OPOP=0;
    if len>param1 && OPOP==0
        K=ceil(len/param1);
        [kc,kmu]=kmeans(vec(:,groupi)',K);
      
        tmppts=pts(:,groupi);
        for mem=1:K
            iiidx=find(kc==mem);
            if length(iiidx)>5
                
                clusters{icnt}=tmppts(:,iiidx);
                icnt=icnt+1;
            end
        end
    else
        if len >5
            clusters{icnt}=pts(:,groupi);
            icnt=icnt+1;            
        end
    end
end
