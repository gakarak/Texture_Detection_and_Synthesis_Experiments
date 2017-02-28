function [mIsMaximallyConnected,mIsSubConnected]=FindMaximallyConnected(mIsGood)
idx=find(mIsGood>0);
mIsSubConnected=zeros(size(mIsGood,1),size(mIsGood,2));
if length(idx)>0
    mIsMaximallyConnected=mIsGood;
    [L,num]=bwlabeln(mIsGood,8);
    lens=zeros(1,num);
    for i=1:num
        len=length(find(L==i));
        lens(i)=len;
        if len>10
            mIsSubConnected=mIsSubConnected|(L==i);
        end
    end
    [val,idx]=max(lens);

    mIsMaximallyConnected=double((L==idx));
    idx=find(mIsMaximallyConnected==0);
    mIsGood(idx)=0;
    mIsMaximallyConnected=mIsGood;
else
    mIsMaximallyConnected=0;
    mIsSubConnected=0;
end