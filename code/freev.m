%%
win.rect                     = [0 0 1920 1080];                                  %  horizontal x vertical resolution [pixels]
win.calibType               = 'HV9';
win.margin                  = [16 5];
mPix                        = win.rect(3:4).*win.margin/100;
if strcmp(win.calibType,'HV9')                                              % positions of calibration dots
   dotinfo.calibpos(1:9,1)  = repmat(mPix(1):(win.rect(3)-2*(mPix(1)))/2:win.rect(3)-mPix(1),1,3);
   dotinfo.calibpos(1:9,2)  = reshape(repmat(mPix(2):(win.rect(4)-2*(mPix(2)))/2:win.rect(4)-mPix(2),3,1),9,1);
end

[trial,meta] = totrial('/Users/jossando/trabajo/India/data/s01/s01C.edf',{'raw','gaze'});

%[trial,meta] = totrial('/Users/jossando/trabajo/India/data/s03/s03.edf',{'raw','gaze'});
%[trial,meta] =totrial('/Users/jossando/trabajo/India/data/images/sanwar/sanwar.edf',{'raw','gaze'});
tr = 1;
if isfield(trial(tr).left,'saccade')
    useye = 'left';
else
    useye = 'right';
end
dotinfo.tstart_dots = trial(tr).dotpos.time(1:9);
dotinfo.dot_order   = str2num(trial(tr).dotpos.msg(1:9));
[ux,uy,xyP,xyR,xgaz,ygaz] = calibdata(trial(tr).(useye).samples,trial(tr).(useye).saccade,win,...
   dotinfo,'sample',1);
doimage(gcf,'/Users/jossando/trabajo/India/result/sanwar/','png',['calib_' num2str(tr)],1);

% for trr=24:34
%     figure
%     im = imread(['/Users/jossando/trabajo/India/images/' trial(trr).category.msg '/' trial(trr).image.msg '.png']);
%     imshow(im),hold on
%     [xgaz,ygaz] = correct_raw(ux,uy,trial(trr).(useye).samples.rawx',trial(trr).(useye).samples.rawy')
%     plot(xgaz-(win.rect(3)-size(im,2))/2,ygaz-(win.rect(4)-size(im,1))/2,'.r')
%     doimage(gcf,'/Users/jossando/trabajo/India/result/sanwar/','png',[trial(trr).category.msg '_' trial(trr).image.msg],1);
% end
