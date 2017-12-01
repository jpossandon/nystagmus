function [caldata,xgaz,ygaz] = calibdata(samples,saccades,win,dotinfo,method,toplot)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [calibmat,xgaz,ygaz] = calib(xraw,yraw,traw,calibpos,tstart_dots,dot_order)
% This function implements D. Stample 9-point calibration method (Behavior
% Research Methods, Instruments & Computers (1993), 25:137-142). It is
% designed to be used with the custom calibration function do_calib.m
%  
%   Inputs:
%       - from samples:
%           - rawx,rawy     , raw eye position during the whole 9-point calibration
%                       period. This is, the complete raw data of the
%                       calibration trial performed with do_calib.m
%           - traw          , corresponding sample time data
%       - from saccades:
%           - start, end    , starting and end times of each saccade
%       - from dotinfo:
%            - calibpos      , 9x2 matrix describing the position in the screen,
%                       in pixels, of the calibration points, according to the
%                       following mapping between rows and screen positions:
%                           1 2 3     this calibpos can be obtained
%                           4 5 6     from the output of do_calib:
%                           7 8 9     calibpos =  reshape([calibdata(1:9).dotpos],2,9)'
%           - tstart_dots   , time of appearance of each calibration dot
%           - dot_order     , correspondace between calibpos rows and
%                         tstart_dots times
%       - method        , 'sample', the median raw sample position as
%                           the point for calibration  
%                         'saccade', use the median saccade end sample position as
%                           the point for calibration
%                         'both', use the median of both above  
%       - toplot        , 0 - no;  1 - yes         
%   Outputs:
%       calib.
%       - ux,uy         , coefficients of cuadratic mapping between raw
%                       data and the position of calibration dots in
%                       screen. To obtain calibrated data from gaze data,
%                       xgaze = ux'*[ones(1,size(xraw',2));xraw';yraw';xraw'.^2;yraw'.^2];
%                       ygaze = uy'*[ones(1,size(yraw',2));xraw';yraw';xraw'.^2;yraw'.^2];
%       - m,n           , x,y quadrant correction coefficients
%       - xyP           , position of calibration points post-calibration
%       - xyR           , position of calibration points pre-calibration 
%       - xyDrift       , corrected position of last drift correction point
%
%       - xgaz,ygaz     , corrected gaze samples 
% JPO, Hamburg, 11-2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xraw = samples.rawx';
yraw = samples.rawy';
traw = samples.time';

rawdataLimit = 50000; % absolute limit in raw units 
if toplot
    figure
    set(gcf,'Position',[33 171 1000 250])
    subplot(1,3,1) % raw data plot
    plot(xraw(abs(xraw)<rawdataLimit & abs(yraw)<rawdataLimit),yraw(abs(xraw)<rawdataLimit & abs(yraw)<rawdataLimit),'.'),hold on
end

t_margin = 200; %ms 

