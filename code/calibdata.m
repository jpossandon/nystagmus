function [ux,uy,xgaz,ygaz] = calibdata(samples,saccades,win,dotinfo,method,toplot)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [calibmat,xgaz,ygaz] = calib(xraw,yraw,traw,calibpos,tstart_dots,dot_order)
% This function implements D. Stample 9-point calibration method (Behavior
% Research Methods, Instruments & Computers (1993), 25:137-142). It is
% designed to be used with the custom calibration function do_calib.m
%  
%   Inputs:
%       - from samples:
%           - xraw,yraw     , raw eye position during the whole 9-point calibration
%                       period. This is, the complete raw data of the
%                       calibration trial performed with do_calib.m
%           - traw          , corresponding sample time data
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
%       - ux,uy         , coefficients of cuadratic mapping between raw
%                       data and the position of calibration dots in
%                       screen. To obtain calibrated data from gaze data,
%                       xgaze = ux'*[ones(1,size(xraw',2));xraw';yraw';xraw'.^2;yraw'.^2];
%                       ygaze = uy'*[ones(1,size(yraw',2));xraw';yraw';xraw'.^2;yraw'.^2];
%                          
% JPO, Hamburg, 11-2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xraw = samples.rawx';
yraw = samples.rawy';
traw = samples.time ;
% Finding raw position at calib position.
% At the moment only taking the median position, we can implement later
% that it takes only in account position after a saccade (~fast period of the nystagmus)

rawdataLimit = 30000; % absolute limit in raw units 
if toplot
    figure
    set(gcf,'Position',[33 171 1147 534])
    subplot(1,2,1) % raw data plot
    plot(xraw(abs(xraw)<rawdataLimit & abs(yraw)<rawdataLimit),yraw(abs(xraw)<rawdataLimit & abs(yraw)<rawdataLimit),'.'),hold on
end

t_margin = 100; %ms
for p = 1:size(dotinfo.dot_order,1)
    
    pos_startT  = dotinfo.tstart_dots(p);                                           % pos_startT and pos_endT mark the period corresponding to the current calibration dor
    
    if p == size(dotinfo.dot_order,1)
        pos_endT = traw(end);
    else
        pos_endT = dotinfo.tstart_dots(p+1);
    end
    
    % indexes for raw data and saccades within t_margin and end-t_margin ms 
    % of the period the calibration dot is on screen
    aux_calib     = traw>pos_startT+100 & traw<pos_endT-t_margin & abs(xraw')<rawdataLimit & abs(yraw')<rawdataLimit;
    aux_sacc      = find(saccades.start>pos_startT+t_margin & saccades.start<pos_endT-t_margin);    % first saccade after appearance of dot +t_margin
%     aux_sacc = aux_sacc(saccades.dur(aux_sacc)>median(saccades.dur(aux_sacc)));
%  if length(aux_sacc)>8
%  aux_sacc = aux_sacc(1:8);
%  end
    aux_saccT = [];
    for st = 1:length(aux_sacc)
        aux_saccT     = [aux_saccT,find(traw>saccades.start(aux_sacc(st)) & ...      % find the last raw sample corresponding to each saccade 
            traw<saccades.end(aux_sacc(st)),1,'last')];
    end
    if p == size(dotinfo.dot_order,1) & dotinfo.dot_order(p)==5                             % the last-point should recenter the calibration grid, I have not tested so it is not yet used below 
        x_centerCorrect = nanmedian(xraw(aux_calib)); 
        y_centerCorrect = nanmedian(yraw(aux_calib));
    else % this by design will re-write values where calibration occured more than once
        if strcmp(method,'sample')
            xr(dotinfo.dot_order(p)) = nanmedian(xraw(aux_calib)); 
            yr(dotinfo.dot_order(p)) = nanmedian(yraw(aux_calib)); 
        elseif strcmp(method,'saccade')
            xr(dotinfo.dot_order(p)) = nanmedian(xraw(aux_saccT)); 
            yr(dotinfo.dot_order(p)) = nanmedian(yraw(aux_saccT)); 
        elseif strcmp(method,'both') 
            xr(dotinfo.dot_order(p)) = mean([nanmedian(xraw(aux_calib)),nanmedian(xraw(aux_saccT))]); 
            yr(dotinfo.dot_order(p)) = mean([nanmedian(yraw(aux_calib)),nanmedian(yraw(aux_saccT))]); 
        end
    end
    if toplot
        plot(xraw(aux_calib),yraw(aux_calib))
        plot(xraw(aux_saccT),yraw(aux_saccT),'.r','MarkerSize',24)
        text(xr(dotinfo.dot_order(p)),yr(dotinfo.dot_order(p)),num2str(dotinfo.dot_order(p)),'FontSize',18)
    end
