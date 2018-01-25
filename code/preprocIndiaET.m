%%
clear
datapath = '/Users/jossando/trabajo/India/data/';

sid             = 's030';%'s030''s099'
task            = 'ID';
MATfile         = fullfile(datapath,sid,[sid task '.mat']);
edffile         = fullfile(datapath,sid,[sid task '.edf']);

load(MATfile)
[trial,meta]    = totrial(edffile,{'raw','gaze'});

% TODO:  DOUBLE CHECK THAT DOTINFO IN EDF IS TEH SAME THAN IN WIN.CALIN

%
tr = 1;
method = 'saccade';
method = 'sample';
for ey = 1:2
    if ey ==1 && isfield(trial(tr).left,'saccade')
        useye = 'left';
    elseif ey ==2 && isfield(trial(tr).right,'saccade')
        useye = 'right';
    end

    if strcmp(method,'saccade')
        trial(tr).(useye).samples.time = trial(tr).(useye).samples.pctime; 
        [caldata,xgaz,ygaz] = calibdata(trial(tr).(useye).samples,trial(tr).(useye).saccade,win,win.calib.dotinfo(ey),'saccade',1);
    elseif strcmp(method,'sample')
        if strcmp(sid,'s078') | strcmp(sid,'s079') 
        [caldata(ey),xgaz,ygaz] = calibdata(win.calib.caldata(ey).samples,[],win,win.calib(1).dotinfo,'sample',1);
        elseif strcmp(sid,'s099') | strcmp(sid,'s065')
        [caldata(ey),xgaz,ygaz] = calibdata(win.calib.caldata(ey).samples,[],win,win.calib(1).dotinfo(ey),'sample',1);
        elseif strcmp(sid,'s030') | strcmp(sid,'s084')
       trial(tr).(useye).samples.time = trial(tr).(useye).samples.pctime;
        [caldata(ey),xgaz,ygaz] = calibdata(trial(tr).(useye).samples,trial(tr).(useye).saccade,win,win.calib.dotinfo(ey),'sample',1);

        else
        [caldata(ey),xgaz,ygaz] = calibdata(trial(tr).(useye).samples,[],win,win.calib(1).dotinfo(ey),'sample',1);
        end
    end
  % doimage(gcf,['/Users/jossando/trabajo/India/result/' sid '/'],'png',['calib_' num2str(tr)],1);
end

 if strcmp(sid,'s065') || strcmp(sid,'s030') || strcmp(sid,'s084')
     for ey = 1:2
        if ey ==1 && isfield(trial(tr).left,'saccade')
            useye = 'left';
        elseif ey ==2 && isfield(trial(tr).right,'saccade')
            useye = 'right';
        end
         for tt = 1:length(trial)
            auxtr       = trial(tt).(useye);
            auxVelX  = nan(1,length(auxtr.samples.rawx));
            auxVelY  = nan(1,length(auxtr.samples.rawx));
            auxAccX  = nan(1,length(auxtr.samples.rawx));
            auxAccY  = nan(1,length(auxtr.samples.rawx));
            for nn = 10:length(auxtr.samples.rawx)-10
                if ~any(auxtr.samples.rawx(nn-9:nn+9)==-32768)
                    auxVelX(nn) = 500*(auxtr.samples.rawx(nn+2)+auxtr.samples.rawx(nn+1)-auxtr.samples.rawx(nn-1)-auxtr.samples.rawx(nn-2))/6/auxtr.samples.rx(nn);
%                     auxAccX(nn) = 500^2*(auxtr.samples.rawx(nn-2)+2*auxtr.samples.rawx(nn)+auxtr.samples.rawx(nn+2))/4/auxtr.samples.rx(nn);
                end
                if ~any(auxtr.samples.rawy(nn-9:nn+9)==-32768)
                     auxVelY(nn) = 500*(auxtr.samples.rawy(nn+2)+auxtr.samples.rawy(nn+1)-auxtr.samples.rawy(nn-1)-auxtr.samples.rawy(nn-2))/6/auxtr.samples.ry(nn);
%                      auxAccY(nn) = 500^2*(auxtr.samples.rawy(nn-2)+2*auxtr.samples.rawy(nn)+auxtr.samples.rawy(nn+2))/4/auxtr.samples.ry(nn);
                end
  
            end
            
            auxtr.samples.rawxvel = auxVelX;
            auxtr.samples.rawyvel = auxVelY;
