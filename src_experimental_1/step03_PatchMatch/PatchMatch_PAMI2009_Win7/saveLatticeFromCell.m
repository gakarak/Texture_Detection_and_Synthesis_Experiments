function [qx,qy,qg] = saveLatticeFromCell(cPTS,mIsBoundary,mIsGood, folder_path)
[m,n]=size(cPTS);

pts_x = zeros(size(cPTS));
pts_y = zeros(size(cPTS));
is_good = zeros(size(cPTS));

for y=1:m
    for x=1:n
        
        pts_x(y,x) = cPTS{y,x}(1);
        pts_y(y,x) = cPTS{y,x}(2);
        
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
               is_good(y,x) = 1;
            end
    end
end

csvwrite(sprintf('%s/pts_x.csv', folder_path), pts_x);
csvwrite(sprintf('%s/pts_y.csv', folder_path), pts_y);
csvwrite(sprintf('%s/is_good.csv', folder_path), is_good);

q1=cell2mat(cPTS);
qx=q1(1:2:end,:);
qy=q1(2:2:end,:);
qg=mIsGood;


