function [caldata,debug] = do_calib(win,TRIALID,dummy)
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
%   win.dotflickfreq - frequency of fliquering of calibratin dot 
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

%ShowHideWinTaskbarMex(0)

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
% indxs;

Screen('FillRect', win.hndl, win.bkgcolor);                                 % remove what was written or displayed
Screen('Flip', win.hndl);

if ~dummy
    Eyelink('Command',...                                                       % display in the eyetracker what is going on
                'record_status_message ''Custom Calibration Trial %d''',TRIALID);
    Eyelink('WaitForModeReady', 50);      
    Eyelink('message','TRIALID %d', TRIALID);                                   % message about trial start in the eye-tracker
    Eyelink('WaitForModeReady', 50); 
    Eyelink('StartRecording');
    Eyelink('WaitForModeReady', 50); 
    Eyelink('message','SYNCTIME');  
end

% cc is current calibration dot?
% validation_flag  

clType      = win.calibration_type;  
cc_dot      = 1;    validation_flag  = 0;                                  % cc_dot keeps track of which calibration points is being tested according to the randomization in index
calibraw    = [];   calibsac         = [];                                 % calibraw and calibsac are structures that contain the calibration information per eye   
n           = 1;    ns          = [1 1];                                   % these are indexes used to fill calibraw calibsa validraw and validsac
nv          = 1;    nsv         = [1 1];

% make calibration dot rectangles
dotrectOut = [0 0 win.dotSize*win.rect(3)/100 win.dotSize*win.rect(3)/100];
dotrectIn = [0 0 win.dotSize*win.rect(3)/100*.3 win.dotSize*win.rect(3)/100*.3];

% load colormap into cmap
load('hsvcolormap')

while cc_dot < length(indxs)+1        
    % plots the respective calibration dot
    
    dotrect1 = CenterRectOnPoint(dotrectOut, dotinfo.calibpos(indxs(cc_dot),1),dotinfo.calibpos(indxs(cc_dot),2) );
    dotrect2 = CenterRectOnPoint(dotrectIn, dotinfo.calibpos(indxs(cc_dot),1),dotinfo.calibpos(indxs(cc_dot),2) );
    Screen('FillOval', win.hndl, 255, dotrect1);
    Screen('FillOval', win.hndl, 0, dotrect2);

    last_dotTime = Screen('Flip', win.hndl);                                % last_dotTime for an easy flickering 
    
    if ~dummy
        Eyelink('message','METATR dotpos %d',indxs(cc_dot));                    % position of the calibration dot of next data as an index
    
        % get aprox time of dot appearance in eyetracker time
        status = 1;
        while status
            status = Eyelink('RequestTime');
        end
        Eyelink('WaitForModeReady', 50);

        % order and time of presenting the calibration dot, we are saving
        % always only the timing of the last dot presented for a given position
        dotinfo.tstart_dots(cc_dot)   = Eyelink('ReadTime');
    else
        dotinfo.tstart_dots(cc_dot)   = GetSecs*1000;
    end
    
    if validation_flag == 0
        dotinfo.dot_order(cc_dot,1)   = indxs(cc_dot);
    end
        
    % the calibration is placed by the experimenter, needs to visuallz
    % cheeck that the subject has moved to the right position
    % Pressing SPACE make the calibration to progress and BACKSPACE to go
    % back
    while 1
         [keyIsDown,seconds,keyCode] = KbCheck;
         if keyIsDown
            if keyCode(KbName('space'))
                %[calibraw,calibsac] =
                %showandSelect(win,calibraw,calibsac,dotinfo(cc_dot)); here we will plot and select but too tired today
                cc_dot = cc_dot+1;
                break;
            elseif keyCode(KbName('BackSpace'))   % DELETE and BACKSPACE?
                cc_dot = cc_dot-1;
                if cc_dot==0
                    cc_dot=1;
                end
                  break;
            end
            
         end

        if ~dummy
            [data,type] = get_ETdataraw;                                      % this is to get data online to estimate calibration coefficients with calibdata and be able to do gaze contingent experiments              
        else        
            [mx, my]  = GetMouse(win.hndl);
            data.time = GetSecs*1000;
            data.px   = [mx+rand*100 mx+100+rand*100];
            data.py   = [my+rand*100 my+100+rand*100];
            data.pa   = [1 1];
            type      = 200;
        end


        if type==200   % samples
            for ey = 1:size(data.px,2)
                if validation_flag == 0
                    calibraw(ey).time(:,n)  = data.time;
                    calibraw(ey).rawx(:,n)  = data.px(ey);                                   %px,py are raw data, gx,gy gaze data; hx,hy headref, data from both eye might be included. The easiest would be to use the uncalibrated GAZE gx,gy data             
                    calibraw(ey).rawy(:,n)  = data.py(ey);
                    calibraw(ey).pa(:,n)    = data.pa(ey);
                else
                    validraw(ey).time(:,nv)  = data.time;
                    validraw(ey).rawx(:,nv)  = data.px(ey);                                   %px,py are raw data, gx,gy gaze data; hx,hy headref, data from both eye might be included. The easiest would be to use the uncalibrated GAZE gx,gy data             
                    validraw(ey).rawy(:,nv)  = data.py(ey);
                    validraw(ey).pa(:,nv)    = data.pa(ey);
                end
            end
             n  = n+1;                                                     % we need different indexes to fill correctly the different structures
             nv = nv+1;
         elseif type==6   % end saccade
             sEye = data.eye+1; %%% !!! isn't this now always using one (the same) eye? ANSWeR: I do not think so, saccade and fication events are different lines for each eye
             if validation_flag == 0
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
        % this is to do the flichering of the calibration dot, with change
        % in size and color
        changeinSize = (sin(2*pi*win.dotflickfreq*GetSecs-last_dotTime)+1)/2;
        dotrect1 = CenterRectOnPoint(ScaleRect(dotrectOut,changeinSize,changeinSize), dotinfo.calibpos(indxs(cc_dot),1),dotinfo.calibpos(indxs(cc_dot),2) );
        dotrect2 = CenterRectOnPoint( ScaleRect(dotrectIn,changeinSize,changeinSize), dotinfo.calibpos(indxs(cc_dot),1),dotinfo.calibpos(indxs(cc_dot),2) );
        Screen('FillOval', win.hndl,255.*cmap(ceil(GetSecs-last_dotTime),:), dotrect1);
        Screen('FillOval', win.hndl, 0, dotrect2);
        Screen('Flip', win.hndl);