%             auxtr.samples.rawxacc = auxAccX;
%             auxtr.samples.rawyacc = auxAccY;
            trial(tt).(useye) = auxtr;
         end
         
     end
 end

%%
%%
% characteristics of all data per eye
%
useye = 'left';
aux   = [trial.(useye)];
aux   = [aux.samples];
[all.t,all.x,all.y,all.xvel,all.yvel] = deal([aux.time],[aux.rawx],[aux.rawy],[aux.rawxvel],[aux.rawyvel]);


%%
% figure,plot(all.xvel,[diff(all.xvel) NaN],'.')
figure,plot(all.xvel,'.-'),hold on
% plot(all.xvel2,'.-')
plot(all.x-mean(all.x),'k')
plot([NaN diff(all.xvel)],'.-r')
% plot(diff(all.xacc),'.-r')
% figure,plot(all.yvel,'.-'),hold on
% plot(all.y-mean(all.y),'k')
% plot(diff(all.yvel),'.-r')
% 
% figure,hist(all.xvel,500)
% figure,hist(diff(all.xvel),500)

%%
% simple saccade/nystagmus detection
% aThr = 5
% vThr = 10
if strcmp(sid,'s079')
    aThr = 2*nanstd(diff(all.xvel));
    vThr = nanstd(all.xvel);
elseif strcmp(sid,'s078')
    aThr = 12;
    vThr = 25;
    elseif strcmp(sid,'s077')
    aThr = 50;
    vThr = 100;
elseif strcmp(sid,'s099')    
    aThr = 12;
    vThr = 25;
    elseif strcmp(sid,'s065')    
    aThr = 60;
    vThr = 80;
    useye = 'right';
        elseif strcmp(sid,'s030')    
    aThr = 35;
    vThr = 60;
    useye = 'left';
    elseif strcmp(sid,'s084')    
    aThr = 20;
    vThr = 40;
    useye = 'left';
end
for tt = 1:length(trial)
    auxtr       = trial(tt).(useye);

    auxVelX      = auxtr.samples.rawxvel;
    auxVelY      = auxtr.samples.rawyvel;
   
    auxAccX      = [NaN diff(auxtr.samples.rawxvel)];
    auxAccY      = [NaN diff(auxtr.samples.rawyvel)];
    flagSacX     = zeros(1,10);
    flagSacY     = zeros(1,10);
    cVelSign    = NaN;
    for ss = 11:length(auxtr.samples.x)
        if flagSacX(ss-1)==0 
            if abs(auxAccX(ss))>aThr & abs(auxVelX(ss))>vThr ;
                if any(flagSacX(ss-10:ss-1)==1) %flagSacX(ss-2)==1 | flagSacX(ss-3)==1 | flagSacX(ss-4)==1 
                    flagSacX(ss) = 0;
                else
                    if sign(auxAccX(ss))==sign(auxVelX(ss))
                        cVelSign    = sign(auxVelX(ss));
                        flagSacX(ss) = 1;
                    else
                        flagSacX(ss) = 0;
                    end
                end
            else
                flagSacX(ss) = 0;
            end
        end
        if flagSacX(ss-1)==1 
            if abs(auxVelX(ss))>vThr & sign(sign(auxVelX(ss)))==cVelSign;
                flagSacX(ss) = 1;
            else
                cVelSign    = NaN;
                flagSacX(ss) = 0;
            end
        end
    end
    for ss = 11:length(auxtr.samples.y)
        if flagSacY(ss-1)==0 
            if abs(auxAccY(ss))>aThr & abs(auxVelY(ss))>vThr;
                if any(flagSacY(ss-10:ss-1)==1) 
                    flagSacY(ss) = 0;
                else
                    if sign(auxAccY(ss))==sign(auxVelY(ss))
                        cVelSign    = sign(auxVelY(ss));
                        flagSacY(ss) = 1;
                    else
                        flagSacY(ss) = 0;
                    end
                end
            else
                flagSacY(ss) = 0;
            end
        end
        if flagSacY(ss-1)==1 
            if abs(auxVelY(ss))>vThr & sign(sign(auxVelY(ss)))==cVelSign;
                flagSacY(ss) = 1;
            else
                cVelSign    = NaN;
                flagSacY(ss) = 0;
            end
        end
    end
    auxtr.samples.issac = flagSacX | flagSacY;
    sends = find(diff(auxtr.samples.issac)==1);
    sstrs = find(diff(auxtr.samples.issac)==-1);
    if auxtr.samples.issac(end) == 1
        sstrs = sstrs(1:end-1); 
    end
    auxtr.fixation.newend =  [auxtr.samples.time(sends),NaN];
    auxtr.fixation.newst  =  [NaN, auxtr.samples.time(sstrs)];
    auxtr.fixation.newdur    =  auxtr.fixation.newend-auxtr.fixation.newst;
    
    trial(tt).(useye) = auxtr;
