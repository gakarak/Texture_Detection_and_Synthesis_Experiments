

function [sad,var,maxdiff]=cellSADDev(c1,c2)
[h,w]=size(c1);
total=0;
data=[];
cnt=1;
for m=1:h
    for n=1:w
        k=abs(c1{m,n}-c2{m,n});
        data(cnt)=sum(k);
        cnt=cnt+1;
        total=total+sum(k);
    end
end
var=std(data);
maxdiff=max(data);
sad=total;
