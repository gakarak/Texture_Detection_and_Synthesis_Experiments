% Only Top 3 are return based on the numnber of semi+complete quads...
clear all;
path='C:\LatticeData\';
str='BlockWiseKLT';
strVersion='out';
prefix=cell(1,1);

prefix{1}='im';
prefix{2}='layer';
prefix{3}='gb';
prefix{4}='noise';


fileidx=1;
nMode=1;
bFirst=1;
si=[0 0 201 150];%13 52 failed...
ei=[5 3 201 950];


for mmm=4:4
    for fileidx=si(mmm):50:ei(mmm)  %gb111 ???....layer059 ???..???
        filepath=sprintf('%s%s%.3d.jpg',path,prefix{mmm},fileidx);

        ttt=dir(filepath)
        if length(ttt)>0

            [rgb,pts,mIdxT1T2,cMemberPT,cCellMPT,mAscore,retClusters]=PhaseI(filepath,7);
            savepath=sprintf('%s%s\\',path,strVersion);
            if bFirst==1
                mkdir(savepath);
                bFirst=0;
            end
            for i=1:length(retClusters)

                [h,w,c]=size(rgb);

                reti=mIdxT1T2(i,1:3);
                if mIdxT1T2(i,4)>=3
                    member=cMemberPT{i};
                    if ~isempty(member)
                        pt_sel=retClusters{i};

                        handle=figure(1);

                        clf;imshow(rgb);hold on;

                        plot(pts(1,:),pts(2,:),'o','color','w','MarkerFaceColor','b','MarkerSize',3);
                        plot(pt_sel(1,:),pt_sel(2,:),'o','color','r','MarkerFaceColor','c','MarkerSize',8);
                        plot(member(1,:),member(2,:),'V','color','r','MarkerFaceColor','y','MarkerSize',5);

                        t1=[pt_sel(:,reti(2)) pt_sel(:,reti(1))];
                        t2=[pt_sel(:,reti(3)) pt_sel(:,reti(1))];

                        cTmpMPT=cCellMPT{i};
                        save(sprintf('%sproposal%s%.6d_%.2d.mat',savepath,prefix{mmm},fileidx,i),'t1','t2','cTmpMPT');


                        plot(t1(1,:),t1(2,:),'y','linewidth',4);
                        plot(t2(1,:),t2(2,:),'y','linewidth',4);
                        plot(pt_sel(1,:),pt_sel(2,:),'o','color','r','MarkerFaceColor','c','MarkerSize',8);
                        [h,w,c]=size(rgb);
                        set(handle,'Position',[100 100 w+200 h+100]);
                        set(handle,'PaperUnits','points','PaperSize',[w+200 h+100]);
                        title(sprintf('t1t2 proposal inlier(%d,%f) Modified Ascore %f)',mIdxT1T2(i,4),mIdxT1T2(i,4)/size(pt_sel,2),mAscore(i)));axis off;
                        legend(str,'MS clustering','t_1,t_2 member','t_1,t_2 proposal','location','EastOutside');
                        text(w/2,h+30,'t_1 and t_2 Proposal','HorizontalAlignment','center');

                        hold off;
                        drawLatticeFromProposalCell(cCellMPT{i},'r',5);
                        hold on;
                        plot(t1(1,:),t1(2,:),'k','linewidth',6);
                        plot(t2(1,:),t2(2,:),'k','linewidth',6);
                        plot(t1(1,:),t1(2,:),'y','linewidth',2);
                        plot(t2(1,:),t2(2,:),'y','linewidth',2);
                        print('-f1','-djpeg','-r300',sprintf('%sc1_c6v4%s%s%.6d_%.2d.jpg',savepath,str,prefix{mmm},fileidx,i)  );
                        hold off;
                        clear pt_sel;

                    end
                end
            end
            % clear rgb;
            % clear mIdxT1T2;
            % clear cMemberPT;
            % clear cCellMPT;
            % clear retClusters;
        end

    end
end

%
%
%
% temporary....
%
%
%