end

%%
% useye = 'right';
% useye = 'left';
auxt   = [trial.(useye)];
aux   = [auxt.samples];
all.issac = [aux.issac];
all.samples = 1:length(all.t);
figure,plot(all.xvel,'.-'),hold on
plot(all.x-mean(all.x),'k')
plot(all.samples(logical(all.issac)),all.x(logical(all.issac))-mean(all.x),'.r')
plot([NaN diff(all.xvel)],'.-m')
hline(-10)
hline(10)
hline(0,'k')

aux = [auxt.fixation];
[all.fst,all.fend,all.fdur] = deal([aux.newst],[aux.newend],[aux.newdur]);
 figure,plot(all.yvel,'.-'),hold on
 plot(all.y-mean(all.y),'k')
 plot(all.samples(logical(all.issac)),all.y(logical(all.issac))-mean(all.y),'.r')
 plot(diff(all.yvel),'.-m')
%%
eyec = {'r','r'};
driftcor     = 1;
cmap         = cmocean('thermal');
allgaz       = [];
allgazfix    = [];
allgazfixend = [];
 allgazfixst = [];
allgazF = [];
sacang = [];
for trr=2:57
%     try
    figure
    if strcmp(task,'ID')
        im = imread(['/Users/jossando/trabajo/India/images/33/' trial(trr).image.msg]);
    elseif strcmp(task,'OBJ')
        im = imread(['/Users/jossando/trabajo/India/images/34/' trial(trr).image.msg]);
    end
    imshow(im),hold on
%     for ey = 1
%          if ey ==1 && isfield(trial(tr).left,'saccade')
%              useye = 'left';
%         elseif ey ==2 && isfield(trial(tr).right,'saccade')
% %             useye = 'right';
%          end
ey=1
        if driftcor
            indxdrift = find(trial(trr).(useye).samples.time<0);
            xdriftc = trial(trr).(useye).samples.rawx'-nanmedian(trial(trr).(useye).samples.rawx(indxdrift)')+caldata(ey).rawCenter(1);
            ydriftc = trial(trr).(useye).samples.rawy'-nanmedian(trial(trr).(useye).samples.rawy(indxdrift)')+caldata(ey).rawCenter(2);
            [xgaz,ygaz] = correct_raw(xdriftc,ydriftc,caldata(ey));
        else
            [xgaz,ygaz] = correct_raw(trial(trr).(useye).samples.rawx',trial(trr).(useye).samples.rawy',caldata(ey));
        end
        issac = trial(trr).(useye).samples.issac;
        cTime = trial(trr).(useye).samples.time;
        try
            sacsts = [xgaz(cTime>0 & [diff(issac) NaN]==1)'-(win.rect(3)-size(im,2))/2,ygaz(cTime>0 & [diff(issac) NaN]==1)'-(win.rect(4)-size(im,1))/2];
            sacends = [xgaz(cTime>0 & [diff(issac) NaN]==-1)'-(win.rect(3)-size(im,2))/2,ygaz(cTime>0 & [diff(issac) NaN]==-1)'-(win.rect(4)-size(im,1))/2];
            if ~isempty(sacsts)
                ha = arrow('Start',sacsts,'Stop',sacends,'Length',10,'Width',0);
                for he = 1:length(ha),set(ha(he),'EdgeColor',[.9 .9 .9],'FaceColor',[.9 .9 .9]),end
                difsac = sacends-sacsts;
                sacang = [sacang;cart2pol(difsac(:,1),difsac(:,2))];
            end
        catch
        end
        plot(xgaz(cTime>0)-(win.rect(3)-size(im,2))/2,ygaz(cTime>0)-(win.rect(4)-size(im,1))/2,['.'],'MarkerSize',14,'Color',[1 0 0])
        plot(xgaz(cTime>0 & issac)-(win.rect(3)-size(im,2))/2,ygaz(cTime>0 & issac)-(win.rect(4)-size(im,1))/2,'.','MarkerSize',14,'Color',[.9 .9 .9])
        
