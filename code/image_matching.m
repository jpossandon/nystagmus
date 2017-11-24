
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREAMBLE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this si to minimize destop when started from bat
if exist('minDesktop')
    if minDesktop ==1
        desktop = com.mathworks.mde.desk.MLDesktop.getInstance();
        mf = desktop.getMainFrame();
        mf.setMinimized(true);
    end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXPERIMENT PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
% this is for debugging
win.DoDummyMode             = 0;                                            % (1) is for debugging without an eye-tracker, (0) is for running the experiment
% PsychDebugWindowConfiguration(0.5);%0.7);                                       % this is for debugging with a single screen

% Screen parameters
win.whichScreen             = 0;                                            % (CHANGE?) here we define the screen to use for the experiment, it depend on which computer we are using and how the screens are conected so it might need to be changed if the experiment starts in the wrong screen
win.FontSZ                  = 20;                                           % font size
win.bkgcolor                = [153 153 153]; 
win.foregroundcolour        = [0 0 0]; % CLUT color idx (for Psychtoolbox functions)
win.msgfontcolour           = [0 0 0];% screen background color, 127 gray
win.Vdst                    = 66;                                           % (!CHANGE!) viewer's distance from screen [cm]         
win.wdth                    = 42;%51;                                           %  51X28.7 cms is teh size of Samsung Syncmaster P2370 in BPN lab EEG rechts
win.hght                    = 23;%28.7;                                         % 42x23 is HP screen in eyetrackin clinic
win.dotSize                 = 4; % [% of window width]
win.calibType               = 'HV9';
win.calibration_type        = 'sample';
win.dotflickfreq            = 5;                                          % Hz
win.margin                  = [20 16];

win.waitframes              = 1;
win.manual_select           = 1;

% Blocks and trials
win.exp_trials              = 56;
win.t_perblock              = 28;
win.calib_every             = 1; 
win.trial_length            = 4;
% Device input during the experiment
win.in_dev                  = 1;                                            % (1) - keyboard  (2) - mouse  (3) - pedal (?)    
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXPERIMENT START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% (!CHANGE!) adjust this to the appropiate screen
if ismac                                                                    % this bit is just so I can run the experiment in my mac without a problem
    exp_path                = '/Users/jossando/trabajo/India/';              % path in my mac
else
%    exp_path                = 'C:\Users\bpn\Documents\jpossandon\nystagmus\';
    exp_path                = 'C:\EXPERIMENTS\freeviewing\';
end

% Input Dialog Box
prompt     = {'Subject Number:','Type (1-identity; 2-emotion)'};
dlg_title  = 'Image Matching';
num_lines  = 1;
defaultans = {'',''};
answer     = inputdlg(prompt,dlg_title,num_lines,defaultans);
% win.s_n  = input('Subject number: ','s');                % subject id number, this number is used to open the randomization file
win.s_n    = answer{1};

%select between identity and emotion
if strcmp(answer{2},'1')
    exptype  = 'ID';
elseif strcmp(answer{2},'2')
    exptype  = 'EM';
end
win.fnameEDF = sprintf('s%03d%s.EDF',str2num(win.s_n),exptype);       % EDF name can be only 8 letters long, so we can have numbers only between 01 and 99
pathEDF      = fullfile(exp_path,'data',sprintf('s%03d',str2num(win.s_n)),filesep);                           % where the EDF files are going to be saved
% if exist([pathEDF win.fnameEDF],'file')                                         % checks whether there is a file with the same name
%     rp = input(sprintf('!Filename %s already exist, do you want to overwrite it (y/n)?',win.fnameEDF),'s');
%     if (strcmpi(rp,'n') || strcmpi(rp,'no'))
%         error('filename already exist')
%     end
% end

mkdir(pathEDF)                                  % edf saving worked before without need to makedir but not anymore
setStr       = sprintf('Subject %s\n',win.s_n); % setting summary
fprintf(setStr); 

AssertOpenGL();                                                             % check if Psychtoolbox is working (with OpenGL) TODO: is this needed?
ClockRandSeed();                                                            % this changes the random seed
commandwindow;
 
% ListenChar(2)   % TODO: disable key listening by MATLAB windows(CTRL+C overridable)

prevVerbos = Screen('Preference','Verbosity', 2);                           % this two lines it to set how much we want the PTB to output in the command and display window 
prevVisDbg = Screen('Preference','VisualDebugLevel',0);                     % verbosity-1 (default 3); vdbg-2 (default 4)
Screen('Preference', 'SkipSyncTests', 2) % TODO:change back to zero                               % for maximum accuracy and reliability

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% START PTB SCREEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'UseVirtualFramebuffer');
% [p.w, p.wrect] = PsychImaging('OpenWindow', p.scrnum, [0 0 0]);
[win.hndl, win.rect]        = PsychImaging('OpenWindow',win.whichScreen,win.bkgcolor);   % starts PTB screen
Priority(MaxPriority(win.hndl));
pscr                        = Screen('Resolution',win.whichScreen);
win.ifi                     = 1/pscr.hz;

