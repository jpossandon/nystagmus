%%
win.rect                     = [0 0 1920 1080];                                  %  horizontal x vertical resolution [pixels]
win.calibType               = 'HV9';
win.margin                  = [16 5];
mPix                        = win.rect(3:4).*win.margin/100;
if strcmp(win.calibType,'HV9')                                              % positions of calibration dots
   dotinfo.calibpos(1:9,1)  = repmat(mPix(1):(win.rect(3)-2*(mPix(1)))/2:win.rect(3)-mPix(1),1,3);
   dotinfo.calibpos(1:9,2)  = reshape(repmat(mPix(2):(win.rect(4)-2*(mPix(2)))/2:win.rect(4)-mPix(2),3,1),9,1);
end

[trial,meta] = totrial('/Users/jossando/trabajo/India/data/031117/s01/s01.edf',{'raw','gaze'});

%[trial,meta] = totrial('/Users/jossando/trabajo/India/data/s03/s03.edf',{'raw','gaze'});
%[trial,meta] =totrial('/Users/jossando/trabajo/India/data/images/sanwar/sanwar.edf',{'raw','gaze'});
tr = 22;
if isfield(trial(tr).left,'saccade')
    useye = 'left';
else
    useye = 'right';
end
dotinfo.tstart_dots = trial(tr).dotpos.time(end-9:end);
dotinfo.dot_order   = str2num(trial(tr).dotpos.msg(end-9:end));
[ux,uy,xyP,xyR,xgaz,ygaz] = calibdata(trial(tr).(useye).samples,trial(tr).(useye).saccade,win,...
   dotinfo,'saccade',1);
doimage(gcf,'/Users/jossando/trabajo/India/result/031117/','png',['calib_' num2str(tr)],1);

for trr=23:42
    try
    figure
    im = imread(['/Users/jossando/trabajo/India/images/' trial(trr).category.msg '/' trial(trr).image.msg '.png']);
    imshow(im),hold on
    [xgaz,ygaz] = correct_raw(ux,uy,trial(trr).(useye).samples.rawx',trial(trr).(useye).samples.rawy')
    plot(xgaz-(win.rect(3)-size(im,2))/2,ygaz-(win.rect(4)-size(im,1))/2,'.r')
    doimage(gcf,'/Users/jossando/trabajo/India/result/031117/','png',[trial(trr).category.msg '_' trial(trr).image.msg],1);
    catch
        trr
    end
    
end

%% new setup
%%
sid             = 's78';
win.rect                    = [0 0 1920 1080];                                  %  horizontal x vertical resolution [pixels]
win.calibType               = 'HV9';
win.margin                  = [20 16];
mPix                        = win.rect(3:4).*win.margin/100;
if strcmp(win.calibType,'HV9')                                              % positions of calibration dots
   dotinfo.calibpos(1:9,1)  = repmat(mPix(1):(win.rect(3)-2*(mPix(1)))/2:win.rect(3)-mPix(1),1,3);
   dotinfo.calibpos(1:9,2)  = reshape(repmat(mPix(2):(win.rect(4)-2*(mPix(2)))/2:win.rect(4)-mPix(2),3,1),9,1);
end
[trial,meta] = totrial(['/Users/jossando/trabajo/India/data/' sid '/' sid '.edf'],{'raw','gaze'});
tr = 1;
if isfield(trial(tr).left,'saccade')
    useye = 'left';
else
    useye = 'right';
end
dotinfo.tstart_dots = trial(tr).dotpos.time(end-9:end);
dotinfo.tend_dots   = [trial(tr).dotpos.time(end-8:end) trial(tr).dotpos.time(end)+2000]
dotinfo.dot_order   = str2num(trial(tr).dotpos.msg(end-9:end));
[ux,uy,xyP,xyR,xgaz,ygaz] = calibdata(trial(tr).(useye).samples,trial(tr).(useye).saccade,win,dotinfo,'sample',1);
% doimage(gcf,['/Users/jossando/trabajo/India/result/' sid '/'],'png',['calib_' num2str(tr)],1);
