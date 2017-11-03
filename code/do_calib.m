function caldata = do_calib(win,TRIALID)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% do_calib(win,TRIALID)
% 
% Custom calibration procedure, it inserts a calibration trial (#TRIALID)
% in the eye-tracker file and gives the coefficients to calibrate the data
% online
% The calibration is placed by the experimenter, 
% Pressing SPACE make the calibration to progress and BACKSPACE to go
% back, at the end of the calibration, the result of the procedure is
% displayed on the experiment screen and it can be accepted or repeated
% completly
%
% INPUT
%   win.hndl      - Psychtoolbox handle for the already open PTB Screen window
%   win.rect      - rect of the open PTB Screen window
%   win.bkgcolor  - background color
%   win.dotSize   - size of the calibration dots in pixels
%   win.calibType - only 'HV9' for now, grid of nine points 
%   win.margin    - [hor vert], margin around the calibration area in %, i.e.
%                   [10 20] means 10% of the screen size to the left and to
%                   the right, and 20% up and down.
%   TRIALID       - trial number that will correspond to the calibration in
%                   edf file
% OUTPUT
%   caldata: 
%       - ux,uy      ,coefficients of cuadratic mapping between raw
%                       data and the position of calibration dots in
%                       screen. To obtain calibrated data from gaze data,
%                       xgaze = ux'*[ones(1,size(xraw',2));xraw';yraw';xraw'.^2;yraw'.^2];
%                       ygaze =
%                       uy'*[ones(1,size(yraw',2));xraw';yraw';xraw'.^2;yraw'.^2];
%       -
% JPO, Hamburg 8.11.16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


mPix                        = win.rect(3:4).*win.margin/100;
if strcmp(win.calibType,'HV9')                                  
   % positions of calibration dots in 9 positions
   % 1 2 3
   % 4 5 6
   % 7 8 9
   dotinfo.calibpos(1:9,1)  = repmat(mPix(1):(win.rect(3)-2*(mPix(1)))/2:win.rect(3)-mPix(1),1,3);
   dotinfo.calibpos(1:9,2)  = reshape(repmat(mPix(2):(win.rect(4)-2*(mPix(2)))/2:win.rect(4)-mPix(2),3,1),9,1);
   indxs                    = [5,randsample([1:4,6:9],8),5];               % start and end in the midldle, other are random
end
indxs

Screen('FillRect', win.hndl, win.bkgcolor);                                 % remove what was written or displayed
Screen('Flip', win.hndl);

Eyelink('Command',...                                                       % display in the eyetracker what is going on
            'record_status_message ''Custom Calibration Trial %d''',TRIALID);
Eyelink('WaitForModeReady', 50);      
Eyelink('message','TRIALID %d', TRIALID);                                   % message about trial start in the eye-tracker
Eyelink('WaitForModeReady', 50); 
Eyelink('StartRecording');
Eyelink('WaitForModeReady', 50); 
Eyelink('message','SYNCTIME');  