end

ixC = [2,4,5,6,8];                                                          % calibration dots top,left,center,right,bottom are the ones used for the basic calibration equation
A   = [ones(5,1),xr(ixC)',yr(ixC)',xr(ixC).^2',yr(ixC).^2'];
bx  = dotinfo.calibpos(ixC,1);
by  = dotinfo.calibpos(ixC,2);

ux  = A\bx;
uy  = A\by;

xgazaux = ux'*[ones(1,size(xraw',2));xraw';yraw';xraw'.^2;yraw'.^2];
ygazaux = uy'*[ones(1,size(yraw',2));xraw';yraw';xraw'.^2;yraw'.^2];

xgaz    = xgazaux;
ygaz    = ygazaux;

if toplot
    plot(xr,yr,'.r','MarkerSize',17)
    subplot(1,2,2),hold on
    line([0 win.rect(3)],[win.rect(4)/2 win.rect(4)/2],'LineStyle',':','Color',[1 0 0])
    line([win.rect(3)/2 win.rect(3)/2],[0 win.rect(4)],'LineStyle',':','Color',[1 0 0])
    plot(xgaz(abs(xgaz)<5000 & abs(ygaz)<5000),ygaz(abs(xgaz)<5000 & abs(ygaz)<5000),'.')
    axis ij
    axis([0 win.rect(3) 0 win.rect(4)])
end
% cuadrant correction, this does not work well yet
% ixC = [1,3,7,9];
% 
% xi      = ux'*[ones(1,size(ixC,2));xr(ixC);yr(ixC);xr(ixC).^2;yr(ixC).^2];
% yi      = uy'*[ones(1,size(ixC,2));xr(ixC);yr(ixC);xr(ixC).^2;yr(ixC).^2];
% m       = (calibpos(ixC,1)'-xi)./xi./yi;
% n       = (calibpos(ixC,2)'-yi)./xi./yi;  
%     
% xgaz    = nan(1,length(xgazaux));
% ygaz    = nan(1,length(ygazaux));
% 
% for i = 1:4
%     switch ixC(i)   %cuadrants
%         case 1
%             auxindx = find(xgazaux<calibpos(5,1) & ygazaux<calibpos(5,2));
%         case 3
%             auxindx = find(xgazaux>calibpos(5,1) & ygazaux<calibpos(5,2));
%         case 7
%             auxindx = find(xgazaux<calibpos(5,1) & ygazaux>calibpos(5,2));
%         case 9
%             auxindx = find(xgazaux>calibpos(5,1) & ygazaux>calibpos(5,2));
%     end
%    
%     xgaz(auxindx) = xgazaux(auxindx)+m(i).*xgazaux(auxindx).*ygazaux(auxindx);
%     ygaz(auxindx) = ygazaux(auxindx)+n(i).*xgazaux(auxindx).*ygazaux(auxindx);
% end
% 
% if toplot
%     plot(xr,yr,'.r','MarkerSize',17)
%     subplot(1,2,2)
%     plot(xgaz(abs(xgaz)<rawdataLimit & abs(ygaz)<rawdataLimit),ygaz(abs(xgaz)<rawdataLimit & abs(ygaz)<rawdataLimit),'.r')
%     axis ij
% end