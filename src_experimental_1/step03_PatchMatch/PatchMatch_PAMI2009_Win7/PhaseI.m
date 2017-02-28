function [rgb,pts,mIdxT1T2,cMemberPT,cCellMPT,mAscore,retClusters]=PhaseI(filepath,topN)
%filepath: path to input image....
%topN: We only collect topN number of proposals...
pts=[];
mIdxT1T2=[];
cCellMPT=[];
mAscore=[];
retClusters=[];
cMemberPT=[];
window=3;
qual=0.1;
ptNum=30;
automatic=1;
s=7;
param1=100;
maxit=2000;
error=0.1;

[pts]=C1_BWKLT(filepath,window,qual,ptNum,automatic);
rgb=imread(filepath);
cClusters=C2MSClustering_KMeans(rgb,pts,s,param1);

if ~isempty(cClusters{1})
    %[mIdxT1T2,cMemberPT,cCellMPT,]=fastC6v5_TopN(cClusters,maxit,error,rgb,topN);
    [mIdxT1T2,cMemberPT,cCellMPT,mAscore,retClusters]=fastC6v5_TopNAscoreWOTPS(cClusters,maxit,error,rgb,topN);
    
    %[mIdxT1T2,cMemberPT,cCellMPT,mAscore,retClusters]=fastC6v5_Top3Ncc(cClusters,maxit,error,rgb,topN);
    %mIdxT1T2 is proposal
    %cMemberPT is supporting member for the proposal
    %cCellMPT is geometric deployment of the pts
    %mAscore A-score for every proposal
    %retClusters is the corresponding pts within clusters including
    %outliers and inliers....
end

clear cClusters;