win.res                     = win.rect(3:4);%[1366 768];%[1920 1080];%                                  %  horizontal x vertical resolution [pixels]
win.pixxdeg                 = win.res(1)/(2*180/pi*atan(win.wdth/2/win.Vdst));% 

[win.cntr(1), win.cntr(2)]  = WindowCenter(win.hndl);                        % get where is the display screen center
Screen('BlendFunction',win.hndl, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);     % enable alpha blending for smooth drawing
% HideCursor(win.hndl);        %TODO: uncomment                                                   % this to hide the mouse
Screen('TextSize', win.hndl, win.FontSZ);                                   % sets teh font size of the text to be diplayed
KbName('UnifyKeyNames');                                                    % recommended, called again in EyelinkInitDefaults
win.start_time              = clock;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EYE-TRACKER SETUP, OPEN THE EDF FILE AND ADDS INFO TO ITS HEADER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[win.el, win.elcmds] = setup_eyetracker(win, 1);                            % Setups the eye-tracker with the before mentioned parameters

OpenError            = Eyelink('OpenFile', win.fnameEDF);                                  % opens the eye-tracking file. It can only be done after setting-up the eye-tracker 
if OpenError,error('EyeLink OpenFile failed (Error: %d)!', OpenError),end   % error in case it is not possible, never happened that I know, but maybe if the small hard-drive aprtition of the eye=tracker is full
Eyelink('Command', sprintf('add_file_preamble_text ''%s''', setStr));       % this adds the information about subject to the end of the header  
wrect = Screen('Rect', win.hndl);                                           
Eyelink('Message','DISPLAY_COORDS %d %d %d %d', 0, 0, wrect(1), wrect(2));  % write display resolution to EDF file

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EYE-TRACKER CALIBRATION AND VALIDATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% EyelinkDoTrackerSetup(win.el);                                              % calibration/validation (keyboard control)
% Eyelink('WaitForModeReady', 500);

% [image,map,alpha]   = imread([exp_path 'stimuli/blackongrt.jpg']);          % drift correction dot image
% fixIndex            = Screen('MakeTexture', win.hndl, image);               % this is one of the way PTB deals with images, the image matrix is transformed in a texture with a handle that can be user later to draw the image in theb PRB screen

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Randomization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
do_image_matching_rand

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THE ACTUAL EXPERIMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% nTrials =33
escape_flag     = 0;
b               = 0;           %block counter                                               % block flag
for nT = 1:nTrials                                                          % loop throught the experiment trials
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % BLOCK START
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if  win.block_start(nT) == 1                                                % if it is a trial that starts a block   
        b = b+1;
        EyelinkDoTrackerSetup(win.el);
        [caldata,calibraw,dotinfo] = do_calib(win,nT,win.DoDummyMode);
        win.calib(b).caldata = caldata;
        win.calib(b).calibraw = calibraw;
        win.calib(b).dotinfo = dotinfo;
        Screen('Flip', win.hndl);
        win.response(nT) = NaN;
        win.result(nT)   = NaN;
        continue
    else
        image           = imread(fullfile(exp_path,'images','33',...
                                        win.image{nT}));      
        postextureIndex	= Screen('MakeTexture', win.hndl, image);   % makes the texture of this trial image
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % TRIALS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Eyelink('message','TRIALID %d', nT);                                % message about trial start in the eye-tracker
   	Eyelink('Command',...                                               % display in the eyetracker what is going on
        'record_status_message ''Block %d Image 1 Trial %d''',b,nT);
    
    Eyelink('StartRecording'); % RECORDING STARTS

    Screen('FillRect', win.hndl, win.bkgcolor);                         % remove what was writte or displayed
    % CALIBRATION DOT
    dotrect1 = [0 0 win.dotSize*win.rect(3)/100 win.dotSize*win.rect(3)/100];
    dotrect1 = CenterRectOnPoint(dotrect1, win.cntr(1),win.cntr(2) );
    dotrect2 = [0 0 win.dotSize*win.rect(3)/100*.3 win.dotSize*win.rect(3)/100*.3];
    dotrect2 = CenterRectOnPoint(dotrect2, win.cntr(1),win.cntr(2) );
    