clType      = 'saccade';
cc          = 1;    cv          = 0;
calibraw    = [];   calibsac    = [];
n           = 1;    ns          = [1 1];
nv          = 1;    nsv         = [1 1];
while cc < length(indxs)+1        
    % plots thee respective calibration dot
    Screen('DrawDots', win.hndl, dotinfo.calibpos(indxs(cc),:),...    
        win.dotSize*win.rect(3)/100,256,[0 0],1);
    Screen('DrawDots', win.hndl, dotinfo.calibpos(indxs(cc),:),...
        win.dotSize*win.rect(3)/100*.3,0,[0 0],1);
    Screen('Flip', win.hndl);
    Eyelink('message','METATR dotpos %d',indxs(cc));                        % position of the calibration dot of next data as an index
    
    % get aprox time of dot appearance in eyetracker time
    status = 1;
    while status
        status = Eyelink('RequestTime');
    end
    Eyelink('WaitForModeReady', 50);
    % order and time of presenting the calibration dot, we are saving
    % always only the last dot presented for a given position
    dotinfo.tstart_dots(cc)   = Eyelink('ReadTime');
    if cv == 0
        dotinfo.dot_order(cc,1)   = indxs(cc);
    end
        
    % the calibration is placed by the experimenter, needs to visuallz
    % cheeck that the subject has moved to the right position
    % Pressing SPACE make the calibration to progress and BACKSPACE to go
    % back
    while 1
         [keyIsDown,seconds,keyCode] = KbCheck;
         if keyIsDown
            if keyCode(KbName('space'))
                cc = cc+1;
                break;
            elseif keyCode(KbName('DELETE')) || keyCode(KbName('BackSpace'))   % DELETE and BACKSPACE?
                cc = cc-1;
                if cc==0
                    cc=1;
                end
                  break;
            end
            
        end
        [data,type] = get_ETdataraw;                                      % this is to get data online to estimate calibration coefficients with calibdata and be able to do gaze contingent experiments              
        if type==200   % samples
            for ey = 1:size(data.px,2)
                if cv == 0
                    calibraw(ey).time(:,n)  = data.time;
                    calibraw(ey).rawx(:,n)  = data.gx(ey);                                   %px,py are raw data, gx,gy gaze data; hx,hy headref, data from both eye might be included. The easiest would be to use the uncalibrated GAZE gx,gy data             
                    calibraw(ey).rawy(:,n)  = data.gy(ey);
                    calibraw(ey).pa(:,n)    = data.pa(ey);
                else
                    validraw(ey).time(:,nv)  = data.time;
                    validraw(ey).rawx(:,nv)  = data.gx(ey);                                   %px,py are raw data, gx,gy gaze data; hx,hy headref, data from both eye might be included. The easiest would be to use the uncalibrated GAZE gx,gy data             
                    validraw(ey).rawy(:,nv)  = data.gy(ey);
                    validraw(ey).pa(:,nv)    = data.pa(ey);
                end
            end
             n  = n+1;
             nv = nv+1;
         elseif type==6   % end saccade
             sEye = data.eye+1;
             if cv == 0
                calibsac(sEye).start(:,ns(sEye)) = data.sttime;
                calibsac(sEye).end(:,ns(sEye))   = data.entime;
                calibsac(sEye).eye(:,ns(sEye))   = sEye;
                calibsac(sEye).genx(:,ns(sEye))  = data.genx;                                   %px,py are raw data, gx,gy gaze data; hx,hy headref            
                calibsac(sEye).geny(:,ns(sEye))  = data.geny;
             else
                validsac(sEye).start(:,nsv(sEye)) = data.sttime;
                validsac(sEye).end(:,nsv(sEye))   = data.entime;
                validsac(sEye).eye(:,nsv(sEye))   = sEye;
                validsac(sEye).genx(:,nsv(sEye))  = data.genx;                                   %px,py are raw data, gx,gy gaze data; hx,hy headref            
                validsac(sEye).geny(:,nsv(sEye))  = data.geny;
              end
             ns(sEye) = ns(sEye)+1;
             nsv(sEye) = nsv(sEye)+1;
        end
       
     end
    while KbCheck; end

    % at the end of one calibratio, the result is displayed on screen
    if cc == length(indxs)+1
        Screen('DrawDots', win.hndl, dotinfo.calibpos',win.dotSize*win.rect(3)/100,256,[0 0],1); % calibration dot position
    	Screen('DrawDots', win.hndl, dotinfo.calibpos',win.dotSize*win.rect(3)/100*.3,0,[0 0],1);
          
        for ey = 1:length(calibsac)
             if cv == 0
                 try
                 [caldata(ey).ux,caldata(ey).uy,xyP,xyR,xgaz,ygaz] = calibdata(calibraw(ey),calibsac(ey),win,dotinfo,clType,0);
                 catch
                     ey
                 end
                 else
                 [bap,bip,bup,xyR] = calibdata(validraw(ey),validsac(ey),win,dotinfo,clType,0);      %it seems that ingoring output with a tilde does not work in windows?
             end
            
            if ey == 1, col = [0 0 256];, else col = [256 0 0];,end
            if cv == 0
                Screen('DrawDots', win.hndl, [calibraw(ey).rawx(1,:);calibraw(ey).rawy(1,:)],4,col,[0 0],1);  %uncorrected data
                Screen('DrawDots', win.hndl, [xgaz;ygaz],6,col,[0 0],0);                                % corrected data
            end
            % corrected calibration positions
            Screen('DrawDots', win.hndl, xyP,win.dotSize/2*win.rect(3)/100,col,[0 0],1);              
    	    Screen('DrawDots', win.hndl, xyP,win.dotSize/2*win.rect(3)/100*.3,0,[0 0],1);
            if cv == 1
                xyRP = caldata(ey).ux'*[ones(1,size(xyR,2));xyR(1,:);xyR(2,:);xyR(1,:).^2;xyR(2,:).^2];
                xyRP = [xyRP;caldata(ey).uy'*[ones(1,size(xyR,2));xyR(1,:);xyR(2,:);xyR(1,:).^2;xyR(2,:).^2]];
                Screen('DrawDots', win.hndl, xyRP,win.dotSize/2*win.rect(3)/100,col,[0 0],0);              
                Screen('DrawDots', win.hndl, xyRP,win.dotSize/2*win.rect(3)/100*.3,0,[0 0],0);
                Screen('DrawLines',win.hndl, reshape([xyP;xyRP],2,18),2,255,[0 0]);
                for p = 1:size(dotinfo.dot_order,1)
                    calData(ey).error(dotinfo.dot_order(p)) = sqrt((xyP(1,dotinfo.dot_order(p))-xyRP(1,dotinfo.dot_order(p))).^2+(xyP(2,dotinfo.dot_order(p))-xyRP(2,dotinfo.dot_order(p))).^2)./win.pixxdeg;
                    Screen('DrawText', win.hndl,sprintf('%2.2f',calData(ey).error(dotinfo.dot_order(p))),xyRP(1,dotinfo.dot_order(p)),xyRP(2,dotinfo.dot_order(p)),[255 255 0]);
                end
                % here calcualte validation errors and text it
            end
            for p = 1:size(dotinfo.dot_order,1)
               Screen('DrawText', win.hndl,num2str(dotinfo.dot_order(p)),xyP(1,dotinfo.dot_order(p)),xyP(2,dotinfo.dot_order(p)));
            end
        end
        if cv == 0
            Screen('DrawText', win.hndl, 'CONTINUE TO VALIDATION (V)     REPEAT CALIBRATION (C)     CONTINUE EXP(SPACE)', 400, 400, 255);
        else
            Screen('DrawText', win.hndl, 'ACCEPT VALIDATION (SPACE)    REPEAT VALIDATION (V)    REPEAT CALIBRATION (C)', 400, 400, 255);
        end
            Screen('Flip', win.hndl);
      
        while 1
            [keyIsDown,seconds,keyCode] = KbCheck;
             if keyIsDown
                if keyCode(KbName('V'))         % CONTINUE TO VALIDATION
                    cv = 1;
                    cc = 1;
                    validraw = [];
                    validsac = [];
                    break;
                elseif keyCode(KbName('space'))         % CONTINUE TO EXPERIMENT
                     break;
                elseif keyCode(KbName('C'))                     % REDO EVERYTHING
                    
                    cc = 1;
                    cv = 0;
                    calibraw = [];
                    calibsac = [];
                   
                    break
                end
                 
             end
        end
    indxs  
    end
    
end   
%caldata.calibraw = calibraw;
%caldata.auxsac = auxsac;
Eyelink('StopRecording');