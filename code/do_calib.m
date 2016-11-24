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

cc             = 1;
while cc < length(indxs)+1        
    Screen('DrawDots', win.hndl, xy(indxs(cc),:),win.dotSize*win.rect(3)/100,256,[0 0],1);
    Screen('DrawDots', win.hndl, xy(indxs(cc),:),win.dotSize*win.rect(3)/100*.3,0,[0 0],1);
    Screen('Flip', win.hndl);
    Eyelink('message','METATR dotpos %d',indxs(cc));                        % position of the calibration dot of next data as an index
    
    n = 1;
    auxcalib =[];
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
%         [data,type] = get_ETdataraw;                                      % TODO: this is to get data online to estimate calibration coefficients with calibdata and be able to do gaze contingent experiments              
%         if type==200   % samples
%             auxcalib.time(n,:) = data.time;
%             auxcalib.px(n,:) = data.px;
%             auxcalib.py(n,:) = data.py;
%             auxcalib.gx(n,:) = data.gx;
%             auxcalib.gy(n,:) = data.gy;
%             auxcalib.pa(n,:) = data.pa;
%         end
        n = n+1;
     end
    while KbCheck; end
    if cc == length(indxs)+1
        auxcalib.dotpos = 'drift';
        caldata(length(indxs)+1)=auxcalib;
    else
        auxcalib.dotpos = xy(indxs(cc-1),:);
        caldata(indxs(cc-1))=auxcalib;
    end
  end     
Eyelink('StopRecording');