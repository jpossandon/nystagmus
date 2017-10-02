% in python
% left, right, messages= edf.pread('/Users/jossando/trabajo/nystagmus/data/s11/s11.edf',properties_filter=['px','py','gx','gy'],ignore_samples=TRUE)
% edf.save_human_understandable(left,'/Users/jossando/trabajo/nystagmus/data/s11/s11.hdf', 'test')
database = '/Users/jossando/trabajo/nystagmus/data/s11/s11.hdf'
fixmat = get_fixmat(database, 'edf');
load('s11eye.mat')
%%

figure
set(gcf,'Position', [-1918 344 1521 361])

remxy = abs(fixmat.right_px)<8000 & abs(fixmat.right_py)<8000 & abs(fixmat.right_gx)<4000 & abs(fixmat.right_gy)<4000;
xraw = fixmat.right_px(fixmat.trial==1 & remxy);
yraw = fixmat.right_py(fixmat.trial==1 & remxy);

subplot(1,3,1)
plot(xraw,yraw,'.k')
axis()
title('raw')

gx = fixmat.right_gx(fixmat.trial==1 & remxy);
gy = fixmat.right_gy(fixmat.trial==1 & remxy);
subplot(1,3,2)
h(1) = plot(gx,gy,'.r');
hold on
h(2) = plot(xgazaux,ygazaux,'.m');
hline(calibpos(5,2),'k')
vline(calibpos(5,1),'k')
title('gaze and raw corrected bicuadratic')
legend(h,{'Gaze (eyelink calib)','Custom calib bicuadratic'})
win.rect = [0 0 1920 1080]
win.margin                  = [16 5];
mPix                        = win.rect(3:4).*win.margin/100;
  xy(1:9,1)  = repmat(mPix(1):(win.rect(3)-2*(mPix(1)))/2:win.rect(3)-mPix(1),1,3);
   xy(1:9,2)  = reshape(repmat(mPix(2):(win.rect(4)-2*(mPix(2)))/2:win.rect(4)-mPix(2),3,1),9,1);
calibpos = xy;

traw        = fixmat.sample_time(fixmat.trial==1 & remxy)'-435640;
tstart_dots = trial(1).dotpos.time;
dot_order = str2num(trial(1).dotpos.msg);

subplot(1,3,3)
h(1) = plot(xgaz,ygaz,'.m'),;
hold on
h(2) = plot(gx,gy,'.r');
hline(calibpos(5,2),'k')
vline(calibpos(5,1),'k')
title('gaze and raw corrected bicuadratic + quadrant')
legend(h,{'Gaze (eyelink calib)','Custom calib bicuadratic+quadrant'})