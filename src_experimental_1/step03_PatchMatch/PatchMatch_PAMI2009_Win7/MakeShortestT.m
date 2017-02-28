function [fail,cProposalMPT,t1,t2]=MakeShortestT(rgb,cProposalMPT,t1,t2)
[mh,mw]=size(cProposalMPT);
mIsGood=zeros(mh,mw);
for y=1:mh
    for x=1:mw
        if ~isempty(cProposalMPT{y,x})
            pt=cProposalMPT{y,x};
            mIsGood(y,x)=1;
            if pt(1)==t1(1,2) && pt(2)==t1(2,2)%x0
                seed_idx=[x;y];
            elseif pt(1)==t1(1,1) && pt(2)==t1(2,1)%x1
                t1idx=[x;y];
            elseif pt(1)==t2(1,1) && pt(2)==t2(2,1)%x2
                t2idx=[x;y];
            end
        end
    end
end
cRegMPT=cProposalMPT;

%extract rectangular image patch from image centered at x0...
%size about the same as t1,t2 norsms...
t1=t1(:,1)-t1(:,2);
t2=t2(:,1)-t2(:,2);

for y=1:mh
    for x=1:mw
        cRegMPT{y,x}=cProposalMPT{seed_idx(2),seed_idx(1)}+(x-seed_idx(1))*t1+(y-seed_idx(2))*t2;

    end
end
cOriginal=cProposalMPT;


for mm=1:3
    [mh,mw]=size(cProposalMPT);
    midx=0;
    for y=1:mh
        for x=1:mw
            if y<mh && x<mw
                flag=isempty(cRegMPT{y,x})+isempty(cRegMPT{y,x+1})+isempty(cRegMPT{y+1,x})+isempty(cRegMPT{y+1,x+1});
                if flag==0
                    v1=cRegMPT{y,x+1}-cRegMPT{y,x};
                    v2=cRegMPT{y+1,x}-cRegMPT{y,x};
                    v3=cRegMPT{y+1,x+1}-cRegMPT{y,x};
                    testv=[norm(v1) norm(v2) norm(v3)];
                    [mval,midx]=max(testv);
                    break;
                end
            end
        end
    end
    %%rectify the cProposalMPT....so that it can have shortest two t1,t2...
    if midx==1
        cNewMPT=cell(mh+mw,mw);
        cNewRegMPT=cell(mh+mw,mw);
        mIsGood=zeros(mh+mw,mw);
        seed_idx=[seed_idx(1), seed_idx(2)+mw-seed_idx(1)];
        for y=1:mh
            for x=1:mw
                cNewMPT{y+mw-x,x}=cProposalMPT{y,x};
                cNewRegMPT{y+mw-x,x}=cRegMPT{y,x};

                if ~isempty(cProposalMPT{y,x})
                    mIsGood(y+mw-x,x)=1;
                end

            end
        end
    elseif midx==2
        cNewMPT=cell(mh,mw+mh);
        cNewRegMPT=cell(mh,mw+mh);
        mIsGood=zeros(mh,mw+mh);
        seed_idx=[seed_idx(1)+mh-seed_idx(2), seed_idx(2)];
        for x=1:mw
            for y=1:mh
                cNewMPT{y,x+mh-y}=cProposalMPT{y,x};
                cNewRegMPT{y,x+mh-y}=cRegMPT{y,x};
                if ~isempty(cProposalMPT{y,x})
                    mIsGood(y,x+mh-y)=1;
                end
            end
        end
    end

    if midx~=3
        cProposalMPT=cNewMPT;
        cRegMPT=cNewRegMPT;
        [mh,mw]=size(cProposalMPT);
        [mm,nn]=find(mIsGood>0);
        minn=min(nn);
        minm=min(mm);
        maxn=max(nn);
        maxm=max(mm);
        cNewMPT=cell(mh-minm+1-(mh-maxm),mw-minn+1-(mw-maxn));
        cNewRegMPT=cell(mh-minm+1-(mh-maxm),mw-minn+1-(mw-maxn));
        mIsGood=zeros(mh-minm+1-(mh-maxm),mw-minn+1-(mw-maxn));
        seed_idx=[seed_idx(1)-minn+1, seed_idx(2)-minm+1];
        for y=1:mh-minm+1-(mh-maxm)
            for x=1:mw-minn+1-(mw-maxn)
                cNewMPT{y,x}=cProposalMPT{y+minm-1,x+minn-1};
                cNewRegMPT{y,x}=cRegMPT{y+minm-1,x+minn-1};
                if ~isempty(cProposalMPT{y+minm-1,x+minn-1})
                    mIsGood(y,x)=1;
                end
            end
        end
        cProposalMPT=cNewMPT;
        cRegMPT=cNewRegMPT;
    else
        break;
    end
end
[mh,mw]=size(cProposalMPT);
mindist=100000;
for y=1:mh-1
    for x=1:mw-1
        flag=isempty(cProposalMPT{y,x})+isempty(cProposalMPT{y+1,x})+isempty(cProposalMPT{y,x+1});
        if flag==0
            td=(y-seed_idx(2))^2+(x-seed_idx(1))^2;
            if mindist>td
                mindist=td;
                t1=[cProposalMPT{y,x+1} cProposalMPT{y,x}];
                t2=[cProposalMPT{y+1,x} cProposalMPT{y,x}];
            end
        end
    end
end


if mindist==100000
    fail=1
else
    fail=0;
end
display=1;
if display==1
    figure(1);imshow(rgb);drawLatticeFromProposalCell(cOriginal,'k',1,10);
    drawLatticeFromProposalCell(cProposalMPT,'r',5,4);
    hold on;

    plot(t1(1,:),t1(2,:),'g','linewidth',4);
    plot(t2(1,:),t2(2,:),'g','linewidth',4);
    hold off;

end

