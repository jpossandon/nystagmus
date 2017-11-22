%%
% Face Identity and emotion database are in folder 33
% filenames are A<gender><subjid><emotion>S_masked<mdiff>.jpg
% gender is 'F' or 'M'
% 7 subjid for F: 02,07,13,15,22,27,29
% 7 subjid for M: 05,06,07,11,27,29,31
% 7 emotions: AF, AN, DIS, HA, NE, SA, SU (afraid, anger,disgust, happy, neutral, sad, surprise)
% mdiff is 2 for F and nothing for M

sIDf   = [2,7,13,15,22,27,29];
sIDm   = [5,6,7,11,27,29,31];
EMstr  = {'AF','AN','DI','HA','NE','SA','SU'};
mdifM  = '';
mdifF  = '2';

if strcmp(exptype,'ID')
% there is 4 type of trial for identity matching:
%  ttype
% -  1  same identity/same emotion (only 7 posible trial per gender)
% -  2  same identity/diff emotion (21 posible comparison per ID )
% -  3  diff identity/same emotion (21 posible comparison per emotion)
% -  4  diff identity/diff emotion (1176 posible comparisons)
% we take 7 per category so 4*7*2= 56 images, we make sure that is balanced
% with respect to ID and emotion

    % female
    sIDs = sIDf;
    gend = 'F';
    % SI/SE
    EMcomb = EMstr(randperm(7));
    for fcomb = 1:14
        imFileNames{fcomb} = sprintf('A%s%02d%sS_masked%s.jpg',gend,sIDf(ceil(fcomb/2)),EMcomb{ceil(fcomb/2)},mdifF);
    end
    ttype = ones(1,14);
    % SI/DE
    while 1
        EMcombi = [randperm(7);randperm(7)];
        if ~any(diff(EMcombi)==0)  % only take pairs thar are different ID and each ID is shown only 2 times  
            break
        end
    end
    EMcomb = EMstr(EMcombi);
    for fcomb = 1:14
        imFileNames{14+fcomb} = sprintf('A%s%02d%sS_masked%s.jpg',gend,sIDf(ceil(fcomb/2)),EMcomb{fcomb},mdifF);
    end
    ttype = [ttype,2*ones(1,14)];
    % DI/SE
    while 1
        IDcomb = [sIDf(randperm(7));sIDf(randperm(7))];
        if ~any(diff(IDcomb)==0)   % only take pairs thar are different ID and each ID is shown only 2 times  
            break
        end
    end
    EMcomb = EMstr(randperm(7));
    for fcomb = 1:14
        imFileNames{28+fcomb} = sprintf('A%s%02d%sS_masked%s.jpg',gend,IDcomb(fcomb),EMcomb{ceil(fcomb/2)},mdifF);
    end
    ttype = [ttype,3*ones(1,14)];
    % DI/DE
    while 1
        IDcomb  = [sIDf(randperm(7));sIDf(randperm(7))];
        EMcombi = [randperm(7);randperm(7)];
        if ~any(diff(IDcomb)==0) & ~any(diff(EMcombi)==0)  % only take pairs thar are different ID and each ID is shown only 2 times  
            break
        end
    end
    EMcomb = EMstr(EMcombi);
    for fcomb = 1:14
        imFileNames{42+fcomb} = sprintf('A%s%02d%sS_masked%s.jpg',gend,IDcomb(fcomb),EMcomb{fcomb},mdifF);
    end
    ttype = [ttype,4*ones(1,14)];
end

win.image_rnd     = randsample(1:2:win.exp_trials,win.exp_trials/2);
win.image         = reshape([imFileNames(win.image_rnd);imFileNames(win.image_rnd+1)],1,win.exp_trials);
win.ttype         = reshape([ttype(win.image_rnd);ttype(win.image_rnd+1)],1,win.exp_trials);
win.pairOrder     = repmat([1,2],1,win.exp_trials/2);
nBlocks           = win.exp_trials./win.t_perblock;                       % # experimental block without counting the first test one
nTrials           = win.exp_trials+nBlocks;                       % Total # of trial
win.block_start   = repmat([1,zeros(1,win.t_perblock)],1,nBlocks);
win.image         = reshape([repmat({''},1,nBlocks);reshape(win.image,win.t_perblock,nBlocks)],1,[]);
win.ttype         = reshape([nan(1,nBlocks);reshape(win.ttype,win.t_perblock,nBlocks)],1,[]);
win.pairOrder     = reshape([nan(1,nBlocks);reshape(win.pairOrder,win.t_perblock,nBlocks)],1,[]);

