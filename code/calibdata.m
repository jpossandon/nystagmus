function [ux,uy] = calibdata(xraw,yraw,traw,calibpos,tstart_dots,dot_order)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [calibmat,xgaz,ygaz] = calib(xraw,yraw,traw,calibpos,tstart_dots,dot_order)
% This function implements D. Stample 9-point calibration method (Behavior
% Research Methods, Instruments & Computers (1993), 25:137-142). It is
% designed to be used with the custom calibration function do_calib.m
%  
%   Inputs:
%       - xraw,yraw     , raw eye position during the whole 9-point calibration
%                       period. This is, the complete raw data of the
%                       calibration trial performed with do_calib.m
%       - traw          , corresponding sample time data
%       - calibpos      , 9x2 matrix describing the position in the screen,
%                       in pixels, of the calibration points, according to the
%                       following mapping between rows and screen positions:
%                           1 2 3     this calibpos can be obtained
%                           4 5 6     from the output of do_calib:
%                           7 8 9     calibpos =  reshape([calibdata(1:9).dotpos],2,9)'
%       - tstart_dots   , time of appearance of each calibration dot
%       - dot_order     , correspondace between calibpos rows and
%                         tstart_dots times
%                
%   Outputs:
%       - ux,uy         , coefficients of cuadratic mapping between raw
%                       data and the position of calibration dots in
%                       screen. To obtain calibrated data from gaze data,
%                       xgaze = ux'*[ones(1,size(xraw',2));xraw';yraw';xraw'.^2;yraw'.^2];
%                       ygaze = uy'*[ones(1,size(yraw',2));xraw';yraw';xraw'.^2;yraw'.^2];
%                          
% JPO, Hamburg, 11-2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Finding raw position at calib position.
% At the moment only taking the median position, we can implement later
% that it takes only in account position after a saccade (~fast period of the nystagmus)

for p = 1:size(dot_order,1)
    
    pos_startT  = tstart_dots(p);
    
    if p == size(dot_order,1)
        pos_endT = traw(end);
    else
        pos_endT = tstart_dots(p+1);
    end
    
    % median gaze position within 100 and end-100 ms of the period the
    % calibration dot is on screen
    aux_calib     = traw>pos_startT+100 & traw<pos_endT-100;
    if p == size(dot_order,1) & dot_order(p)==5                             % the last-point should recenter the calibration grid, I have not tested so it is not yet used below 
        x_centerCorrect = median(xraw(aux_calib)); 
        y_centerCorrect = median(yraw(aux_calib));
    else % this by design will re-write values where calibration occured more than once
        xr(dot_order(p)) = median(xraw(aux_calib)); 
        yr(dot_order(p)) = median(yraw(aux_calib)); 
    end
end


ixC = [2,4,5,6,8];
A   = [ones(5,1),xr(ixC)',yr(ixC)',xr(ixC).^2',yr(ixC).^2'];
bx  = calibpos(ixC,1);
by  = calibpos(ixC,2);


ux  = A\bx;
uy  = A\by;

xgazaux = ux'*[ones(1,size(xraw',2));xraw';yraw';xraw'.^2;yraw'.^2];
ygazaux = uy'*[ones(1,size(yraw',2));xraw';yraw';xraw'.^2;yraw'.^2];

xgaz    = xgazaux;
ygaz    = ygazaux;


% cuadrant correction, this does not work well yet
% ixC = [1,3,7,9];
% 
% xi      = ux'*[ones(1,size(ixC,2));xr(ixC);yr(ixC);xr(ixC).^2;yr(ixC).^2];
% yi      = uy'*[ones(1,size(ixC,2));xr(ixC);yr(ixC);xr(ixC).^2;yr(ixC).^2];
% m       = (calibpos(ixC,1)'-xi)./xi./yi;
% n       = (calibpos(ixC,2)'-yi)./xi./yi;  
    
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