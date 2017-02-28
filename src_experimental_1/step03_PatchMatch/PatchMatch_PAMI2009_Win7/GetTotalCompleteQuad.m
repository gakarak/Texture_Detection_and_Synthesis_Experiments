
function [ccnt,semicnt]=GetTotalCompleteQuad(mIsGood)
%first looking for complete quadratirals......
ccnt=0;
semicnt=0;
[h,w]=size(mIsGood);
for y=1:h-1
    for x=1:w-1
        flag=0;
        flag=mIsGood(y,x)+mIsGood(y+1,x)+mIsGood(y,x+1);
        flag=flag+mIsGood(y+1,x+1);
        if flag ==4
            ccnt=ccnt+1;            
        elseif flag==3
            semicnt=semicnt+1;
            semicnt=semicnt+1;
        end
    end
end