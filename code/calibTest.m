%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Only calibration

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXPERIMENT PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear all                                                                 % we clear parameters?
% this is for debugging
win.DoDummyMode             = 0;                                            % (1) is for debugging without an eye-tracker, (0) is for running the experiment
%PsychDebugWindowConfiguration(2,0.7);%0.7);                                       % this is for debugging with a single screen

%  Screen parameters
 
win.whichScreen             = 0;                                            % (CHANGE?) here we define the screen to use for the experiment, it depend on which computer we are using and how the screens are conected so it might need to be changed if the experiment starts in the wrong screen
win.FontSZ                  = 20;                                           % font size
win.bkgcolor                = 0;                                          % screen background color, 127 gray
win.Vdst                    = 66;                                           % (!CHANGE!) viewer's distance from screen [cm]         
win.res                     = [1366 768];                                  %  horizontal x vertical resolution [pixels]
win.wdth                    = 51;                                           %  51X28.7 cms is teh size of Samsung Syncmaster P2370 in BPN lab EEG rechts
win.hght                    = 28.7;                                         % 
win.pixxdeg                 = win.res(1)/(2*180/pi*atan(win.wdth/2/win.Vdst));% 
win.dotSize                 = 3; % [% of window width]
win.calibType               = 'HV9';
win.margin                  = [16 8];

% Blocks and trials
% win.exp_trials              = 30;%256;
% win.t_perblock              = 10;
% win.calib_every             = 1; 
% win.trial_length            = 8;
% Device input during the experiment
win.in_dev                  = 1;                                            % (1) - keyboard  (2) - mouse  (3) - pedal (?)    
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXPERIMENT START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% (!CHANGE!) adjust this to the appropiate screen
if ismac                                                                    % this bit is just so I can run the experiment in my mac without a problem
    exp_path                = '/Users/jossando/trabajo/nystagmus/';              % path in my mac
else
    exp_path                = 'C:\Users\bpn\Documents\jpossandon\nystagmus\';
end

win.s_n                     = input('Subject number: ','s');                % subject id number, this number is used to open the randomization file
win.fnameEDF                = sprintf('s%02dC.EDF',str2num(win.s_n));       % EDF name can be only 8 letters long, so we can have numbers only between 01 and 99
pathEDF                     = fullfile(exp_path,'data',sprintf('s%02d',str2num(win.s_n)));                           % where the EDF files are going to be saved
if exist([pathEDF win.fnameEDF],'file')                                         % checks whether there is a file with the same name
    rp = input(sprintf('!Filename %s already exist, do you want to overwrite it (y/n)?',win.fnameEDF),'s');
    if (strcmpi(rp,'n') || strcmpi(rp,'no'))
        error('filename already exist')
    end
end
mkdir(pathEDF)
% win.s_age                   = input('Subject age: ','s');
% win.s_hand                  = input('Subject handedness for writing (l/r): ','s');
% win.s_gender                = input('Subject gender (m/f): ','s');
% setStr                      = sprintf('Subject %d\nAge %s\nHandedness %s\nGender %s\n',win.s_n,win.s_age,win.s_hand,win.s_gender); % setting summary
% fprintf(setStr); 

AssertOpenGL();                                                             % check if Psychtoolbox is working (with OpenGL) TODO: is this needed?
ClockRandSeed();                                                            % this changes the random seed

[IsConnected, IsDummy] = EyelinkInit(win.DoDummyMode);                      % open the link with the eyetracker
assert(IsConnected==1, 'Failed to initialize EyeLink!')
 
% ListenChar(2)                                                             % disable key listening by MATLAB windows(CTRL+C overridable)