%         plot(xgaz(cTime>0 & [diff(issac) NaN]==-1)-(win.rect(3)-size(im,2))/2,ygaz(cTime>0 & [diff(issac) NaN]==-1)-(win.rect(4)-size(im,1))/2,['.b'],'MarkerSize',12)
         allgaz = [allgaz,[xgaz(cTime>0)-(win.rect(3)-size(im,2))/2;ygaz(cTime>0)-(win.rect(4)-size(im,1))/2]];
        allgazfix = [allgazfix,[xgaz(cTime>0 & ~issac)-(win.rect(3)-size(im,2))/2;ygaz(cTime>0 & ~issac)-(win.rect(4)-size(im,1))/2]];
        allgazfixend = [allgazfixend,[xgaz(cTime>0 & [diff(issac) NaN]==1)-(win.rect(3)-size(im,2))/2;ygaz(cTime>0 &  [diff(issac) NaN]==1)-(win.rect(4)-size(im,1))/2]];
        allgazfixst = [allgazfixst,[xgaz(cTime>0 & [diff(issac) NaN]==-1)-(win.rect(3)-size(im,2))/2;ygaz(cTime>0 &  [diff(issac) NaN]==-1)-(win.rect(4)-size(im,1))/2]];
        
        if mod(cTime(1),2)
             if ~any(abs([xgaz(cTime>-1000 & cTime<4000)])>10000)
                allgazF = [allgazF; [xgaz(cTime>-1000 & cTime<3999)]];
             end
        else
            if ~any(abs([xgaz(cTime>-1000 & cTime<4000)])>10000)
                allgazF = [allgazF; [xgaz(cTime>-1000 & cTime<4000)]];
            end
        end
%     end
             doimage(gcf,['/Users/jossando/trabajo/India/result/' sid '/'],'png',[trial(trr).image.msg(1:end-4) '_' trial(trr).pair_order.msg],[],1);

          figure,
%           subplot(2,1,1)
          set(gcf,'Position',[100 100 1200 250])
          h(1) = plot(cTime(xgaz>-500 & xgaz<2000),xgaz(xgaz>-500 & xgaz<2000)-(win.rect(3)-size(im,2))/2);,hold on
          h(2) = plot(cTime(ygaz>-500 & ygaz<2000),ygaz(ygaz>-500 & ygaz<2000)-(win.rect(4)-size(im,1))/2);
          xlim([cTime(1) cTime(end)])
          ylim([0 size(im,1)])
          ha  = get(gca) ;
          hh = hline(size(im,2)/2);
          hh.Color = ha.ColorOrder(1,:);
          hh = hline(size(im,1)/2);
          hh.Color = ha.ColorOrder(2,:);
          vline(0)
          xlabel('Time (ms)','FontSize',14)
          ylabel('Gaze Position (pix)','FontSize',14)
          legend(h,{'Horizontal','Vertical'})
          legend boxoff
          box off
             doimage(gcf,['/Users/jossando/trabajo/India/result/' sid '/'],'png',[trial(trr).image.msg(1:end-4) '_trace_' trial(trr).pair_order.msg],[],1);

%

          %           figure,
%           subplot(4,1,1)
%           plot(cTime,xgaz(xgaz>-500 & xgaz<2000)),hold on
%           xlim([cTime(1) cTime(end)])
%           subplot(4,1,2), hold on
%           plot(cTime,trial(trr).(useye).samples.rawxvel(xgaz>-500 & xgaz<2000),'.-')
%           plot(cTime(1:end-1),diff(trial(trr).(useye).samples.rawxvel(xgaz>-500 & xgaz<2000)),'.-r')
%           xlim([cTime(1) cTime(end)])
%           subplot(4,1,3)
%           plot(cTime,ygaz(ygaz>-500 & ygaz<2000))
%           xlim([cTime(1) cTime(end)])
%          subplot(4,1,4), hold on
%          plot(cTime,trial(trr).(useye).samples.rawyvel(ygaz>-500 & ygaz<2000),'.-')
%          plot(cTime(1:end-1),diff(trial(trr).(useye).samples.rawyvel(ygaz>-500 & ygaz<2000)),'.-r')
%          xlim([cTime(1) cTime(end)])
%     catch
%         trr
%     end
    
