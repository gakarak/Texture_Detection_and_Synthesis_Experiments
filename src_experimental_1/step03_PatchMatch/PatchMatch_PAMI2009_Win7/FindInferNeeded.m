function mInferNeeded=FindInferNeeded(mIsMaxConnected)
[mh,mw]=size(mIsMaxConnected);

SE=strel('square',3);


mInferNeeded=imdilate(mIsMaxConnected,SE)-mIsMaxConnected;