prevVerbos = Screen('Preference','Verbosity', 2);                           % this two lines it to set how much we want the PTB to output in the command and display window 
prevVisDbg = Screen('Preference','VisualDebugLevel',3);                     % verbosity-1 (default 3); vdbg-2 (default 4)
Screen('Preference', 'SkipSyncTests', 2)                                    % for maximum accuracy and reliability

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% START PTB SCREEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[win.hndl, win.rect]        = Screen('OpenWindow',win.whichScreen,win.bkgcolor);   % starts PTB screen
% if win.rect(3)~=1280 || win.rect(4)~=960                                    % (!CHANGE!) if resolution is not the correct one the experiment stops
%     sca
%     Eyelink('Shutdown');       % closes the link to the eye-tracker
%     fclose(obj);               % closes the serial port
%     error('Screen resolution must be 1280x960')
% end
[win.cntr(1), win.cntr(2)] = WindowCenter(win.hndl);                        % get where is the display screen center
Screen('BlendFunction',win.hndl, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);     % enable alpha blending for smooth drawing
%HideCursor(win.hndl);                                                       % this to hide the mouse
Screen('TextSize', win.hndl, win.FontSZ);                                   % sets teh font size of the text to be diplayed
KbName('UnifyKeyNames');                                                    % recommended, called again in EyelinkInitDefaults
win.start_time = clock;


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INSTRUCTIONS IN GERMAN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if win.in_dev == 1
    txtdev = ['Leertaste dr' 252 'cken (press Space)'];
elseif win.in_dev == 2
    txtdev = 'Maustate klicken';
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EYE-TRACKER SETUP, OPEN THE EDF FILE AND ADDS INFO TO ITS HEADER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[win.el, win.elcmds] = setup_eyetracker(win, 1);                            % Setups the eye-tracker with the before mentioned parameters

% DrawFormattedText(win.hndl,txt1,'center','center',255,55);                  % This 'draws' the text, nothing is displayed until Screen flip
% Screen('Flip', win.hndl);                                                   % This is the command that changes the PTB display screen. Here it present the first instructions.
% 
% if win.in_dev == 1                                                          % Waiting for input according to decided device to continue
%     waitForKB_linux({'space'});                                             % press the space key in the keyboard
% elseif win.in_dev == 2
%     [clicks,x,y,whichButton] = GetClicks(win.hndl,0);                       % mouse clik
% end

OpenError = Eyelink('OpenFile', win.fnameEDF);                                  % opens the eye-tracking file. It can only be done after setting-up the eye-tracker 
if OpenError                                                                % error in case it is not possible, never happened that I know, but maybe if the small hard-drive aprtition of the eye=tracker is full
    error('EyeLink OpenFile failed (Error: %d)!', OpenError), 
end
% Eyelink('Command', sprintf('add_file_preamble_text ''%s''', setStr));       % this adds the information about subject to the end of the header  
wrect = Screen('Rect', win.hndl);                                           
Eyelink('Message','DISPLAY_COORDS %d %d %d %d', 0, 0, wrect(1), wrect(2));  % write display resolution to EDF file

%ListenChar(2)                                                               % disable MATLAB windows' keyboard listen (no unwanted edits)


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EYE-TRACKER CALIBRATION AND VALIDATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% EyelinkDoTrackerSetup(win.el);                                              % calibration/validation (keyboard control)
% Eyelink('WaitForModeReady', 500);

% [image,map,alpha]   = imread([exp_path 'stimuli/blackongrt.jpg']);          % drift correction dot image
% fixIndex            = Screen('MakeTexture', win.hndl, image);               % this is one of the way PTB deals with images, the image matrix is transformed in a texture with a handle that can be user later to draw the image in theb PRB screen


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THE ACTUAL EXPERIMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
b                   = 1;                                                    % block flag
for nT = 1%:nTrials                                                          % loop throught the experiment trials
    
     
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % BLOCK START
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        EyelinkDoTrackerSetup(win.el);

        
        caldata = do_calib(win,nT);
        
        Screen('Flip', win.hndl);

        Eyelink('WaitForModeReady', 50);

end
win.end_time = clock;
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Finishing EDF file and transfering info (in case experiment is interrupted
% this can be run to save the eye-tracking data)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% Task Iteration done; save files, restore stuff, DON'T clear vars %%%%
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

% save([pathEDF,win.fnameEDF(1:end-3),'mat'],'win')
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
% fclose(obj);                                                                % close the serial port
ListenChar(1)             