%         WaitSecs(0.00001);


     end
    while KbCheck; end

    % at the end of one calibration, the result is displayed on screen
    if cc_dot == length(indxs)+1

        Screen('DrawDots', win.hndl, dotinfo.calibpos',win.dotSize*win.rect(3)/100/3,256,[0 0],1); % calibration dot position
    	Screen('DrawDots', win.hndl, dotinfo.calibpos',win.dotSize*win.rect(3)/100*.3/3,0,[0 0],1);

        if ~dummy   
            if strcmp(win.calibration_type,'saccade');
                eyes_with_sacc_data=length(calibsac);
            else          
%%%!!!!                
                eyes_with_sacc_data=2; %%%!!! does this work?
            end
        else
            eyes_with_sacc_data=2;
            calibsac=[1 1];
            validsac=[1 1];
        end
        

        for ey = 1:eyes_with_sacc_data    % loop through eyes that got saccade data
            if validation_flag == 0
                % this is the calibration calculation, ux and uy are used
                % to correct data, and to correct the validation
                [caldata(ey).ux,caldata(ey).uy,caldata(ey).correctedDotPos,caldata(ey).uncorrectedDotPos,xgaz,ygaz,debug] = calibdata(calibraw(ey),calibsac(ey),win,dotinfo,clType,0);
            
            else
                % for validation calibdata is colled only to get the uncorrected positions 
                [bap,bip,bup,uncorrectedDotPos,debug] = calibdata(validraw(ey),validsac(ey),win,dotinfo,clType,0);      %it seems that ingoring output with a tilde does not work in windows?
            end
            
            % LEFT EYE IS BLUE... RIGHT EYE IS RED
            if ey == 1, col = [0 0 255];, else col = [255 0 0];,end
            if validation_flag == 0
                Screen('DrawDots', win.hndl, [calibraw(ey).rawx(1,:);calibraw(ey).rawy(1,:)],4,col,[0 0],1);  %uncorrected data
                Screen('DrawDots', win.hndl, [xgaz;ygaz],6,col,[0 0],0);                                % corrected data
            end
            % corrected calibration positions
%             Screen('DrawDots', win.hndl, caldata(ey).correctedDotPos,win.dotSize/2*win.rect(3)/100/3,col,[0 0],1);              
%     	    Screen('DrawDots', win.hndl, caldata(ey).correctedDotPos,win.dotSize/2*win.rect(3)/100*.3/3,0,[0 0],1);
            if validation_flag == 1
                ey
                % the uncorrectedDotPos from the validation are corrected
                % with the coefficients obtained during the calibration
                correctedValidationPos = caldata(ey).ux'*[ones(1,size(uncorrectedDotPos,2));uncorrectedDotPos(1,:);uncorrectedDotPos(2,:);uncorrectedDotPos(1,:).^2;uncorrectedDotPos(2,:).^2];
                correctedValidationPos = [correctedValidationPos;caldata(ey).uy'*[ones(1,size(uncorrectedDotPos,2));uncorrectedDotPos(1,:);uncorrectedDotPos(2,:);uncorrectedDotPos(1,:).^2;uncorrectedDotPos(2,:).^2]];
                % plot the estimatied position of the calibration dots from the gaze during validation correctedwith the calibration coefiecients
                Screen('DrawDots', win.hndl, correctedValidationPos,win.dotSize/2*win.rect(3)/100/3,col,[0 0],0);              
                Screen('DrawDots', win.hndl, correctedValidationPos,win.dotSize/2*win.rect(3)/100*.3/3,0,[0 0],0);
                % draw a line between the absolute position of the
                % calibration dot and the validation position
                Screen('DrawLines',win.hndl, reshape([dotinfo.calibpos';correctedValidationPos],2,18),2,255,[0 0]);
                for pt = 1:size(dotinfo.dot_order,1)
                    calData(ey).error(dotinfo.dot_order(pt)) = sqrt((dotinfo.calibpos(dotinfo.dot_order(pt),1)-correctedValidationPos(1,dotinfo.dot_order(pt))).^2+(dotinfo.calibpos(dotinfo.dot_order(pt),2)-correctedValidationPos(2,dotinfo.dot_order(pt))).^2)./win.pixxdeg;
                    Screen('DrawText', win.hndl,sprintf('%2.2f',calData(ey).error(dotinfo.dot_order(pt))),correctedValidationPos(1,dotinfo.dot_order(pt)),correctedValidationPos(2,dotinfo.dot_order(pt)),[255 255 0]);
                end
            end
            for pt = 1:size(dotinfo.dot_order,1)
               Screen('DrawText', win.hndl,num2str(dotinfo.dot_order(pt)),caldata(ey).correctedDotPos(1,dotinfo.dot_order(pt)),caldata(ey).correctedDotPos(2,dotinfo.dot_order(pt)));
            end
            
            % save data
            caldata(ey).calibraw = calibraw(ey);
            caldata(ey).calibsac = calibsac(ey);
            caldata(ey).dotinfo  = dotinfo;
            caldata(ey).validraw  = dotinfo;
        
        end
        if validation_flag == 0
            Screen('DrawText', win.hndl, 'CONTINUE TO VALIDATION (V)     REPEAT CALIBRATION (C)     CONTINUE EXP(SPACE)', win.rect(3)*.1, 400, 255);
        else
            Screen('DrawText', win.hndl, 'ACCEPT VALIDATION (SPACE)    REPEAT VALIDATION (V)    REPEAT CALIBRATION (C)', win.rect(3)*.1, 400, 255);
        end
        Screen('Flip', win.hndl);
    
        while 1
            [keyIsDown,seconds,keyCode] = KbCheck;
             if keyIsDown
                if keyCode(KbName('V'))         % CONTINUE TO VALIDATION
                    cc_dot = 1;
                    validation_flag = 1;
                    validraw = [];
                    validsac = [];
                    break;
                elseif keyCode(KbName('space'))         % CONTINUE TO EXPERIMENT
                     break;
                elseif keyCode(KbName('C'))                     % REDO EVERYTHING
                    cc_dot = 1;
                    validation_flag = 0;
                    calibraw = [];
                    calibsac = [];
                    break
                end
                 
             end
        end
%     indxs  
    end
    
end

if ~dummy
    Eyelink('StopRecording');
end

end
%ShowHideWinTaskbarMex(1)