% cycle through points
for pt = 1:size(dotinfo.dot_order,1)
    
    % start and end timestamp of current dot
     pos_startT  = dotinfo.tstart_dots(pt);                                          
    pos_endT    = dotinfo.tend_dots(pt);

    % indexes for raw data and saccades within t_margin and end-t_margin ms 
    % of the period the calibration dot is on screen
	aux_calib     = traw>pos_startT & traw<pos_endT & abs(xraw)<rawdataLimit & abs(yraw)<rawdataLimit;
    

    if ~strcmp(method,'sample')
        aux_sacc      = find(saccades.start>pos_startT+t_margin & saccades.start<pos_endT-t_margin);    % first saccade after appearance of dot +t_margin
        %  aux_sacc = aux_sacc(saccades.dur(aux_sacc)>median(saccades.dur(aux_sacc)));
        %  if length(aux_sacc)>8
        %  aux_sacc = aux_sacc(1:8);
        %  end
        aux_saccT = [];
        for st = 1:length(aux_sacc)
            aux_saccT     = [aux_saccT,find(traw>saccades.start(aux_sacc(st)) & ...      % find the last raw sample corresponding to each saccade 
                             traw<=saccades.end(aux_sacc(st))+2,1,'last')];
        end
    end
    
    
    if pt == size(dotinfo.dot_order,1) && ((strcmp(win.calibType,'HV9') && dotinfo.dot_order(pt)==5) ||...
            (strcmp(win.calibType,'HV5') && dotinfo.dot_order(pt)==3))     
    % the last-point should recenter the calibration grid, I have not tested so it is not yet used below 
        if strcmp(method,'sample')
            x_centerCorrect = nanmedian(xraw(aux_calib)); 
            y_centerCorrect = nanmedian(yraw(aux_calib));
        elseif strcmp(method,'saccade')
            x_centerCorrect = nanmedian(xraw(aux_saccT)); 
            y_centerCorrect = nanmedian(yraw(aux_saccT));
        elseif strcmp(method,'both') 
            x_centerCorrect = mean([nanmedian(xraw(aux_calib)),nanmedian(xraw(aux_saccT))]); 
            y_centerCorrect = mean([nanmedian(yraw(aux_calib)),nanmedian(yraw(aux_saccT))]); 
        end
    else % this by design will re-write values where calibration occured more than once
        if strcmp(method,'sample')
            xyR(1,dotinfo.dot_order(pt)) = nanmedian(xraw(aux_calib)); 
            xyR(2,dotinfo.dot_order(pt)) = nanmedian(yraw(aux_calib)); 
        elseif strcmp(method,'saccade')
             xyR(1,dotinfo.dot_order(pt)) = nanmedian(xraw(aux_saccT)); 
            xyR(2,dotinfo.dot_order(pt)) = nanmedian(yraw(aux_saccT)); 
        elseif strcmp(method,'both') 
            xyR(1,dotinfo.dot_order(pt)) = mean([nanmedian(xraw(aux_calib)),nanmedian(xraw(aux_saccT))]); 
            xyR(2,dotinfo.dot_order(pt)) = mean([nanmedian(yraw(aux_calib)),nanmedian(yraw(aux_saccT))]); 
        end
    end

    if toplot
        plot(xraw(aux_calib),yraw(aux_calib))
        if ~strcmp(method,'sample')
            plot(xraw(aux_saccT),yraw(aux_saccT),'.r','MarkerSize',24)
        end
        text(xyR(1,dotinfo.dot_order(pt)),xyR(2,dotinfo.dot_order(pt)),num2str(dotinfo.dot_order(pt)),'FontSize',18)
        title('ORIGINAL','FONTSIZE',16)
    end
end

 xyRc = xyR(:,5);
xyR = xyR-repmat(xyRc,1,size(xyR,2)); 
if strcmp(win.calibType,'HV9') 
   ixC = [2,4,5,6,8];
elseif strcmp(win.calibType,'HV5')
% calibration dots top,left,center,right,bottom are the ones used for the basic calibration equation
     ixC = [1,2,3,4,5];
end
A   = [ones(5,1),xyR(1,ixC)',xyR(2,ixC)',xyR(1,ixC).^2',xyR(2,ixC).^2'];
% bx  = dotinfo.calibpos(ixC,1);
% by  = dotinfo.calibpos(ixC,2);
bx  = dotinfo.calibpos(ixC,1)-win.rect(3)/2;
by  = dotinfo.calibpos(ixC,2)-win.rect(4)/2;

ux  = A\bx;
uy  = A\by;

% xgazaux = ux'*[ones(1,size(xraw',2));xraw';yraw';xraw'.^2;yraw'.^2];
% ygazaux = uy'*[ones(1,size(yraw',2));xraw';yraw';xraw'.^2;yraw'.^2];

xgazaux = ux'*[ones(1,size(xraw'-xyRc(1),2));xraw'-xyRc(1);yraw'-xyRc(2);(xraw'-xyRc(1)).^2;(yraw'-xyRc(2)).^2];
ygazaux = uy'*[ones(1,size(yraw'-xyRc(2),2));xraw'-xyRc(1);yraw'-xyRc(2);(xraw'-xyRc(1)).^2;(yraw'-xyRc(2)).^2];

