function drawLatticeFromCell(cPTS,color,mIsBoundary,mIsGood,markersize)
[m,n]=size(cPTS);
if nargin <2
    color='r';
    IsHole=zeros(m,n);
    markersize=1;
elseif nargin <3
    IsHole=zeros(m,n);
    markersize=1;
elseif nargin<5
    markersize=4;
end

hold on;
for y=1:m
    for x=1:n

        if x+1<=n

            if mIsBoundary(y,x)~=1 && mIsBoundary(y,x+1)~=1 &&mIsGood(y,x)>0 &&mIsGood(y,x+1)>0
            xx=[cPTS{y,x}(1),cPTS{y,x+1}(1)];
            yy=[cPTS{y,x}(2),cPTS{y,x+1}(2)];
            plot(xx,yy,color,'linewidth',1);
            end

        end
        if y+1<=m
            if mIsBoundary(y,x)~=1 && mIsBoundary(y+1,x)~=1 && mIsGood(y,x)>0&&mIsGood(y+1,x)>0
            xx=[cPTS{y,x}(1),cPTS{y+1,x}(1)];
            yy=[cPTS{y,x}(2),cPTS{y+1,x}(2)];
            plot(xx,yy,color,'linewidth',1);
            end

        end
    end
end

for y=1:m
    for x=1:n
        if mIsBoundary(y,x)~=1
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
            
            if mIsGood(y,x)>0 && flag
               plot(xx,yy,'V','color',color,'MarkerFaceColor','y','MarkerSize',markersize);
            else
               % plot(xx,yy,'Marker', 'd','color',color,'MarkerFaceColor','b','MarkerSize',markersize);
            end
        end
        if mIsBoundary(y,x)==1
            
           % xx=[cPTS{y,x}(1)-10 ,cPTS{y,x}(1)+10];
           % yy=[cPTS{y,x}(2)-10 ,cPTS{y,x}(2)+10];
           % plot(xx,yy,'b','linewidth',1);
           % xx=[cPTS{y,x}(1)+10, cPTS{y,x}(1)-10];
           % yy=[cPTS{y,x}(2)-10, cPTS{y,x}(2)+10];
           % plot(xx,yy,'b','linewidth',1);

        end
    end
end
hold off;