%%
% old stuff for old stimuli
% there is four groups images total 256, in foldes images/ 7 8 26 27
% folders = [repmat(7,1,64),repmat(8,1,64),repmat(26,1,64),repmat(27,1,64)];
% images  = repmat(1:64,1,4);
% there is fivegroups of images total 53, in foldes images/ 
% 28 (butteflies,9) 29 (faces,11) 30 (houses,11) 31 (scrambled faces, 11)
% 32 (scrambled houses, 11), 33 (inverted faces, 11), 34 (inverted houses, 11)
%
% Pilot Task Nov-2017
% Images presentend in pair 6s-1s-6s
% Same or different?
%
% Randomization :
% same-whithin normal  10 faces and 10 house trial (20 diff images,40 images)
% different-within normal, 5 faces 5 house trial (20 diff images,total 20)
% different-between normal, 10 mis trial (20 diff images, total 20)

%folders = [repmat(8,1,47),repmat(28,1,9),repmat(29,1,11),repmat(30,1,11),repmat(31,1,11),repmat(32,1,11)];
%images  = [1:47,1:9,1:11,1:11,1:11,1:11];

% folderFace  = repmat(29,1,10);
% folderHouse = repmat(30,1,10);
% images      = 1:10;
% 
% withinFolder  = [repmat(folderFace,1,2),repmat(folderHouse,1,2)];
% betweenFolder = reshape([[folderFace(1:5);folderHouse(1:5)],[folderHouse(1:5);folderFace(1:5)]],1,length(folderFace)+length(folderHouse));
% SwithinImage  = [reshape(repmat(images,2,1),1,length(images)*2),reshape(repmat(images,2,1),1,length(images)*2)];
% DwithinImage  = [randsample(images,length(images)),randsample(images,length(images))];
% DbetweenImage = reshape([randsample(images,length(images));randsample(images,length(images))],1,length(images)*2);
% images        = [SwithinImage,DwithinImage,DbetweenImage];
% folders       = [withinFolder,withinFolder(1:2:end),betweenFolder];
% ttype         = [ones(1,length(SwithinImage)),2.*ones(1,length(DwithinImage)),3.*ones(1,length(DbetweenImage))];                                             % 1 - SW 2 - DW 3 - DB 
% 
% win.image_rnd     = randsample(1:2:win.exp_trials,win.exp_trials/2);
% win.image         = reshape([images(win.image_rnd);images(win.image_rnd+1)],1,win.exp_trials);
% win.im_folder     = reshape([folders(win.image_rnd);folders(win.image_rnd+1)],1,win.exp_trials);
% win.ttype         = reshape([ttype(win.image_rnd);ttype(win.image_rnd+1)],1,win.exp_trials);
% win.pairOrder     = repmat([1,2],1,win.exp_trials/2);
% nBlocks           = win.exp_trials./win.t_perblock;                       % # experimental block without counting the first test one
% nTrials           = win.exp_trials+nBlocks;                       % Total # of trial
% win.block_start   = repmat([1,zeros(1,win.t_perblock)],1,nBlocks);
% win.image         = reshape([nan(1,nBlocks);reshape(win.image,win.t_perblock,nBlocks)],1,[]);
% win.im_folder     = reshape([nan(1,nBlocks);reshape(win.im_folder,win.t_perblock,nBlocks)],1,[]);
% win.ttype         = reshape([nan(1,nBlocks);reshape(win.ttype,win.t_perblock,nBlocks)],1,[]);
% win.pairOrder     = reshape([nan(1,nBlocks);reshape(win.pairOrder,win.t_perblock,nBlocks)],1,[]);
% 
% %win.image_rnd     = reshape([nan(1,nBlocks);reshape(win.image_rnd,win.t_perblock,nBlocks)],1,[]);
