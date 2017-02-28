close all;
clear all;

%Lattice Detection....

class='txt02_pxy_M';
wdir=sprintf('D:/step03_PatchMatch/data_for_test1/%s/cropped', class);
ratio_thresh = 0.7;
max_tries = 3;
% lstImages = dir([wdir, '/*.jpg']);
% lstImages = dir(sprintf('%s/*.jpg', wdir));
% numImages=numel(lstImages);
% for ii=1:numImages
%     tfn = lstImages(ii).name;
%     tpath = sprintf('%s/%s', wdir, tfn);
%     timg = imread(tpath);
%     timg = timg(180:480, 80:420, :);
%     imwrite(timg, sprintf('%s/%s/%s', wdir, 'cropped', tfn));
% % %     imshow(timg);
% % %     drawnow;
% end
% crop 180:480, 80:420, :



%Start Input setup....
% if ismac
% [filename, pathname, fNum] = uigetfile('*.tif;*.bmp;*.jpg', 'Open Image', [pwd,'/images']);
% else
% [filename, pathname, fNum] = uigetfile('*.tif;*.bmp;*.jpg;*.png', 'Open Image', [pwd,'\images\']);
% end
% 
% if isequal(filename, 0)
%     break;
% end

pathname = wdir;
lstImages = dir(sprintf('%s/*.jpg', wdir));
numImages = numel(lstImages);
for ii=1:numImages
    %filename = '5.jpg';
    filename = lstImages(ii).name;
    inputpath = fullfile(pathname, filename);

    savepath = sprintf('./results/%s/',class)
    fname = [filename(1:size(filename,2)-4),'_result']; % this is to save the final detected lattice....
    %End Input setup....
    intermediatepath=sprintf('%s%s\\',savepath,fname);
    mkdir(savepath);
    mkdir(intermediatepath);


    tic;
    for try_num=1:max_tries
        %Phase I - best t1 t2 proposal......
        [rgb,pts,mIdxT1T2,cMemberPT,cCellMPT,mAscore,retClusters]=PhaseI(inputpath,7);


        [h,w,c]=size(rgb);
        %choose the first with good ratio
        mIdxT1T2_size = size(mIdxT1T2);
        good_idx = -1;
        for i=1:mIdxT1T2_size(1)
            reti=mIdxT1T2(i,1:3);
            if mIdxT1T2(i,4)>=3
                member=cMemberPT{i};
                if ~isempty(member)
                    pt_sel=retClusters{i};

                    %ratio
                    t1=[pt_sel(:,reti(2)) pt_sel(:,reti(1))];
                    t2=[pt_sel(:,reti(3)) pt_sel(:,reti(1))];
                    t1_len = sqrt((t1(1, 1) - t1(1, 2))^2 + (t1(2, 1) - t1(2, 2))^2);
                    t2_len = sqrt((t2(1, 1) - t2(1, 2))^2 + (t2(2, 1) - t2(2, 2))^2);
                    ratio = min(t1_len, t2_len)/max(t1_len, t2_len);
                    if ratio > ratio_thresh
                        fprintf('found good ratio: %d, on i: %d', ratio, i)
                        good_idx = i;
                        break;
                    end
                end
            end
        end

        if good_idx ~= -1 %not found good ratio
            break;
        end
        
        clear rgb;
        clear mIdxT1T2;
        clear cMemberPT;
        clear cCellMPT;
        clear retClusters;
    end
    
    if good_idx == -1
       fprintf('Sorry, couldnt find good ratio for %s', fname);
       continue;
    end
    
    %we just look at the first one with good idx, although we can use the rest of it.....
    i = good_idx
    reti=mIdxT1T2(i,1:3);
    if mIdxT1T2(i,4)>=3
        member=cMemberPT{i};
        if ~isempty(member)
            pt_sel=retClusters{i};
            
            handle=figure(9);

            clf;imshow(rgb);hold on;

            plot(pts(1,:),pts(2,:),'o','color','w','MarkerFaceColor','b','MarkerSize',3);
            plot(pt_sel(1,:),pt_sel(2,:),'o','color','r','MarkerFaceColor','c','MarkerSize',8);
            plot(member(1,:),member(2,:),'V','color','r','MarkerFaceColor','y','MarkerSize',5);
            %t1,t2 vector...........
            t1=[pt_sel(:,reti(2)) pt_sel(:,reti(1))];
            t2=[pt_sel(:,reti(3)) pt_sel(:,reti(1))];
            csvwrite(sprintf('%s%s/t1.csv', savepath, fname), t1)
            csvwrite(sprintf('%s%s/t2.csv', savepath, fname), t2)

            plot(t1(1,:),t1(2,:),'y','linewidth',4);
            plot(t2(1,:),t2(2,:),'y','linewidth',4);
            plot(pt_sel(1,:),pt_sel(2,:),'o','color','r','MarkerFaceColor','c','MarkerSize',8);
            [h,w,c]=size(rgb);
            set(handle,'Position',[100 100 w+200 h+100]);
            set(handle,'PaperUnits','points','PaperSize',[w+200 h+100]);
            title(sprintf('t1t2 proposal inlier(%d,%f) Modified Ascore %f)',mIdxT1T2(i,4),mIdxT1T2(i,4)/size(pt_sel,2),mAscore(i)));axis off;
            legend('KLT','MS clustering','t_1,t_2 member','t_1,t_2 proposal','location','EastOutside');
            text(w/2,h+30,'t_1 and t_2 Proposal','HorizontalAlignment','center');

            hold off;
            drawLatticeFromProposalCell(cCellMPT{i},'r',5);
            hold on;
            plot(t1(1,:),t1(2,:),'k','linewidth',6);
            plot(t2(1,:),t2(2,:),'k','linewidth',6);
            plot(t1(1,:),t1(2,:),'y','linewidth',2);
            plot(t2(1,:),t2(2,:),'y','linewidth',2);
            %print('-f1','-djpeg','-r300',sprintf('%sc1_c6v4%s%s%.6d_%.2d.jpg',savepath,str,prefix{mmm},fileidx,i)  );
            hold off;
            clear pt_sel;
            cTmpMPT=cCellMPT{i};
            %if possible we can adjust t1,t2 vector so that they are close to
            %orthogonal....
            [fail,cProposalMPT,tp1,tp2]=MakeShortestT(rgb,cTmpMPT,t1,t2);
            if fail==1
                cProposalMPT=cTmpMPT;
            else
                t1=tp1;
                t2=tp2;
            end

            %Phase 2 where MRF and MSBP is performed.....
            [rOriginalMPT,cRegMPT,mIsGood,mIsBoundary,boundary_width,bFail]=phase2_3rect_global_newpdf3(rgb,cProposalMPT,t1,t2,savepath,fname,2,i);
            if bFail==0
                e=toc;

                save(sprintf('%s%sresult%d.mat',savepath,fname,i),'e','rOriginalMPT','cRegMPT','mIsGood','mIsBoundary');
            end

        end
    end
    clear rgb;
    clear mIdxT1T2;
    clear cMemberPT;
    clear cCellMPT;
    clear retClusters;
end