%     if win.pairOrder(nT)==2
%         noise = 255*rand(size(image,1),size(image,2));
%         pretextureIndex	= Screen('MakeTexture', win.hndl, noise);
%         Screen('DrawTexture', win.hndl, pretextureIndex);
%     end
    Screen('FillOval', win.hndl, win.foregroundcolour, dotrect1);
    Screen('FillOval', win.hndl, win.bkgcolor, dotrect2);

    Screen('Flip', win.hndl);
    Eyelink('WaitForModeReady', 50);
    WaitSecs(1)
    Screen('FillRect', win.hndl, win.bkgcolor);
    Screen('DrawTexture', win.hndl, postextureIndex);                   % draw the trial image
       
    if nT==1
        win.el.eye_used = Eyelink('EyeAvailable');
        if win.el.eye_used==win.el.BINOCULAR,                           % (!TODO!) this I do not know yet
            win.el.eye_used = win.el.LEFT_EYE;
        end
    end

    Screen('Flip', win.hndl);                                               % actual image change, we message it to the eye-tracke and set the timer
    Eyelink('message','SYNCTIME');                                          % so trial zero time is just after image change
    tstart      = GetSecs;                                                  % timer trial start
    last_stim   = tstart;                                                   % in this case, this mean image appearace
 
    Eyelink('message','METATR image %s',win.image{nT});               % we send relevant information to the eye-tracker file, here which image
    Eyelink('WaitForModeReady', 50);
    Eyelink('message','METATR block_start %d',win.block_start(nT));         % if it was the first image in the block
    Eyelink('WaitForModeReady', 50);
    Eyelink('message','METATR pair_order %d',win.pairOrder(nT));         % if it was the first image in the block
    Eyelink('WaitForModeReady', 50);
    Eyelink('message','METATR ttype %d',win.ttype(nT));         % if it was the first image in the block
   
    % to stop
    while GetSecs<tstart+win.trial_length                           % lopp until trials finishes
       [keyIsDown,seconds,keyCode] = KbCheck;
         if keyIsDown
            if keyCode(KbName('escape')) 
               Eyelink('StopRecording');
               escape_flag = 1;
               sca
               break
            end
         end
    end
    
    if ~escape_flag
        Eyelink('StopRecording');
        Eyelink('WaitForModeReady', 50);

        if win.pairOrder(nT)==2
           if strcmp(exptype,'ID')
                Screen('DrawText', win.hndl, 'SAME IDENTITY (S)  DIFFERENT IDENTITY (D)', win.cntr(1), win.cntr(2), win.foregroundcolour);
           elseif strcmp(exptype,'EM')
                Screen('DrawText', win.hndl, 'SAME EMOTION (S)  DIFFERENT EMOTION (D)', win.cntr(1), win.cntr(2), win.foregroundcolour);
           end
            Screen('Flip', win.hndl); 
            while 1
                [keyIsDown,seconds,keyCode] = KbCheck;
                 if keyIsDown
                    if keyCode(KbName('S')) 
                        win.response(nT) = 1;
                        break
                    end
                    if keyCode(KbName('D')) 
                        win.response(nT) = 2;
                        break
                    end
                 end
            end
            if strcmp(exptype,'ID')
                if (ismember(win.ttype(nT),[1 2]) && win.response(nT) == 1) || ...
                        (ismember(win.ttype(nT),[3 4]) && win.response(nT) == 2) 
                    win.result(nT) = 1;
                elseif (ismember(win.ttype(nT),[1 2]) && win.response(nT) == 2) || ...
                        (ismember(win.ttype(nT),[3 4]) && win.response(nT) == 1) 
                    win.result(nT) = 0; 
                end
            end
        else
             win.response(nT) = NaN;
             win.result(nT)   = NaN; 
        end
    end
    if escape_flag
        break
    end
end
win.end_time = clock;
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Finishing EDF file and transfering info (in case experiment is interrupted
% this can be run to save the eye-tracking data)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if escape_flag
    saveData = questdlg('Experiment Interrupted, do you wish to save data aquired sofar?',...
        'Interrupted','Yes','No','Cancel','No'); 
else
    saveData = 'Yes';
end

%%%%% Task Iteration done; save files, restore stuff, DON'T clear vars %%%%
if strcmp(saveData,'Yes')
    save([pathEDF,win.fnameEDF(1:end-3),'mat'],'win')
    Eyelink('CloseFile');
    Eyelink('WaitForModeReady', 500); % make sure mode switching is ok
    if ~win.DoDummyMode
        % get EDF->DispPC: file size [bytes] if OK; 0 if cancelled; <0 if error
        rcvStat = Eyelink('ReceiveFile', win.fnameEDF, pathEDF,1);
        if rcvStat > 0 % only sensible if real connect
            fprintf('EDF received to %s (%.1f MiB).\n',pathEDF,rcvStat/1024^2);
        else
            fprintf(2,'EDF file reception error: %d.\n', rcvStat);
        end
    end
end

% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CLOSING ALL DEVICES, PORTS, ETC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Most of the commands below are important for being able to restart the
% experiment, in the case the experiment crushs they should be entered
% manually

% A known issue: Eyelink('Shutdown') crashing Matlab in 64-bit Linux
% cf. http://tech.groups.yahoo.com/group/psychtoolbox/message/12732
% not anymore it seems
%if ~IsLinux(true), Eyelink('Shutdown'); end
Eyelink('Shutdown');                                                        % close the link to the eye-tracker

Screen('CloseAll');                                                         % close the PTB screen
Screen('Preference','Verbosity', prevVerbos);                               % restore previous verbosity
Screen('Preference','VisualDebugLevel', prevVisDbg);                        % restore prev vis dbg
% fclose(obj);
% % close the serial port
ListenChar(1)                                                               % restore MATLAB keyboard listening (on command window)