end
%%
figure,plot(allgazfix(1,:),allgazfix(2,:),'.'),axis([0 584 0 850]),axis ij
 [fixpdfall,fixs] = makepdf(allgaz(1,:)',allgaz(2,:)',40,[850,584],1,1);
 [fixpdffix,fixs] = makepdf(allgazfix(1,:)',allgazfix(2,:)',40,[850,584],1,1);
 [fixpdffixend,fixs] = makepdf(allgazfixend(1,:)',allgazfixend(2,:)',40,[850,584],1,1);
 [fixpdffixst,fixs] = makepdf(allgazfixst(1,:)',allgazfixst(2,:)',40,[850,584],1,1);
 %%
 im = imread(['/Users/jossando/trabajo/India/images/33/Mimagen.jpg']);
 %
figure,
h = imshow(im)
hold on
h = imshow(fixpdffix,[]),colormap parula
set(h, 'AlphaData', fixpdffixend./max(fixpdffixend(:))./1.3);
doimage(gcf,['/Users/jossando/trabajo/India/result/' sid '/'],'png','fixpdffix_parula',[],1);

figure,
h = imshow(im)
hold on
h = imshow(zeros(size(im)))
set(h, 'AlphaData', .7-fixpdffix./max(fixpdffix(:)));
doimage(gcf,['/Users/jossando/trabajo/India/result/' sid '/'],'png','fixpdffix_mask',[],1);

figure,
h = imshow(im)
hold on
h = imshow(fixpdffixend,[]),colormap parula
set(h, 'AlphaData', fixpdffixend./max(fixpdffixend(:))./1.3);
doimage(gcf,['/Users/jossando/trabajo/India/result/' sid '/'],'png','fixpdffixend_parula',[],1);

figure,
h = imshow(im)
hold on
h = imshow(zeros(size(im)))
set(h, 'AlphaData', .7-fixpdffixend./max(fixpdffixend(:)));
doimage(gcf,['/Users/jossando/trabajo/India/result/' sid '/'],'png','fixpdffixend_mask',[],1);

figure,
h = imshow(im)
hold on
h = imshow(fixpdffixst,[]),colormap parula
set(h, 'AlphaData', fixpdffixst./max(fixpdffixst(:))./1.3);
doimage(gcf,['/Users/jossando/trabajo/India/result/' sid '/'],'png','fixpdffixst_parula',[],1);

figure,
h = imshow(im)
hold on
h = imshow(zeros(size(im)))
set(h, 'AlphaData', .7-fixpdffixst./max(fixpdffixst(:)));
doimage(gcf,['/Users/jossando/trabajo/India/result/' sid '/'],'png','fixpdffixst_mask',[],1);

%%
clear s
for tr = 1:size(allgazF)
[s(:,:,tr),w,t] = spectrogram(allgazF(tr,:)-mean(allgazF(tr,:)),1000,950,1000,500);
%  figure,plot(allgazF(tr,:))
%  figure,imagesc(t-1.5,w(w>0 & w<10),10*log10(abs(s((w>0 & w<10),:,tr)))),axis xy
end

figure,imagesc(t-1.5,w(w>0 & w<20),10*log10(abs(mean(s((w>0 & w<20),:,:),3)))),axis xy
figure,imagesc(t-1.5,w(w>0 & w<20),mean(10*log10(abs(s((w>0 & w<20),:,:))),3)),axis xy

%%
bins = -1000:250:4000;
aux_end = all.fend(all.fend>-1000 &all.fend<4000 & all.fdur>50)
aux_dur = all.fdur(all.fend>-1000 & all.fend<4000 & all.fdur>50)
[n,bin] = histc(aux_end,bins);
acM = accumarray(bin',aux_dur,[],@mean)
acS = accumarray(bin',aux_dur,[],@std)
figure,hold on
plot(aux_end,aux_dur,'ok','MarkerFaceColor',[.9 .9 .9],'MarkerEdgeColor',[.8 .8 .8])
% jbfill(bins(1:end-1)+125,[acM+acS]',[acM-acS]','b','b',1,.7),hold on
plot(bins(1:end-1)+125,acM,'.-','LineWidth',2,'MarkerSize',14)
vline(0)
xlabel('Time (ms)','FontSize',14)
ylabel('Saccadic Interval Duration (ms)','FontSize',14)
ylim([0 1200])
doimage(gcf,['/Users/jossando/trabajo/India/result/' sid '/'],'png','sac_interval',[],1);

%%
figure
hr = rose(sacang,12);
hr.LineWidth = 2;
hr.Color = [0 0 0]
doimage(gcf,['/Users/jossando/trabajo/India/result/' sid '/'],'png','sac_angle',[],1);