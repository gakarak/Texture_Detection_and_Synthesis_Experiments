function drawLatticeFromProposalCell(cPTS,color,markersize,linewidth)
[m,n]=size(cPTS);
if nargin <2
    color='r';
    markersize=4;
    linewidth=1;
   
elseif nargin <3
    markersize=4;
    
    
elseif nargin<4
    linewidth=1;       
end
mIsGood=zeros(m,n);
for y=1:m
    for x=1:n
        if ~isempty(cPTS{y,x})
            mIsGood(y,x)=1;
        end
    end
end
hold on;
for y=1:m
    for x=1:n

        if x+1<=n

            if mIsGood(y,x)==1 &&mIsGood(y,x+1)==1
                xx=[cPTS{y,x}(1),cPTS{y,x+1}(1)];
                yy=[cPTS{y,x}(2),cPTS{y,x+1}(2)];
                plot(xx,yy,color,'linewidth',linewidth);
            end

        end
        if y+1<=m
            if mIsGood(y,x)==1&&mIsGood(y+1,x)==1
                xx=[cPTS{y,x}(1),cPTS{y+1,x}(1)];
                yy=[cPTS{y,x}(2),cPTS{y+1,x}(2)];
                plot(xx,yy,color,'linewidth',linewidth);
            end

        end
    end
end

for y=1:m
    for x=1:n

        if mIsGood(y,x)==1
            xx=[cPTS{y,x}(1)];
            yy=[cPTS{y,x}(2)];

            flag=0;
            if x+1 <=n
                flag=flag|mIsGood(y,x+1);
            end
            if y+1 <=m
                flag=flag|mIsGood(y+1,x);
            end
            if y-1 >=1
                flag=flag|mIsGood(y-1,x);
            end
            if x-1 >=1
                flag=flag|mIsGood(y,x-1);
            end

            if mIsGood(y,x)==1 && flag
                plot(xx,yy,'V','color',color,'MarkerFaceColor','y','MarkerSize',markersize);
            else
                plot(xx,yy,'Marker', 'd','color',color,'MarkerFaceColor','b','MarkerSize',markersize);
            end
        end

    end
end
hold off;