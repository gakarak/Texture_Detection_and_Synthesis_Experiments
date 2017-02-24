function Ans = getxcorr2(A,B)


if ( size(A,3) == size(B,3) )
    Ans = xcorr2(A(:,:,1),B(:,:,1));
    for i = 2 : size(A,3)
        Ans = Ans + xcorr2(A(:,:,i),B(:,:,i));
    end
else
    if( size(B,3) ==1)
        Ans = xcorr2(A(:,:,1),B(:,:));
        for i = 2 : size(A,3)
            Ans = Ans + xcorr2(A(:,:,i),B(:,:));
        end
    else
        if(size(A,3)==1)
            Ans = getxcorr2(B,A);
        else
            Ans = xcorr2(A(:,:,1),B(:,:,1));
        end
    end
end