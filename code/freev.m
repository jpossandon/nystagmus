% %%
% win.rect                     = [0 0 1920 1080];                                  %  horizontal x vertical resolution [pixels]
% win.calibType               = 'HV9';
% win.margin                  = [16 5];
% mPix                        = win.rect(3:4).*win.margin/100;
% if strcmp(win.calibType,'HV9')                                              % positions of calibration dots
%    dotinfo.calibpos(1:9,1)  = repmat(mPix(1):(win.rect(3)-2*(mPix(1)))/2:win.rect(3)-mPix(1),1,3);
%    dotinfo.calibpos(1:9,2)  = reshape(repmat(mPix(2):(win.rect(4)-2*(mPix(2)))/2:win.rect(4)-mPix(2),3,1),9,1);
% end
% 
% [trial,meta] = totrial('/Users/jossando/trabajo/India/data/031117/s01/s01.edf',{'raw','gaze'});
% 
% %[trial,meta] = totrial('/Users/jossando/trabajo/India/data/s03/s03.edf',{'raw','gaze'});
% %[trial,meta] =totrial('/Users/jossando/trabajo/India/data/images/sanwar/sanwar.edf',{'raw','gaze'});
% tr = 22;
% if isfield(trial(tr).left,'saccade')
%     useye = 'left';
% else
%     useye = 'right';
% end
% dotinfo.tstart_dots = trial(tr).dotpos.time(end-9:end);
% dotinfo.dot_order   = str2num(trial(tr).dotpos.msg(end-9:end));
% [ux,uy,xyP,xyR,xgaz,ygaz] = calibdata(trial(tr).(useye).samples,trial(tr).(useye).saccade,win,...
%    dotinfo,'saccade',1);
% doimage(gcf,'/Users/jossando/trabajo/India/result/031117/','png',['calib_' num2str(tr)],1);
% 
% for trr=23:42
%     try
%     figure
%     im = imread(['/Users/jossando/trabajo/India/images/' trial(trr).category.msg '/' trial(trr).image.msg '.png']);
%     imshow(im),hold on
%     [xgaz,ygaz] = correct_raw(ux,uy,trial(trr).(useye).samples.rawx',trial(trr).(useye).samples.rawy')
%     plot(xgaz-(win.rect(3)-size(im,2))/2,ygaz-(win.rect(4)-size(im,1))/2,'.r')
%     doimage(gcf,'/Users/jossando/trabajo/India/result/031117/','png',[trial(trr).category.msg '_' trial(trr).image.msg],1);
%     catch
%         trr
%     end
%     
% end

%% new setup
%%
sid             = 's030';
task            = 'ID';
load(['/Users/jossando/trabajo/India/data/' sid '/' sid task '.mat'])

%  win.rect                    = [0 0 1920 1080];                                  %  horizontal x vertical resolution [pixels]
%  win.calibType               = 'HV9';
%  win.margin                  = [20 16];
%  mPix                        = win.rect(3:4).*win.margin/100;
%   dotinfo.calibpos(1:9,1)  = repmat(mPix(1):(win.rect(3)-2*(mPix(1)))/2:win.rect(3)-mPix(1),1,3);
%      dotinfo.calibpos(1:9,2)  = reshape(repmat(mPix(2):(win.rect(4)-2*(mPix(2)))/2:win.rect(4)-mPix(2),3,1),9,1);
% % dotinfo.tstart_dots = trial(1).dotstart.time
% % dotinfo.tend_dots = trial(1).dotend.time
% dotinfo.tstart_dots = str2double(cellstr(trial(1).dotstart.msg));
% dotinfo.tend_dots = str2double(cellstr(trial(1).dotend.msg));
% dotinfo.dot_order = str2double(cellstr(trial(1).dotpos.msg));
     % if strcmp(win.calibType,'HV5') 
%     % remove outer points, as currently not used
%     dotinfo.calibpos([1 3 7 9],:)=[];
%     
% end
[trial,meta] = totrial(['/Users/jossando/trabajo/India/data/' sid '/' sid task '.edf'],{'raw','gaze'});

%%
tr = 1;
method = 'saccade';
method = 'sample';
for ey = 1:2
    if ey ==1 && isfield(trial(tr).left,'saccade')
        useye = 'left';
    elseif ey ==2 && isfield(trial(tr).right,'saccade')
        useye = 'right';
    end
% load(['/Users/jossando/trabajo/India/data/' sid '/' sid 'ID.mat'])
%  dotinfo = win.calib.dotinfo(ey);
%  trial(tr).(useye).samples.time = trial(tr).(useye).samples.pctime; 
% [caldata,xgaz,ygaz] = calibdata(trial(tr).(useye).samples,trial(tr).(useye).saccade,win,dotinfo,'saccade',1);
   [caldata(ey),xgaz,ygaz] = calibdata(win.calib.caldata(ey).samples,[],win,win.calib.dotinfo(ey),'sample',1);

  % doimage(gcf,['/Users/jossando/trabajo/India/result/' sid '/'],'png',['calib_' num2str(tr)],1);
end
%%
eyec = {'b','r'};
driftcor = 1
for trr=10:20
    try
    figure
    if strcmp(task,'ID')
        im = imread(['/Users/jossando/trabajo/India/images/33/' trial(trr).image.msg]);
    elseif strcmp(task,'OBJ')
        im = imread(['/Users/jossando/trabajo/India/images/34/' trial(trr).image.msg]);
    end
    imshow(im),hold on
    for ey = 1:2
        if driftcor
            xdriftc = trial(trr).(useye).samples.rawx'-nanmedian(trial(trr).(useye).samples.rawx(indxdrift)')+caldata(ey).rawCenter(1);
            ydriftc = trial(trr).(useye).samples.rawy'-nanmedian(trial(trr).(useye).samples.rawy(indxdrift)')+caldata(ey).rawCenter(2);
            [xgaz,ygaz] = correct_raw(xdriftc,ydriftc,caldata(ey));
        else
            [xgaz,ygaz] = correct_raw(trial(trr).(useye).samples.rawx',trial(trr).(useye).samples.rawy',caldata(ey));
        end
%       indxdrift = find(trial(trr).(useye).samples.time<0)
%       
%       [xgaz,ygaz] = correct_raw(trial(trr).(useye).samples.rawx'-nanmedian(trial(trr).(useye).samples.rawx(indxdrift)'),...
%           trial(trr).(useye).samples.rawy'-nanmedian(trial(trr).(useye).samples.rawy(indxdrift)'),caldata(ey));
%     
%       xdrift  = win.rect(3)/2-nanmedian(xgaz(indxdrift));
%       ydrift  = win.rect(4)/2-nanmedian(ygaz(indxdrift));
%       xgaz    = xgaz-xdrift;
%      ygaz    = ygaz-ydrift;
%     
        plot(xgaz-(win.rect(3)-size(im,2))/2,ygaz-(win.rect(4)-size(im,1))/2,['.' eyec{ey}])
        
    end
    figure,plot(xgaz(xgaz>-500 & xgaz<2000))
%       doimage(gcf,['/Users/jossando/trabajo/India/result/' sid '/'],'png',[trial(trr).image.msg '_' trial(trr).pair_order.msg],1);
    catch
        trr
    end
    
end