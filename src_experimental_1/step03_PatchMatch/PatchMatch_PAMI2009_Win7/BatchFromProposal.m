% Only Top 3 are return based on the numnber of semi+complete quads...
clear all;
path='C:\LatticeData\';
prefix='im';
proposalpath='C:\LatticeData\out\';

fileidx=1;
nMode=1;
bFirst=1;

markersize=4;
if length(prefix)==2
    if prefix=='gb'
        markersize=2;
    end
end
prefix=cell(1,1);
prefix{1}='im';
prefix{2}='layer';
prefix{3}='gb';
si=[0 0 201];%13 52 failed...
ei=[0 78 201];
markersize=[4 4 2];

for mmm=3:3
    %for fileidx=4:72%gb111 ???....layer059 ???..???
    for fileidx=si(mmm):ei(mmm)
        fname=sprintf('%s%.3d',prefix{mmm},fileidx);

        %filepath=sprintf('%s\\%s.jpg',path,fname);
        filepath=sprintf('%s\\%s.png',path,fname);
        ttt=dir(filepath)
        if length(ttt)>0
            rgb=imread(filepath);
            %[rgb,pts,mIdxT1T2,cMemberPT,cCellMPT,mAscore,retClusters]=PhaseI(filepath);
            s1=cputime;
            for i=7:7
                t=dir(sprintf('%sproposal%s%.6d_%.2d.mat',proposalpath,prefix{mmm},fileidx,i));
                if isempty(t)
                    break;
                end
                load(sprintf('%sproposal%s%.6d_%.2d.mat',proposalpath,prefix{mmm},fileidx,i));


                savepath=sprintf('%sPAMI_D4_doublesw2\\',path);
                mkdir(sprintf('%sPAMI_D4_doublesw2\\%s',path,fname));

                %phase2_3_eachObsfast(rgb,cTmpMPT,t1,t2,savepath,fname,markersize);
                %phase2_3_eachObs(rgb,cTmpMPT,t1,t2,savepath,fname,markersize);
                trial=i;

                t = cputime;
                [fail,cProposalMPT,tp1,tp2]=MakeShortestT(rgb,cTmpMPT,t1,t2);
                if fail==1
                    cProposalMPT=cTmpMPT;
                else
                    t1=tp1;
                    t2=tp2;
                end
                %[rOriginalMPT,cRegMPT,mIsGood,mIsBoundary,boundary_width,bFail]=phase2_3rect_global(rgb,cTmpMPT,t1,t2,savepath,fname,markersize,trial);

                [rOriginalMPT,cRegMPT,mIsGood,mIsBoundary,boundary_width,bFail]=phase2_3rect_global_newpdf3(rgb,cProposalMPT,t1,t2,savepath,fname,markersize(mmm),trial);
                %[rOriginalMPT,cRegMPT,mIsGood,mIsBoundary,boundary_width,bFail]=phase2_iterative(rgb,cTmpMPT,t1,t2,savepath,fname,markersize(mmm),trial);

                e=cputime-t;

                save(sprintf('%s%sresult%d.mat',savepath,fname,i),'e','rOriginalMPT','cRegMPT','mIsGood','mIsBoundary');

                if bFail==0
                    break;
                end
            end
            alle=cputime-s1;
            %            save(sprintf('%s%sresult_final.mat',savepath,fname),'alle','rOriginalMPT','cRegMPT','mIsGood','mIsBoundary');
            %phase2_3fast(rgb,cTmpMPT,t1,t2,savepath,fname,markersize);
            %phase2_3LargeEngine(rgb,cTmpMPT,t1,t2,savepath,fname,markersize);
        end
    end
end


