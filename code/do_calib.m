function caldata = do_calib(win,TRIALID)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% do_calib(win,TRIALID)
% 
% win.hndl      - Psychtoolbox handle for the already open PTB Screen window
% win.rect      - rect of the open PTB Screen window
% win.bkgcolor  - background color
% win.dotSize   - size of the calibration dots in pixels
% win.calibType - only 'HV9' for now, grid of nine points 
% win.margin    - [hor vert], margin around the calibration area in %, i.e.
%                   [10 20] means 10% of the screen size to the left and to
%                   the right, and 20% up and down.
% TRIALID       - trial number that will correspond to the calibration in
%                   edf file
%
% JPO, Hamburg 8.11.16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


mPix                        = win.rect(3:4).*win.margin/100;
if strcmp(win.calibType,'HV9')                                              % positions of calibration dots
   xy(1:9,1)  = repmat(mPix(1):(win.rect(3)-2*(mPix(1)))/2:win.rect(3)-mPix(1),1,3);
   xy(1:9,2)  = reshape(repmat(mPix(2):(win.rect(4)-2*(mPix(2)))/2:win.rect(4)-mPix(2),3,1),9,1);
   indxs      = [5,randsample([1:4,6:9],8),5];
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

cc      = 1;
auxraw  = [];
auxsac  = [];
n       = 1;
ns      = 1;
while cc < length(indxs)+1        
    Screen('DrawDots', win.hndl, xy(indxs(cc),:),win.dotSize*win.rect(3)/100,256,[0 0],1);
    Screen('DrawDots', win.hndl, xy(indxs(cc),:),win.dotSize*win.rect(3)/100*.3,0,[0 0],1);
    Screen('Flip', win.hndl);
    Eyelink('message','METATR dotpos %d',indxs(cc));                        % position of the calibration dot of next data as an index
    while 1
         [keyIsDown,seconds,keyCode] = KbCheck;
         if keyIsDown
            if keyCode(KbName('space'))
                cc = cc+1;
                break;
            elseif keyCode(KbName('DELETE')) || keyCode(KbName('BackSpace'))                     % DELETE and BACKSPACE?
                cc = cc-1;
                if cc==0
                    cc=1;
                end
                  break;
            end
            
        end
        [data,type] = get_ETdataraw;                                      % TODO: this is to get data online to estimate calibration coefficients with calibdata and be able to do gaze contingent experiments              
        if type==200   % samples
            for ey = 1:size(data.px,2)
                auxraw(ey).traw(:,n)  = data.time;
                auxraw(ey).rawx(:,n)  = data.px(ey);                                   %px,py are raw data, gx,gy gaze data; hx,hy headref, data from both eye might be included            
                auxraw(ey).rawy(:,n)  = data.py(ey);
                auxraw(ey).gx(:,n)    = data.gx(ey);
                auxraw(ey).gy(:,n)    = data.gy(ey);
                auxraw(ey).pa(:,n)    = data.pa(ey);
            end
             n = n+1;
%          elseif type==6   % end saccade
%             auxsac(data.eye).start(:,ns) = data.sttime;
%             auxsac(data.eye).end(:,ns)   = data.entime;
%             auxsac(data.eye).eye(:,ns)   = data.eye;
%             auxsac(data.eye).genx(:,ns)  = data.genx;                                   %px,py are raw data, gx,gy gaze data; hx,hy headref            
%             auxsac(data.eye).geny(:,ns) = data.geny;
%              ns = ns+1;
        end
       
     end
    while KbCheck; end
%     if cc == length(indxs)+1
%         auxraw.dotpos = 'drift';
%         caldata(length(indxs)).raw =auxraw;
%         caldata(length(indxs)).sac =auxsac;
%         
%     else
%         auxraw.dotpos = xy(indxs(cc-1),:);
%         caldata(indxs(cc-1)).raw =auxraw;
%         caldata(indxs(cc-1)).sac =auxsac;
%     end
    if cc == length(indxs)+1
        for ey = 1:length(auxraw)
            auxraw(ey).raw =auxraw(ey);
    %         auxraw(ey).sac =auxsac;
            Screen('DrawDots', win.hndl, xy',win.dotSize*win.rect(3)/100,256,[0 0],1);
            Screen('DrawDots', win.hndl, xy',win.dotSize*win.rect(3)/100*.3,0,[0 0],1);
            %   [ux,uy,xgaz,ygaz] = calibdata(auxraw(ey),trial(tr).(useye).saccade,win,dotinfo,'sample',1);
            Screen('DrawDots', win.hndl, [auxraw(ey).raw.rawx(1,:);auxraw(ey).rawy(1,:)],10,[0 0 256],[0 0],ey);
            Screen('DrawDots', win.hndl, [auxraw(ey).gx(1,:);auxraw(ey).gy(1,:)],10,[0 0 256],[0 0],ey-1);
        end
          Screen('DrawText', win.hndl, 'CONTINUE (SPACE)      REPEAT (BACKKSPACE)', 400, 400, 255);
        %end
           Screen('Flip', win.hndl);
        while 1
            [keyIsDown,seconds,keyCode] = KbCheck;
             if keyIsDown
                if keyCode(KbName('space'))         % CONTINUE TO EXPERIMENT
                    break;
                elseif keyCode(KbName('DELETE')) || keyCode(KbName('BackSpace'))                     % DELETE and BACKSPACE?
                    cc=1;
                    auxraw =[];
                    auxsac = [];
                    break
                end
                 
             end
        end
   %    
    end
end   
  % here give feedback and ask for redo or finish
Eyelink('StopRecording');