xyPaux  = ux'*[ones(1,size(xyR,2));xyR(1,:);xyR(2,:);xyR(1,:).^2;xyR(2,:).^2];
xyPaux  = [xyPaux;uy'*[ones(1,size(xyR,2));xyR(1,:);xyR(2,:);xyR(1,:).^2;xyR(2,:).^2]];

xyDriftaux  = ux'*[ones(1,size(x_centerCorrect'-xyRc(1),2));x_centerCorrect'-xyRc(1);y_centerCorrect'-xyRc(2);(x_centerCorrect'-xyRc(1)).^2;y_centerCorrect'-xyRc(2).^2];
xyDriftaux  = [xyDriftaux;uy'*[ones(1,size(y_centerCorrect'-xyRc(2),2));(x_centerCorrect'-xyRc(1));y_centerCorrect'-xyRc(2)';(x_centerCorrect'-xyRc(1)).^2;y_centerCorrect'-xyRc(2).^2]];
% xgaz    = xgazaux;
% ygaz    = ygazaux;

xgaz    = xgazaux+win.rect(3)/2;
ygaz    = (ygazaux+win.rect(4)/2);
xyP     = xyPaux+repmat(win.rect(3:4)'/2,1,size(xyPaux,2));
xyDrift = xyDriftaux + win.rect(3:4)'/2;

if toplot
    subplot(1,3,2),hold on
    line([0 win.rect(3)],[win.rect(4)/2 win.rect(4)/2],'LineStyle',':','Color',[1 0 0])
    line([win.rect(3)/2 win.rect(3)/2],[0 win.rect(4)],'LineStyle',':','Color',[1 0 0])
    plot(xgaz(abs(xgaz)<5000 & abs(ygaz)<5000),ygaz(abs(xgaz)<5000 & abs(ygaz)<5000),'.','Color',[0 0 1])
    for pt = 1:size(dotinfo.dot_order,1)
         text(dotinfo.calibpos(dotinfo.dot_order(pt),1),dotinfo.calibpos(dotinfo.dot_order(pt),2),num2str(dotinfo.dot_order(pt)),'FontSize',18)
%          text(xyP(1,dotinfo.dot_order(pt)),xyP(2,dotinfo.dot_order(pt)),num2str(dotinfo.dot_order(pt)),'FontSize',18)
%           plot(xyR(1,dotinfo.dot_order(pt)),xyR(2,dotinfo.dot_order(pt)),'.k','MarkerSize',18)
          plot(xyP(1,dotinfo.dot_order(pt)),xyP(2,dotinfo.dot_order(pt)),'.r','MarkerSize',16)
    end
    plot(xyDrift(1),xyDrift(2),'.c','MarkerSize',24)
    text(xyDrift(1),xyDrift(2),'drift','FontSize',18)
    
    axis([0-100 win.rect(3)+100 0-100 win.rect(4)+100])
    rectangle('Position',[0 0 win.rect(3) win.rect(4)])
    axis ij
    title('5-POINT CALIBRATION','FONTSIZE',16)
%     axis image
    
end

%Cuadrant correction

if strcmp(win.calibType,'HV9') 
    
    ixC = [1,3,7,9];
    
    xi      = ux'*[ones(1,size(xyR(1,ixC),2));xyR(1,ixC);xyR(2,ixC);xyR(1,ixC).^2;xyR(2,ixC).^2];
    yi      = uy'*[ones(1,size(xyR(1,ixC),2));xyR(1,ixC);xyR(2,ixC);xyR(1,ixC).^2;xyR(2,ixC).^2];
   
    m       = (dotinfo.calibpos(ixC,1)'-win.rect(3)/2-xi)./xi./yi;
    n       = (dotinfo.calibpos(ixC,2)'-win.rect(4)/2-yi)./xi./yi;  
        
    xgaz    = nan(1,length(xgazaux));
    ygaz    = nan(1,length(ygazaux));
    xyP     = xyPaux;
    for i = 1:4
        switch ixC(i)   %cuadrants
            case 1
                auxindx = find(xgazaux<0 & ygazaux<0);
                driftquad = find(xyDriftaux(1)<0 & xyDriftaux(2)<0);
            case 3
                auxindx = find(xgazaux>0 & ygazaux<0);
                driftquad = find(xyDriftaux(1)>0 & xyDriftaux(2)<0);
            case 7
                auxindx = find(xgazaux<0 & ygazaux>0);
                driftquad = find(xyDriftaux(1)<0 & xyDriftaux(2)>0);
            case 9
                auxindx = find(xgazaux>0 & ygazaux>0);
                driftquad = find(xyDriftaux(1)>0 & xyDriftaux(2)>0);
        end
        xyPaux(1,ixC(i)) = xyPaux(1,ixC(i))+m(i).*xyPaux(1,ixC(i)).*xyPaux(2,ixC(i));
        xyPaux(2,ixC(i)) = xyPaux(2,ixC(i))+n(i).*xyPaux(1,ixC(i)).*xyPaux(2,ixC(i));
        xgaz(auxindx) = xgazaux(auxindx)+m(i).*xgazaux(auxindx).*ygazaux(auxindx);
        ygaz(auxindx) = ygazaux(auxindx)+n(i).*xgazaux(auxindx).*ygazaux(auxindx);
        if driftquad
            xyDriftaux(1) = xyDriftaux(1)+m(i).*xyDriftaux(1).*xyDriftaux(2);
            xyDriftaux(2) = xyDriftaux(2)+n(i).*xyDriftaux(1).*xyDriftaux(2);
        end 
    end
    xgaz    = xgaz+win.rect(3)/2;
    ygaz    = (ygaz+win.rect(4)/2);
    xyP     = xyPaux+repmat(win.rect(3:4)'/2,1,size(xyPaux,2));
    xyDrift = xyDriftaux + win.rect(3:4)'/2;

    
   
    if toplot
        subplot(1,3,3), hold on
        line([0 win.rect(3)],[win.rect(4)/2 win.rect(4)/2],'LineStyle',':','Color',[1 0 0])
        line([win.rect(3)/2 win.rect(3)/2],[0 win.rect(4)],'LineStyle',':','Color',[1 0 0])
  
        plot(xgaz(abs(xgaz)<rawdataLimit & abs(ygaz)<rawdataLimit),ygaz(abs(xgaz)<rawdataLimit & abs(ygaz)<rawdataLimit),'.','Color',[0 0 1])
         for pt = 1:size(dotinfo.dot_order,1)
              text(dotinfo.calibpos(dotinfo.dot_order(pt),1),dotinfo.calibpos(dotinfo.dot_order(pt),2),num2str(dotinfo.dot_order(pt)),'FontSize',18)
               plot(xyP(1,dotinfo.dot_order(pt)),xyP(2,dotinfo.dot_order(pt)),'.g','MarkerSize',16)
         end
         
         plot(xyDrift(1),xyDrift(2),'.c','MarkerSize',24)
        text(xyDrift(1),xyDrift(2),'drift','FontSize',18)
    
        rectangle('Position',[0 0 win.rect(3) win.rect(4)])
        axis ij
        axis([0-100 win.rect(3)+100 0-100 win.rect(4)+100])
        title('9-POINT CALIBRATION','FONTSIZE',16)
   end
end

caldata.ux                  = ux;
caldata.uy                  = uy;
caldata.correctedDotPos     = xyP;
caldata.uncorrectedDotPos   = xyR+repmat(xyRc,1,size(xyR,2));
caldata.xyDrift             = xyDrift;
caldata.rawCenter           = xyRc;
caldata.rect                = win.rect;
caldata.calibType           = win.calibType;
caldata.samples             = samples;
if strcmp(win.calibType,'HV9') 
    caldata.m                   = m;
    caldata.n                   = n;
elseif strcmp(win.calibType,'HV5') 
    caldata.m                   = NaN;
    caldata.n                   = NaN;
end