%%
win.rect                     = [0 0 1920 1080];                                  %  horizontal x vertical resolution [pixels]
win.calibType               = 'HV9';
win.margin                  = [16 5];
mPix                        = win.rect(3:4).*win.margin/100;
if strcmp(win.calibType,'HV9')                                              % positions of calibration dots
   xy(1:9,1)  = repmat(mPix(1):(win.rect(3)-2*(mPix(1)))/2:win.rect(3)-mPix(1),1,3);
   xy(1:9,2)  = reshape(repmat(mPix(2):(win.rect(4)-2*(mPix(2)))/2:win.rect(4)-mPix(2),3,1),9,1);
end

[trial,meta] =totrial('/Users/jossando/trabajo/nystagmus/data/s03/s03.edf',{'raw','gaze'});
%[trial,meta] =totrial('/Users/jossando/trabajo/nystagmus/data/images/sanwar/sanwar.edf',{'raw','gaze'});
tr = 1;
[ux,uy,xgaz,ygaz] = calibdata(trial(tr).left.samples.rawx',trial(tr).left.samples.rawy',...
    trial(tr).left.samples.time,...
   xy,trial(tr).dotpos.time(1:9),str2num(trial(tr).dotpos.msg(1:9)));

for trr=2:32
    figure
    imshow(['/Users/jossando/trabajo/nystagmus/images/' trial(trr).category.msg '/' trial(trr).image.msg '.png']),hold on
    [xgaz,ygaz] = correct_raw(ux,uy,trial(trr).left.samples.rawx',trial(trr).left.samples.rawy')
    plot(xgaz-320,ygaz-30,'.k')
%     doimage(gcf,'/Users/jossando/trabajo/nystagmus/result/','png',[trial(trr).category.msg '_' trial(trr).image.msg],1);
end
