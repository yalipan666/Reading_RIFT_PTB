%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reading Experiment with Rapid Tagging frequency
% 10/08/2018 Yai Pan
% Press Q (quit) to exit exp
% Press C (continue) to skip eyechecker during start/end box
% Press E (eyelink) to start eyelink setup, calibration or/and validation
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initials: first block normal, second block add 2

% % % Reading_Exp_v9 19/11/2018 
% % % 1. 145cm visual distance, 22 textsize

% % % 2. End box in the lower center 
% % % 3. 13 points in eye-link calibration
% % % 4. Probe questions ending in ? mark
% % % 5.Shorter end box fixation duration
% % % Reading_Exp_v10 23/11/2018
% % % 1. correct the End box in the lower center
% % % 2. seperate 2 blocks
% % % 3. 5 points in eye-link calibration
% % % 4. make sure Probe questions ending in ? mark
% % % Reading_Exp_v11 28/02/2019
% % % 1. NOT seperate 2 blocks, but adding rest screen
% % % 2. fixation baseline period (make sure no power bias during baseline)
% % % 3. adding parameter to show the eye-position on PTB screen or not
% % % Exp_Reading_v12 04/04/2019
% % % 1. 2 tagging methods: single band/ broad band
% % % 2. adding guassian smooth to the edges of the small flicking
% background of the target word and parafoveal word

function Exp_Reading_v15
%%% frequency tagging parameters, %%%1--single band;  2---broadband

f1 = 60;
f2 = 0;

close all;
Screen('CloseAll');

tic
%%======= double check parameters before MEG =======%%
cfg.debugmode =0;                % runnning on local computer.for rapidmode testing without triggers
cfg.CheckEyeMyself = 0;  %%%   
if cfg.debugmode
    Screen('Preference', 'SkipSyncTests', 1); %must be 0 during experiment
    cfg.el.eyelink =0;              %eyelink on/off
    cfg.el.override = 1;          %No eyelink in actual experiment, use only in case of fault
    cfg.DataPixxOnly = 1;      %for rapidmode testing without triggers with propixx
    tt = 0.01;
else
    Screen('Preference', 'SkipSyncTests', 0); %must be 0 during experiment
    cfg.el.eyelink = 1;              %eyelink on/off
    cfg.el.override = 0 ;         %No eyelink in actual experiment, use only in case of fault
    cfg.DataPixxOnly = 1;      %for rapidmode testing without triggers with propixx
    tt = 1;
end

% Input dialog
prompt = {'Subject code:', ...
    'Subject Number:', ...
    'Screen width (cm): ', ...
    'Screen height (cm): ', ...
    'Screen distance (cm): '};
dlg_title = 'Input';
num_lines = 1;
defaultans = {'A','2','70.6','39.5','145'};
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
cfg.SubCode = answer{1};
cfg.SubID = str2double(answer{2});


%% initializing logfile, need to change the filename
exp_dir = fileparts(mfilename('fullpath'));
resultsDir = fullfile(exp_dir, 'Data');
% create results dir if it does not exist
if (~exist(resultsDir,'dir'))
    mkdir(resultsDir);
end
%%%%%
expdate_all = clock;
expdate = [num2str(expdate_all(1)) '_' num2str(expdate_all(2)) '_' num2str(expdate_all(3)) '_' ];
datafilename = [resultsDir filesep expdate 'Exp_Reading' '_' cfg.SubCode '.mat'];
if exist(datafilename,'file')
    error('The data file exists! Please enter a different subject name.');
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%================== Parameters initialization ==================%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Physical screen parameters (cm) (input)
cfg.width=str2double(answer{3});   %projection screen width in cm
cfg.height=str2double(answer{4});  %projection screen height in cm
cfg.dist=str2double(answer{5});    %distance from subject eye to screen in cm

%%%%%%%%%%%%%%%%%=================PTB screen Initialization======================%%%%%%%%%%%%%%%%%%%%%
AssertOpenGL;
PsychDefaultSetup(2);    % call some default settings for setting up Psychtoolbox
%ListenChar(2);
%Open screen
screens = Screen('Screens'); % Get the screen numbers
cfg.screenNumber = max(screens); %select screen
cfg.ScrBgc = [0.5 0.5 0.5];
%%%  Get the size of the on screen window and set resolution
sc_info = Screen('Resolution', cfg.screenNumber);
resx = sc_info.width;
resy = sc_info.height;
cfg.resx = resx;
cfg.resy = resy;
% initializing keyboard setting
KbName('UnifyKeyNames'); % for easy use of Keyboard keys
escKey = KbName('Q');
%%% KEY response in debugmode
leftKey = KbName('F'); %% same
rightKey = KbName('J'); %% different

%%%%%%%%%%%%%%%%%%%%%%%%================EyeLink settings====================%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cfg.el.Eyeused = 'LEFT_EYE';      %eye used
cfg.el.edffile = [cfg.SubCode '.edf']; %EDF filename
cfg.el.eyelinkKey = KbName('E');  %Key used to toggle eyelink validation/calculation on or off during experiment.
cfg.el.continueKey = KbName('C'); %skip eye check part in start/end box, inorder to continue exp

%%%%%%=====Eyelink Initialization
if cfg.el.eyelink
    %add eyelink script folder (should be in main experiment folder)
    addpath([exp_dir filesep 'Eyelink']);
    %make directory if it doesn't already exist (local computer)
    cfg.el.eyedir = [exp_dir filesep 'Eyelink' filesep ];
    if ~exist(cfg.el.eyedir, 'dir')
        mkdir(cfg.el.eyedir);
    end
    %check whether files already exist for this subject/session
    if exist([exp_dir filesep 'Eyelink' filesep 'Data' filesep  cfg.el.edffile '.edf'],'file')>0
        cont = input('Warning! Eyelink file will be overwritten, do you want to continue? (y/n) ','s');
        if cont == 'n'
            error('Session aborted')
        end
    end
    cfg.el_rect = [0 0 resx resy]; %% needed for the el_Set_Params function
    % Set parameters, start and calibrate eyelink
    
else %=% when eyelink is off
    if ~cfg.debugmode %is this is real experiment time, eyelink should be on
        if cfg.el.override
            warning('Eyelink not in use, continuing anyway...')
        else
            error('Eyelink not selected!')
        end
    end
end

%%%%%%%%============= open PTB window
[window] = PsychImaging('OpenWindow', cfg.screenNumber, cfg.ScrBgc);
cfg.window = window;
%%% for the rapid drawing in the offscreen window
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'UseFastOffscreenWindows');

% Query the maximum priority level
topPriorityLevel = MaxPriority(window);
if ~cfg.debugmode && ~cfg.CheckEyeMyself
    HideCursor;
    Priority(topPriorityLevel);
end

% enable alpha blending, also required for using offscreen window
Screen(window,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
% Flip to clear
Screen('Flip', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);
Para.ifi = ifi;

%%%%%%%%%%%%%%%%%%%%%%%%=================Stimuli settings=================%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%screen setup
cfg.WordSpace = 0.35; %0.33; %% unit in visual angle, equal space between each word;
WordSpace = usrDeg2Pix(cfg.WordSpace,cfg);
cfg.WordStart = 4*cfg.WordSpace;%6*cfg.WordSpace; %% unit in visual angle, the start point of sentence
WordStart = usrDeg2Pix(cfg.WordStart,cfg);
cfg.TextStyle = 1;                  %0=normal,1=bold,2=italic,4=underline,8=outline,32=condense,64=extend.
cfg.TextFont = 'Courier New';
cfg.TextSize = 22;%22; %22--0.3556 visdeg -> 12.3pix; 24--0.3951
cfg.TextColor = [0 0 0];


% %Timing
cfg.fix_t = tt*1.2;        %Duration (s) of the fixation
cfg.fix_jitter = tt*0.4;   %Baseline jitter. fixation duration is fix_t+jitter*[0..1]
cfg.iti = tt*0.5;          %intertrial interval
cfg.rest = tt*60; %% rest time between blocks
cfg.puretag = tt*12;
cfg.EyeTime = tt*30;
cfg.fedbk = tt*1;
%%%%%%====== fixation cross
% Set size of the arms and linewidth
fixCrossDimPix = 15;
lineWidthPix = 4;
% get coordinates
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
CrossCoords = [xCoords; yCoords];

%%%%%%====== Stimulus matrix
% % %generage the sentences
% % [~,SentMat_raw] = xlsread('Sentences');
% % [TarWodLocFreq] = xlsread('TargetWordLocation&Freq');
% % [~,ProbeMat] = xlsread('ProbeQuestions');
% % Question_all = cell(size(SentMat_raw,1),2); %% [question answer]
% % Question_all(2:end,1) = ProbeMat(:,1);
% % Question_all(2:end,2) = ProbeMat(:,end);
% % 
% % % % % % % % % % randid = randperm(size(SentMat_raw,1));
% % SentMat = SentMat_raw(randid,:);
% % TarWodLocFreq = TarWodLocFreq(randid,:);
% % Question_all = Question_all(randid,:);
% % save SentMat SentMat
% % save TarWodLocFreq TarWodLocFreq
% % save randid randid
% % save Question_all Question_all

% %%% new sentences
% [TarWodLocFreq] = xlsread('TargetWordLocation&Freq');
% load randid_new
% TarWodLocFreq = TarWodLocFreq(randid,:);
% save TarWodLocFreq TarWodLocFreq


%get the sentences
% load SentMat_1 %% SentMat
% load TarWodLocFreq %% TarWodLocFreq
% load Question_all
load SentMat_2 %% SentMat
load TarWodLocFreq_2 %% TarWodLocFreq
load Question_all_2

% parameteres for the reading paradigm
NumSent = size(SentMat,1);   %% number of sentences in the whole sheet1
FlkWords = [TarWodLocFreq(:,1) TarWodLocFreq(:,1)+1]; %% location of the tagging word1
Para.SentMat = SentMat;
Para.FlkWords = FlkWords;
Para.TarWodLocFreq = TarWodLocFreq;

% condition matrix
CondMat = TarWodLocFreq; %%[location frequency(1--low, 2--high)]
%save in cfg
Para.CondMat = CondMat;
%total nr of trials per block
nTrials = size(CondMat,1);
Para.nTrials = nTrials;
Para.BreakTrials = round(nTrials/4);             %How many trials between breaks?

%Calculate the stimulus centers
xPos=resx/4;
yPos=resy/4;
pos_1 = round([xPos yPos]); % left upper
pos_2 = round([3*(xPos) yPos]); % right-upper
pos_3 = round([xPos 3*(yPos)]); % left-lower
pos_4 = round([3*(xPos) 3*(yPos)]); % right-lower
qcenters =[pos_1 ; pos_2 ; pos_3 ; pos_4]; % centers for each quandrant

%%%% shift projector screen to the center
cfg.FixationsShift=0;           %Upward shift of screen center, to allow more space below fixation, in percent (0-100)
q_upshift_pix=round(yPos*(cfg.FixationsShift*1e-2));
% nm_upshift_pix=round((resy/2)*(cfg.FixationsShift*1e-2)); %shift of quadrant center in pixels
%apply screen center shift
qcenters(:,2)=qcenters(:,2)-q_upshift_pix;

%for every quandrant, calculate rects (useful for text placement)
q_rects(1,:)=[0 0 qcenters(1,:)*2];
q_rects(2,:)=[resx/2 0 resx qcenters(2,2)*2];
q_rects(3,:)=[0 resy/2 resx/2 resy-q_upshift_pix*2];
q_rects(4,:)=[resx/2 resy/2 resx resy-q_upshift_pix*2];

%%%% define the eyelink monitor windows
%Parameters for fixation control, note conversion to pixels does not
%take into account rapidmode, because eyelink knows only projected screen
cfg.gaze_start = 0.2;  %% duration of gaze within start box before sentence onset
cfg.gaze_end = 0.1; %% duration of gaze within end box
cfg.box_r_el = 1; % actual visual degree for eye-link to monitor %% RADIUS of start and end box of sentences
dot_center_ptb = usrDeg2Pix((cfg.box_r_el+cfg.WordSpace), cfg);
cfg.dot_r_ptb = 0.2*cfg.box_r_el; % small visual degree for ptb to present
dot_r = usrDeg2Pix(cfg.dot_r_ptb, cfg); %% radius, unit in pixel, in small rapid mode
%%%  dot coords for ptb to present
coords_dot = [0 0 2*dot_r 2*dot_r];
DotCoords_start = zeros(4,4);
DotCoords_end = zeros(4,4);
for q = 1:4
    DotCoords_start(q,:) = floor(CenterRectOnPointd(coords_dot, q_rects(q,1)+dot_center_ptb, qcenters(q,2)));
    DotCoords_end(q,:) = floor(CenterRectOnPointd(coords_dot,qcenters(q,1), q_rects(q,4)-2*dot_center_ptb)); % bottom vertical end box
end
%%% box coords for eyelink monitor window, in big normal window not small rapidmode window
box_r_el = round(((tand(cfg.box_r_el)*cfg.dist)*(resy/cfg.height))); %% convert degree to pix
box_center_ptb = round(((tand(cfg.box_r_el+cfg.WordSpace)*cfg.dist)*(resy/cfg.height)));
cfg.el.startWindow = [0 0 2*box_r_el 2*box_r_el];
cfg.el.startWindow = floor(CenterRectOnPointd(cfg.el.startWindow,box_center_ptb,resy/2)); %% starting box small window
cfg.el.endWindow = floor(CenterRectOnPointd(cfg.el.startWindow,resx/2,resy-2*box_center_ptb)); %% starting box small window
endbox_color = [0.25 0.25 0.25];

%%%%%%%%%%%%%%================Initalise Labjack / buttonbox settings===============%%%%%%%%%%%%%%%%%%%%%
% % if ~cfg.debugmode
% %     % Make the UD .NET assembly visible in MATLAB.
% %     bBox.ljasm = NET.addAssembly('LJUDDotNet');
% %     bBox.ljudObj = LabJack.LabJackUD.LJUD;
% %     % Open the first found LabJack U3.
% %     [bBox.ljerror, bBox.ljhandle] = bBox.ljudObj.OpenLabJackS('LJ_dtU3', 'LJ_ctUSB', '0', true, 0);
% %
% %     % Start by using the pin_configuration_reset IOType so that all pin
% %     % assignments are in the factory default condition.
% %     bBox.ljudObj.ePutS(bBox.ljhandle, 'LJ_ioPIN_CONFIGURATION_RESET', 0, 0, 0);
% %     cfg.bBox=bBox;
% %     cfg.bBox.keyLeft=16; %to init
% %     cfg.bBox.keyRight=17;
% % %     if mod(str2double(answer{1}),2) % key-press counterbalance over subjects
% % %         cfg.bBox.ActiveKeys=[cfg.bBox.keyLeft];
% % %     else
% % %         cfg.bBox.ActiveKeys=[cfg.bBox.keyRight];
% %      cfg.bBox.ActiveKeys=[cfg.bBox.keyRight]; %%!!! using right pad
% % %     end
% % end 
if ~cfg.debugmode
    %%%%% NAta Setting up
    if mod(cfg.SubID,2) %%% odd/single number
        cfg.keyLeft = KbName('4$'); %% same
        cfg.keyRight = KbName('7&'); %% different
    else  %%% even number
        cfg.keyLeft = KbName('7&'); %% same
        cfg.keyRight = KbName('4$'); %% different
    end
    active=[cfg.keyLeft cfg.keyRight]; %These are the left and right index fingers of the (5-button) NATA boxes
    keylist=zeros(1,256); %Set all keys to zero (ignore)
    keylist(active)=1; %set active keys to 1 (listen)
    KbQueueCreate(0,keylist);%%Create queue, this is a time consuming operation (relatively), do while non-time critical
    KbQueueStart(); %Start listening
    KbQueueFlush();
end

%%%%%%%%%%%%%%%%%==================Parallel Port IO & triggers settings===============%%%%%%%%%%%%%%%%%%%%%
% set up triggers
cfg.TriggerFix = 1;   % fixation onset
cfg.TriggerStartBox = 2; %% start box onset
cfg.TriggerSentOn = 4;    % %%% sentence onset
cfg.TriggerSentOff = 8;    % %%% sentence offset
cfg.TriggerITI = 16;   % ITI onset
cfg.TriggerOpenEye = 64;   
cfg.TriggerCloseEye = 128;  
cfg.TriggerPureTagOn = 32;   % tagging on in the pure tagging task

% set up parallel port
if ~cfg.debugmode
    %declare global variables because we want to use them in a external subfunction
    PortAddress = hex2dec('BFF8');
    ioObjTrig = io64;
    status = io64(ioObjTrig);
    io64(ioObjTrig,PortAddress,0); %trigger 0 (reset)
    cfg.PortAddress = PortAddress;
    cfg.ioObjTrig = ioObjTrig;
end

%%%%%%%%%%%%%%%%%=================Frequency Tagging Timecourse======================%%%%%%%%%%%%%%%%%%%%%
% if mod(str2double(answer{2}),2) % frequency counterbalance over subjects
cfg.FreqMat = [f1 f2];
% else
%     cfg.FreqMat = circshift([f1 f2],[0 1]);
% end
Para.FreqMat = cfg.FreqMat;
cfg.WaveShape = 'sin';            %Shape of the waveform 'sin' for sinusoidal, 'square' for square wave
cfg.Phaselock = 1;                %1=Phase locked RFT, same phase RFT stimulation for every trial; 0=random phase
cfg.FreqBins = 8;                %Nr of frequency bins with non-phase locked RFT

%%%%%%%%=====photoDiode settings
cfg.diodeFreq = 1;               %Frequency to present to photodiode? 1=f1, 2=f2, depending on conf
cfg.photoDiode = 1;              %Add corner stimulus for photodiode? --- the right bottom one
cfg.diodeSize = 2;               %Size of the photodiode in cm

%Get the placement of the photoDiode
if cfg.photoDiode
    %calculate size of photodiode in pixels
    diode_size_pix=round(0.5*(resy/cfg.height)*cfg.diodeSize);
    %calculate diode positions -- right bottom one
    diode1_pos{1}=[resx/2-diode_size_pix resy/2-diode_size_pix resx/2 resy/2];
    diode1_pos{2}=[resx-diode_size_pix resy/2-diode_size_pix resx resy/2];
    diode1_pos{3}=[resx/2-diode_size_pix resy-diode_size_pix resx/2 resy];
    diode1_pos{4}=[resx-diode_size_pix resy-diode_size_pix resx resy];
    
    %calculate diode positions -- left bottom one
    diode2_pos{1}=[0 resy/2-diode_size_pix diode_size_pix resy/2];
    diode2_pos{2}=[resx/2 resy/2-diode_size_pix resx/2+diode_size_pix resy/2];
    diode2_pos{3}=[0 resy-diode_size_pix diode_size_pix resy];
    diode2_pos{4}=[resx/2 resy-diode_size_pix resx/2+diode_size_pix resy];
end

% create photoDiode
imageSize = [379 379];
ci = [199, 199, 199];     % center and radius of circle ([c_row, c_col, r])
[xx,yy] = ndgrid((1:imageSize(1))-ci(1),(1:imageSize(2))-ci(2));
mask_alpha = uint8((xx.^2 + yy.^2)<ci(3)^2);
mask_alpha(mask_alpha==1)=255;  % Alpha layer: center is 255, surrounding is 0
if cfg.photoDiode
    diode=uint8(ones(size(mask_alpha))*255);
    diode(:,:,2)=mask_alpha;
    diode_tex = Screen('MakeTexture', window, diode);
end


% calculate the amount of frames needed for each part of the experiment.
%Get the maximal amount of frames to calculate the timecourse for
max_trialframes = 1000*round((cfg.fix_t+cfg.fix_jitter)/ifi);%max frames per trial

%Here we define the phase timecourse of the frequencies. To enable trial
%averaging in the time domain, phase will be 0 at t=0 (zeroframe), stimulus (figure)
%onset
frame_mult=12; %every refresh is 12 frames

%Effective presentation frequency. Should be 1440 for propixx
Fs=(1/ifi)*frame_mult;
cfg.Fs=Fs;
disp(['Effective refresh rate: ' num2str(Fs,6) 'Hz']);

if sum(cfg.FreqMat>Fs/2)>0
    warning('Presentation rate too low for the chosen flicker frequencies!')
end

%Frequency timecourse parameters
cfg.patch_amplitude = 0.5;
cfg.patch_startPhase = 0;
cfg.f_offset = 0;

%initialize the table
if cfg.Phaselock
    freqTable=NaN(length(cfg.FreqMat),(max_trialframes*frame_mult));
else
    freqTable=NaN(length(cfg.FreqMat),cfg.FreqBins,(max_trialframes*frame_mult));
end

for f = 1:length(cfg.FreqMat)
    patch_frequency = cfg.FreqMat(f);
    patch_angFreq = 2 * pi * patch_frequency;
    start_time=(cfg.fix_t+cfg.fix_jitter)*-1;
    frametime=start_time:ifi/frame_mult:(max_trialframes*frame_mult)*(ifi/frame_mult)+start_time;
    frametime=frametime(1:max_trialframes*frame_mult);
    if cfg.Phaselock
        if strcmpi(cfg.WaveShape,'square') %square wave
            freqTable(f,:)= cfg.patch_amplitude * square(patch_angFreq * frametime + cfg.patch_startPhase) + cfg.patch_amplitude + cfg.f_offset;
        else %sinusoidal
            freqTable(f,:)= cfg.patch_amplitude * sin(patch_angFreq * frametime + cfg.patch_startPhase) + cfg.patch_amplitude + cfg.f_offset;
        end
    else
        for b=1:cfg.FreqBins
            cfg.patch_startPhase =(2*pi/cfg.FreqBins)*(b-1);
            if strcmpi(cfg.WaveShape,'square') %square wave
                freqTable(f,b,:)= cfg.patch_amplitude * square(patch_angFreq * frametime + cfg.patch_startPhase) + cfg.patch_amplitude + cfg.f_offset;
            else %sinusoidal
                freqTable(f,b,:)= cfg.patch_amplitude * sin(patch_angFreq * frametime + cfg.patch_startPhase) + cfg.patch_amplitude + cfg.f_offset;
            end
        end
    end
end
cfg.freqTable=freqTable;
% % % % %% check the frequency table
% % % % zerotm = 973;
% % % % ttt = zerotm:zerotm+200;
% % % % figure;
% % % % dddatat = freqTable;
% % % % ddtime = frametime;
% % % % plot(ddtime(ttt),dddatat(1,ttt),'r','LineWidth',2); hold on;
% % % % plot(ddtime(ttt),dddatat(2,ttt),'b','LineWidth',2);
% % % % legend('Freq 65','Freq 72')

cfg.diodeTable1=freqTable(dsearchn(cfg.FreqMat',f1),:);
cfg.diodeTable2=freqTable(dsearchn(cfg.FreqMat',f2),:);

% if cfg.photoDiode
%     if cfg.Phaselock
%         switch cfg.diodeFreq
%             case 1
%                 cfg.diodeTable=freqTable(dsearchn(cfg.FreqMat',f1),:);
%             case 2
%                 cfg.diodeTable=freqTable(dsearchn(cfg.FreqMat',f2),:);
%         end
%     end
% end

%calculate all permutation of phase differences. It is important to balance
%the phase differences well to properly cancel out phase interference
tmp=[];
combs=[];
intervals=[1:cfg.FreqBins]-1;
for i=1:cfg.FreqBins
    tmp(:,1)=[1:cfg.FreqBins]';
    tmp(:,2)=mod(intervals+(i-1),cfg.FreqBins)+1; 
    combs=[combs ; tmp];
end
cfg.combs=combs;

if ~cfg.Phaselock
    %randomize phase table for trials
    reps=nTrials/length(combs);
    if mod(nTrials/(length(combs)),1)>0
        warning(['Nr of frequency bins (' int2str(cfg.FreqBins) ') does not fit into an integer nr of trials (' int2str(nTrials) ')'])
    end
    combsMat=repmat(combs,reps,1);
    cfg.combsMat=combsMat(randperm(size(combsMat,1)),:);
end

%%%%%%%%%%%%%%%%%=================Propixx initialization======================%%%%%%%%%%%%%%%%%%%%%
% Setup Propixx 1440 Hz
if  ~cfg.debugmode || cfg.DataPixxOnly
    Datapixx('Open');
    Datapixx('SetPropixxDlpSequenceProgram', 5); % 2 for 480, 5 for 1440 Hz, 0 for normal
    Datapixx('RegWrRd');
end

%%%%%%%%%%%%%%%%%================= output setting ======================%%%%%%%%%%%%%%%%%%%%%
Result.FixationON = nan(nTrials,1);
Result.StartBoxON = nan(nTrials,1);
Result.SentenceON = nan(nTrials,1);
Result.ITION = nan(nTrials,1);
Result.ProbeON = nan(nTrials,1);
Result.PureTagON = nan(nTrials,1);
Result.RT = nan(nTrials,1);
Result.CORR = nan(nTrials,1);
Result.KeyPress = cell(nTrials,1);
Result.WordLocation = zeros(NumSent,size(SentMat,2),4); %[x-start, x-end, y-start y-end] unit in pixel of the small rapid window
Result.EYEdata = cell(size(SentMat,1),1);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%===================== EXPERIMENTAL LOOP =======================%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% introduction#
KbReleaseWait;  %%%  make sure no key unreleased in debug
%welcome screen at first trial
for q = 1 :4
    %for some weird ass reason, this only works with supressed output arguments [~,~,~]
    [~,~,~] = DrawFormattedText(window, 'Press  Any  Key  To  START !', 'center', 'center',cfg.TextColor,[],[],[],[],[],q_rects(q,:));
end
vbl = Screen('Flip', window);
KbWait; %% waiting for key pressing
WaitSecs(1);

%%%%%%%%%%%%%================ Eye link: calibration + validation ===============%%%%%%%%%%%%%%%%%
%%%%% testing eyetracker
if cfg.el.eyelink
    cfg = el_calib_valid(cfg,0); % get the cfg.el.defaults settings
end

if cfg.el.eyelink
% %     Experiment start message to eyelink
    Eyelink('Message', ['SubId_' int2str(cfg.SubID) ' start']);
end

%%%% no trigger sent yet
cfg.triggerSent=0;

%%%%%%%%%%%%%%================  trial loops  ===============%%%%%%%%%%%%%%%%%
for i = 1:nTrials
    EYEdata = []; % recording eye data for each trial
    % set up Text parameters
    Screen('TextFont', window, cfg.TextFont);
    Screen('TextSize', window, cfg.TextSize);
    Screen('TextStyle',window, cfg.TextStyle);
    
    %%%=== define frames for each trial
    Para.FixDuration(i,1) = cfg.fix_t + cfg.fix_jitter*rand;
    fixendframes = round(Para.FixDuration(i,1)/ifi);
    
    %%%set frequency table
    if cfg.Phaselock
        cur_freqTable=freqTable;
    else %randomize phase
        comb_sel=cfg.combsMat(i,:);
        bin1=comb_sel(1);
        bin2=comb_sel(2);
        cur_freqTable(1,:)=squeeze(freqTable(1,bin1,:))';
        cur_freqTable(2,:)=squeeze(freqTable(2,bin2,:))';
        switch cfg.diodeFreq
            case 1
                cfg.diodeTable=cur_freqTable(dsearchn(cfg.FreqMat',f1),:);
            case 2
                cfg.diodeTable=cur_freqTable(dsearchn(cfg.FreqMat',f2),:);
        end
    end
    
    
    %%%%%%======= do a final check of calibration using driftcorrection
    if (cfg.el.eyelink && mod(i,3)==1) || (cfg.el.eyelink && mod(i,Para.BreakTrials)==1)
        el_calib_valid(cfg,2); % run EyelinkDoDriftCorrection
    end
    Screen('Flip', window);
    WaitSecs(0.3)
    
    %%%%%%%%%%%%%%%%%%%% ============ 1. fixation ============ %%%%%%%%%%%%%%%%%%%%
    for j = 1:fixendframes
        for q = 1:4 %four quadrants draw fixation cross
            %%% draw photodiode
            colortmp_p1 = [cfg.diodeTable1((((j-1)*12)+q)), cfg.diodeTable1((((j-1)*12)+q+4)),  cfg.diodeTable1((((j-1)*12)+q+8))];
            colortmp_p2 = [cfg.diodeTable2((((j-1)*12)+q)), cfg.diodeTable2((((j-1)*12)+q+4)),  cfg.diodeTable2((((j-1)*12)+q+8))];
            if cfg.photoDiode
                Screen('DrawTexture', window, diode_tex,[],diode1_pos{q},0, [], 1, colortmp_p1);
                Screen('DrawTexture', window, diode_tex,[],diode2_pos{q},0, [], 1, colortmp_p2);
            end            
            Screen('DrawLines', window, CrossCoords, lineWidthPix, cfg.TextColor, qcenters(q,:), 2);
        end
        % Flip to the screen
        vbl = Screen('Flip', window);
        %%%=== send triggers
        if j == 1
            Result.FixationON(i,1) = vbl;
            cfg = sendTrigger(cfg,cfg.TriggerFix);
            %we want to reset the trigger 50ms after the last trigger
        end
        if cfg.triggerSent && GetSecs>(cfg.triggerTime+0.05) && ~cfg.debugmode
            io64(cfg.ioObjTrig,cfg.PortAddress,0);
            cfg.triggerSent=0;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%% ============ 2. start box ============ %%%%%%%%%%%%%%%%%%%%
    KbReleaseWait;  %%%  make sure no key unreleased in debug
    ppp = 1; %%% index to send trigger
    j = 1; %% index of the frames to change the frequency table in each frame
    fff = 1;
    while fff <= round(cfg.gaze_start/ifi)
        %%% draw start box
        for q = 1:4 %four quadrants draw fixation cross
            Screen('FillRect', window, cfg.TextColor, DotCoords_start(q,:));
            %%% draw photodiode
            colortmp_p1 = [cfg.diodeTable1((((j-1)*12)+q)), cfg.diodeTable1((((j-1)*12)+q+4)),  cfg.diodeTable1((((j-1)*12)+q+8))];
            colortmp_p2 = [cfg.diodeTable2((((j-1)*12)+q)), cfg.diodeTable2((((j-1)*12)+q+4)),  cfg.diodeTable2((((j-1)*12)+q+8))];
            if cfg.photoDiode
                Screen('DrawTexture', window, diode_tex,[],diode1_pos{q},0, [], 1, colortmp_p1);
                Screen('DrawTexture', window, diode_tex,[],diode2_pos{q},0, [], 1, colortmp_p2);
            end 
        end
        % Flip to the screen
        vbl = Screen('Flip', window);
        
        %%%=== send triggers
        if ppp == 1
            Result.StartBoxON(i,1) = vbl;
            cfg = sendTrigger(cfg,cfg.TriggerStartBox);
            ppp = 0;
        end
        %we want to reset the trigger 50ms after the last trigger
        if cfg.triggerSent && GetSecs>(cfg.triggerTime+0.05) && ~cfg.debugmode
            io64(cfg.ioObjTrig,cfg.PortAddress,0);
            cfg.triggerSent=0;
        end
        
        %check whether fixation is in the start box
        if cfg.el.eyelink
            sample = Eyelink('NewestFloatSample');
            % Get current gaze position from sample
            x = sample.gx(1); %first sample should be left eye
            y = sample.gy(1);
            %%% xxxx plot eyelink window
            if cfg.CheckEyeMyself
                % eyelink check window
                Screen('FrameRect', window, cfg.TextColor, cfg.el.startWindow./2);
                Screen('FrameRect', window, cfg.TextColor, cfg.el.endWindow./2);
                % xy position of eye
                Screen('FrameOval', window, [255 0 0], [x/2-8 y/2-8 x/2+8 y/2+8],3);
            end
            %%% compare x and y to start box window
            if sample.pa(1)>0
                inbox = (x > cfg.el.startWindow(1) &&  x <  cfg.el.startWindow(3) && y > cfg.el.startWindow(2) && y < cfg.el.startWindow(4));
                if inbox == 0
                    fff = 0;
                end
            else
              fff = 0;
            end
        else
            fff = 0;
        end
        
        %%%% check key press
        [ keyIsDown, ~, KeyCode ] = KbCheck;
        if keyIsDown && KeyCode(escKey)
            cleanup(cfg);
            break;
        end
        
        if keyIsDown && KeyCode(cfg.el.eyelinkKey)
            el_calib_valid(cfg,2)  %% do calibration and validation again
            fff = 0;
        end
        if keyIsDown && KeyCode(cfg.el.continueKey)
            fff =  round(cfg.gaze_start/ifi) + 10;
        end
        j = j + 1;
        fff = fff + 1;
    end
    
    %%%%%%%%%%%%%%%%%%%% ============ 3. sentence  ============ %%%%%%%%%%%%%%%%%%%%
    %%%%trial start
    if cfg.el.eyelink
        %send trial start trigger to eyelink
        Eyelink('Message', ['Sentence_ ' int2str(i) ' start' ]);
    end
    
    %%%DRAW STIMULI
    %%% get the sentence and its x-coordinate in this trial
    Words = SentMat(i,:); %% words in the present sentences
    for www = 1:length(Words)
        if strfind(Words{www},'.')
            break
        end
    end
    NumWord = www;
    TxtXcoord = zeros(1,NumWord); %% the x-coordinate of the first word
    WordWid = zeros(1,NumWord);
    WordHit = zeros(1,NumWord);
    for www = 1:NumWord
        textmp = Words{www};
        WordWid(www) = RectWidth(Screen('TextBounds',window,textmp));
        WordHit(www) = RectHeight(Screen('TextBounds',window,textmp));
        if www ~= 1
            TxtXcoord(www) = TxtXcoord(www-1)+WordWid(www-1)+WordSpace;
        end
    end
    TxtXcoord = TxtXcoord + WordStart;
    MostHeight = mode(WordHit);
    % Compute bounding box of textstring:
    TextureBox1 = q_rects(1,:);
    
    %%%%% draw sentence in the offscreen window
    %%all words in offscreen 1
    woff1 = Screen('OpenOffscreenwindow', window, [cfg.ScrBgc 0],TextureBox1);
    Screen('TextFont', woff1, cfg.TextFont);
    Screen('TextSize', woff1, cfg.TextSize);
    Screen('TextStyle',woff1, cfg.TextStyle);
    for www = 1:NumWord
        Screen('DrawText', woff1, Words{www},TxtXcoord(www),0.5*TextureBox1(4)+0.25*MostHeight,[1 1 1], [], 1);
    end
    %%gaussian mask of the small flickering patch underlying target word 1 in offscreen 2
% % bcgheight = max([round(TxtXcoord(FlkWords(i,1)+1)-TxtXcoord(FlkWords(i,1))) round(TxtXcoord(FlkWords(i,1)+1+1)-TxtXcoord(FlkWords(i,1)+1))]); 
    bcgheight = round(TxtXcoord(FlkWords(i,1)+1)-TxtXcoord(FlkWords(i,1)));    
    msy = round(bcgheight)/2;
    id_wrd = FlkWords(i,1);
    woff2 = Screen('OpenOffscreenwindow', window, [cfg.ScrBgc 0],TextureBox1);
    rectwidth = round(TxtXcoord(id_wrd+1)-TxtXcoord(id_wrd));
    rectheight = bcgheight;
    x_start = round(TxtXcoord(id_wrd)-0.5*WordSpace);
    y_start = round(0.5*TextureBox1(4)-rectheight/2);
    x_coords = [x_start (x_start+rectwidth)];
    y_coords = [y_start (y_start+rectheight)];
    Screen('FillRect', woff2,[1 1 1],[x_coords(1) y_coords(1) x_coords(end) y_coords(end)]);
    % We create a Luminance+Alpha matrix for use as transparency mask:
    % Layer 1 (Luminance) is filled with luminance value 'gray' of the background.
    ms = round(1.5*WordSpace + WordWid(id_wrd))/2;
    transLayer=2;
    %%%% square mask
    [x,y]=meshgrid(-ms:ms, -msy:msy);
    maskblob=uint8(ones(2*msy+1, 2*ms+1, transLayer) * 128);
    % Layer 2 (Transparency aka Alpha) is filled with gaussian transparency mask.
    xsd=ms/1.2; %bigger than 1.2, more concentrated blob, less smoothing area
    ysd=msy/1.2;
    maskblob(:,:,transLayer)=uint8(round(255 - exp(-((x/xsd).^2)-((y/ysd).^2))*255));
    % Build a single transparency mask texture in offscreen 3
    woff3 = Screen('MakeTexture', window, maskblob);
    wordcenter_x = (x_coords(1)+x_coords(end))/2;
    wordcenter_y = (y_coords(1)+y_coords(end))/2;
    rect4offscreen = [ wordcenter_x-ms  wordcenter_y-msy  wordcenter_x+ms  wordcenter_y+msy];
    
    %%gaussian mask of the small flicking background of word2 in offscreen4
    %%flicker words 2 in offscreen 3
    id_wrd = FlkWords(i,1)+1;
    woff4 = Screen('OpenOffscreenwindow', window, [cfg.ScrBgc 0],TextureBox1);
    rectwidth = round(TxtXcoord(id_wrd+1)-TxtXcoord(id_wrd));
    rectheight = bcgheight;
    x_start = round(TxtXcoord(id_wrd)-0.5*WordSpace);
    y_start = round(0.5*TextureBox1(4)-rectheight/2);
    x_coords = [x_start (x_start+rectwidth)];
    y_coords = [y_start (y_start+rectheight)];
    Screen('FillRect', woff4,[1 1 1],[x_coords(1) y_coords(1) x_coords(end) y_coords(end)]);
    % We create a Luminance+Alpha matrix for use as transparency mask:
    % Layer 1 (Luminance) is filled with luminance value 'gray' of the
    % background.
    ms = round(1.5*WordSpace + WordWid(id_wrd))/2;
    transLayer=2;
    %%%% square mask
    [x,y]=meshgrid(-ms:ms, -msy:msy);
    maskblob=uint8(ones(2*msy+1, 2*ms+1, transLayer) * 128);
    size(maskblob);
    % Layer 2 (Transparency aka Alpha) is filled with gaussian transparency
    % mask.
    xsd=ms/1.2;
    ysd=msy/1.2;
    maskblob(:,:,transLayer)=uint8(round(255 - exp(-((x/xsd).^2)-((y/ysd).^2))*255));
    % Build a single transparency mask texture
    woff5 = Screen('MakeTexture', window, maskblob);
    wordcenter_x = (x_coords(1)+x_coords(end))/2;
    wordcenter_y = (y_coords(1)+y_coords(end))/2;
    rect4offscreen2 = [wordcenter_x-ms  wordcenter_y-msy  wordcenter_x+ms  wordcenter_y+msy];
    
    %%% recording eye-movement coordinates
    Result.WordLocation(i,1:NumWord,1) = TxtXcoord; %% x-start
    Result.WordLocation(i,1:NumWord,3) = TxtXcoord+WordWid; %% x-end
    ys = 0.5*TextureBox1(4)-1.25.*MostHeight;
    ye = 0.5*TextureBox1(4)-.25.*MostHeight;
    Result.WordLocation(i,1:NumWord,2) = ys.*ones(1,NumWord);
    Result.WordLocation(i,1:NumWord,4) = ye.*ones(1,NumWord);
    
    %%%%%========= frames loops in each trial
    KbReleaseWait;  %%%  make sure no key unreleased in debugc
    ppp = 1; %%% index to send trigger
    j = 1; %% index of the frames to change the frequency table in each frame
    fff = 1;
    while fff <= round(cfg.gaze_end/ifi) %% word frames during one trial
        %%% put sentences onscreen
        for q = 1:4 %for all quadrants
            %%% flicking bkg of word1
            colortmp2 = [cur_freqTable(1,(((j-1)*12)+q)), cur_freqTable(1,(((j-1)*12)+q+4)),  cur_freqTable(1,(((j-1)*12)+q+8))];
            Screen('DrawTexture', window, woff2,[], q_rects(q,:),0, [], 1, colortmp2);
            Screen('DrawTexture', window, woff3,[], rect4offscreen+[q_rects(q,1) q_rects(q,2) q_rects(q,1) q_rects(q,2)]);
            %%% flicking bkg of word2
            colortmp3 = [cur_freqTable(2,(((j-1)*12)+q)), cur_freqTable(2,(((j-1)*12)+q+4)),  cur_freqTable(2,(((j-1)*12)+q+8))];
            Screen('DrawTexture', window, woff4,[], q_rects(q,:),0, [], 1, colortmp3);
            Screen('DrawTexture', window, woff5,[], rect4offscreen2+[q_rects(q,1) q_rects(q,2) q_rects(q,1) q_rects(q,2)]);
            %%% draw all words
            colortmp1 = cfg.TextColor;
            Screen('DrawTexture', window, woff1,[], q_rects(q,:),0, [], 1, colortmp1);
            
            %%% draw end box
            Screen('FillRect', window, endbox_color, DotCoords_end(q,:));
            %%% draw photodiode
            colortmp_p1 = [cfg.diodeTable1((((j-1)*12)+q)), cfg.diodeTable1((((j-1)*12)+q+4)),  cfg.diodeTable1((((j-1)*12)+q+8))];
            colortmp_p2 = [cfg.diodeTable2((((j-1)*12)+q)), cfg.diodeTable2((((j-1)*12)+q+4)),  cfg.diodeTable2((((j-1)*12)+q+8))];
            if cfg.photoDiode
                Screen('DrawTexture', window, diode_tex,[],diode1_pos{q},0, [], 1, colortmp_p1);
                Screen('DrawTexture', window, diode_tex,[],diode2_pos{q},0, [], 1, colortmp_p2);
            end
        end
        %%% flip the frame
        [vbl] = Screen('Flip', window, vbl + 0.5 * ifi);
        
        %%%=== send triggers
        if ppp == 1
            Result.SentenceON(i,1) = vbl;
            cfg = sendTrigger(cfg,cfg.TriggerSentOn);
            ppp = 0;
        end
        %we want to reset the trigger 50ms after the last trigger
        if cfg.triggerSent && GetSecs>(cfg.triggerTime+0.05) && ~cfg.debugmode
            io64(cfg.ioObjTrig,cfg.PortAddress,0);
            cfg.triggerSent=0;
        end
        
        %%% check end box fixation
        %We'll check eye position during the experiment, once per screen refresh (e.g. 120Hz)
        if cfg.el.eyelink %after initial period
            %Get eyelink sample
            sample = Eyelink('NewestFloatSample');
            % Get current gaze position from sample
            x = sample.gx(1); %first sample should be left eye
            y = sample.gy(1);
            EYEdata = [EYEdata; [x y]];
            
            %%% xxxx plot eyelink window
            if cfg.CheckEyeMyself
                 % eyelink check window
                Screen('FrameRect', window, cfg.TextColor, cfg.el.startWindow./2);
                Screen('FrameRect', window, cfg.TextColor, cfg.el.endWindow./2);
                % xy position of eye
                Screen('FrameOval', window, [255 0 0], [x/2-8 y/2-8 x/2+8 y/2+8],3);
            end
            
            %%%% compare x and y to fixation_end_window
            if sample.pa(1)>0
                inbox = x > cfg.el.endWindow(1) &&  x <  cfg.el.endWindow(3) && y > cfg.el.endWindow(2) && y < cfg.el.endWindow(4);
                if inbox == 0
                    fff = 0;
                end
            else
              fff = 0;
            end
        else
            fff = 0;
        end
        
        %CHECK RESPONSES
        [keyIsDown, ~, KeyCode] = KbCheck;
        if keyIsDown && KeyCode(escKey)
            cleanup(cfg);
            break;
        end
        %%%%check the eye-tracker key-press
        if keyIsDown && KeyCode(cfg.el.eyelinkKey)
            el_calib_valid(cfg,1)  %% do calibration and validation again
            fff = 0;
        end
        if keyIsDown && KeyCode(cfg.el.continueKey)
            fff = round(cfg.gaze_end/ifi)+10;
        end
        j = j + 1;
        fff = fff + 1;
    end
    %%% sentence off trigger
    cfg = sendTrigger(cfg,cfg.TriggerSentOff);
    if cfg.triggerSent && GetSecs>(cfg.triggerTime+0.05) && ~cfg.debugmode
        io64(cfg.ioObjTrig,cfg.PortAddress,0);
        cfg.triggerSent=0;
    end
    
    %%% close offscreens
    Screen('Close', woff1) 
    Screen('Close', woff2)
    Screen('Close', woff3)
    Screen('Close', woff4);
    Screen('Close', woff5);
  
    %%%%%%%%%%%%%%%%%%%% ============ 4. probe questions  ============ %%%%%%%%%%%%%%%%%%%%
    KbReleaseWait; 
    if ~cfg.debugmode
        KbQueueFlush();
    end
    probe = Question_all{i,1};
    if ~strcmp(probe,'') && ~isempty(probe)
        Screen('TextFont', window, cfg.TextFont);
        Screen('TextSize', window, cfg.TextSize);
        Screen('TextStyle',window, cfg.TextStyle);
        for q = 1 :4
            [~,~,~] = DrawFormattedText(window, probe,q_rects(q,1)+ WordStart, 'center' ,cfg.TextColor,[],[],[],[],[],q_rects(q,:));
        end
        [vbl] = Screen('Flip', window);
        Result.ProbeON(i,1) = vbl;
      
        %%% check the response
        noResponse=1;
        while noResponse
            if ~cfg.debugmode %% NaTA box
                [pressed, firstpress]=KbQueueCheck(); %check response, return whether pressed, and first press timestamp
                %Note that two keys may have been pressed
                KeyCode=find(firstpress);
                if length(KeyCode)>1 %two or more buttons pressed
                    [~,ind]=min(firstpress(KeyCode));
                    KeyCode = KeyCode(ind); %select first response
                end
                t_keypress=firstpress(KeyCode);
            else   %% keyboard 
                [pressed, t_keypress, KeyCode] = KbCheck;
            end
            if pressed
                if ~cfg.debugmode  %% NaTA box
                    if (strcmp(Question_all{i,2},'T') && KeyCode == cfg.keyLeft) || (strcmp(Question_all{i,2},'F') && KeyCode ==  cfg.keyRight)
                        Result.CORR(i) = 1;
                    else
                        Result.CORR(i) = 0;
                    end
                else  %% keyboard 
                    if (strcmp(Question_all{i,2},'T') && KeyCode(leftKey)) || (strcmp(Question_all{i,2},'F') && KeyCode(rightKey))
                        Result.CORR(i) = 1;
                    else
                        Result.CORR(i) = 0;
                    end
                    KbReleaseWait;
                end
                Result.RT(i,1) = t_keypress-vbl;
                Result.KeyPress{i,1} = KbName(KeyCode);
                noResponse=0;
            end
            WaitSecs(0.001);
        end
        
        %%%%%%%%%%%%%%%%%%%% ============ 5. feedback to the resposne  ============ %%%%%%%%%%%%%%%%%%%%
        if Result.CORR(i)
            message = 'Correct';
        else
            message = 'Wrong';
        end
        for q = 1 :4
            [~,~,~] = DrawFormattedText(window, message,q_rects(q,1)+ WordStart, 'center' ,cfg.TextColor,[],[],[],[],[],q_rects(q,:));
        end
        Screen('Flip', window);
        WaitSecs(cfg.fedbk);
    end
    
    %%%%%%%%%%%%%%%%%%%% ============ 6. blank screen  ============ %%%%%%%%%%%%%%%%%%%%
    vbl = Screen('Flip', window);
    Result.ITION(i,1) = vbl;
    if ~cfg.debugmode
        % sent trigger
        cfg = sendTrigger(cfg,cfg.TriggerITI);
        WaitSecs(0.05);
        io64(cfg.ioObjTrig,cfg.PortAddress,0);
        cfg.triggerSent=0;
    end
    WaitSecs(cfg.iti - 0.05);
    
    %%%%%%%%%%%%%%%%%%%% ============ 7. rest  ============ %%%%%%%%%%%%%%%%%%%%
    %ADD extra break after every so many trials
    if ~mod(i,Para.BreakTrials) && i ~= nTrials
        %%% have a rest
        for kkkk = 1:cfg.rest
          message=['Well done! \n\n Please close your eyes and take a Break \n\n\n\n ' num2str(cfg.rest-kkkk)];
          for q = 1:4
            [~,~,~]=DrawFormattedText(window, message, 'center', 'center',cfg.TextColor,[],[],[],2,[],q_rects(q,:));
          end
          Screen('Flip', window);
          WaitSecs(1);
        end
        
        %%% press any button to continue
        message='Please press the button when you are ready to continue';
        for q = 1:4
          [~,~,~]=DrawFormattedText(window, message, 'center', 'center',cfg.TextColor,[],[],[],2,[],q_rects(q,:));
        end
        Screen('Flip', window);
        %%% check button press
        if ~cfg.debugmode
          KbQueueFlush();
        end
        KbReleaseWait;
        noResponse = 1;
        while noResponse
          if ~cfg.debugmode
            [pressed]=KbQueueCheck(); %check response, return whether pressed, and first press timestamp
          else
            [pressed] = KbCheck;
          end
          if pressed
            noResponse = 0;
          end
        end
        %add empty screen
        Screen('Flip', window);
    end
    Result.EYEdata{i,1} = EYEdata;
    %%% saving data
    save(datafilename,'cfg','Para','Result');
end

%%% pure tagging task
% % % welcome screen at first trial
for q = 1 :4
    %for some weird ass reason, this only works with supressed output arguments [~,~,~]
    [~,~,~] = DrawFormattedText(window, 'Please fixate on the Y \n\n And count how many times the Y changes to X!', 'center', 'center',cfg.TextColor,[],[],[],[],[],q_rects(q,:));
end
vbl = Screen('Flip', window);
KbWait;
%%% get the sentence and its x-coordinate in this trial
TrgLoc = 6;
Words = {};
Words{1} = 'XXX';
Words{2} = 'XXXX';
Words{3} = 'XXXX';
Words{4} = 'XXXXX';
Words{5} = 'XXXX';
Words{6} = 'XXXYXXX';
Words{7} = 'XXXXX';
Words{8} = 'XXXX';
Words{9} = 'XXXXX';
Words{10} = 'XXXX';
Words{11} = 'XXXXX';
Words_change = Words;
Words_change{TrgLoc} = 'XXXXXXX'; %%% odd ball target
% NumWord = length(Words);
TxtXcoord = zeros(1,NumWord); %% the x-coordinate of the first word
WordWid = zeros(1,NumWord);
WordHit = zeros(1,NumWord);

for www = 1:NumWord
    textmp = Words{www};
    if ~isempty(textmp)
    WordWid(www) = RectWidth(Screen('TextBounds',window,textmp));
    WordHit(www) = RectHeight(Screen('TextBounds',window,textmp));
    if www ~= 1
        TxtXcoord(www) = TxtXcoord(www-1)+WordWid(www-1)+WordSpace;
    end
    end
end
TxtXcoord = TxtXcoord + WordStart;
MostHeight = mode(WordHit);

% Compute bounding box of textstring:
TextureBox1 = q_rects(1,:);
%%%%% draw sentence in the offscreen window
clear woff1 woff2 woff3
%% the small flicking background of words 1 in offscreen 2
bcgheight = round(TxtXcoord(TrgLoc+1)-TxtXcoord(TrgLoc));
msy = round(bcgheight)/2;
id_wrd = TrgLoc;
woff2 = Screen('OpenOffscreenwindow', window, [cfg.ScrBgc 0],TextureBox1);
rectwidth = round(TxtXcoord(id_wrd+1)-TxtXcoord(id_wrd));
rectheight = bcgheight;
x_start = round(TxtXcoord(id_wrd)-0.5*WordSpace);
y_start = round(0.5*TextureBox1(4)-rectheight/2);
x_coords = [x_start (x_start+rectwidth)];
y_coords = [y_start (y_start+rectheight)];
Screen('FillRect', woff2,[1 1 1],[x_coords(1) y_coords(1) x_coords(end) y_coords(end)]);
% Layer 1 (Luminance) is filled with luminance value 'gray' of the background.
ms = round(2*WordSpace + WordWid(id_wrd))/2;
transLayer=2;
%%%% square mask
[x,y]=meshgrid(-ms:ms, -msy:msy);
maskblob=uint8(ones(2*msy+1, 2*ms+1, transLayer) * 128);
size(maskblob);
% Layer 2 (Transparency aka Alpha) is filled with gaussian transparency mask.
xsd=ms/1.2;
ysd=msy/1.2;
maskblob(:,:,transLayer)=uint8(round(255 - exp(-((x/xsd).^2)-((y/ysd).^2))*255));
% Build a single transparency mask texture in offscreen 3
woff3 = Screen('MakeTexture', window, maskblob);
wordcenter_x = (x_coords(1)+x_coords(end))/2;
wordcenter_y = (y_coords(1)+y_coords(end))/2;
rect4offscreen = [ wordcenter_x-ms  wordcenter_y-msy  wordcenter_x+ms  wordcenter_y+msy];


%%all words in offscreen 1
woff1 = Screen('OpenOffscreenwindow', window, [cfg.ScrBgc 0],TextureBox1);
Screen('TextFont', woff1, cfg.TextFont);
Screen('TextSize', woff1, cfg.TextSize);
Screen('TextStyle',woff1, cfg.TextStyle);
for www = 1:NumWord
  Screen('DrawText', woff1, Words{www},TxtXcoord(www),0.5*TextureBox1(4)+0.25*MostHeight,[1 1 1], [], 1);
end
targettrail = [2,6,8,10,14,16,18,20];
changetrial = 0;
for ttt = 1:20
    ppp = 1; %%% index to send trigger
    %%%%%========= frames loops in each trial
    if ismember(ttt,targettrail)
        changetrial = 1;
    else
        changetrial = 0;
    end

    j = 1; %% index of the frames to change the frequency table in each frame
    while j <= round(cfg.puretag/ifi) %% word frames during one trial
        %%% put sentences onscreen
        for q = 1:4 %for all quadrants
          %%% draw photodiode
            colortmp_p1 = [cfg.diodeTable1((((j-1)*12)+q)), cfg.diodeTable1((((j-1)*12)+q+4)),  cfg.diodeTable1((((j-1)*12)+q+8))];
            colortmp_p2 = [cfg.diodeTable2((((j-1)*12)+q)), cfg.diodeTable2((((j-1)*12)+q+4)),  cfg.diodeTable2((((j-1)*12)+q+8))];
           
            if mod(ttt,2) == 1  %%% flicking bkg of word1
                colortmp2 = [cur_freqTable(1,(((j-1)*12)+q)), cur_freqTable(1,(((j-1)*12)+q+4)),  cur_freqTable(1,(((j-1)*12)+q+8))];
                if j == round(cfg.puretag/ifi)-2
                  colortmp2 = colortmp2 + (cfg.ScrBgc - colortmp2).*0.2;
                elseif j == round(cfg.puretag/ifi)-1
                  colortmp2 = colortmp2 + (cfg.ScrBgc - colortmp2).*0.6;
                  elseif j == round(cfg.puretag/ifi)
                  colortmp2 = colortmp2 + (cfg.ScrBgc - colortmp2).*0.9;
                end
                Screen('DrawTexture', window, woff2,[], q_rects(q,:),0, [], 1, colortmp2); %%% flickering
                Screen('DrawTexture', window, woff3,[], rect4offscreen+[q_rects(q,1) q_rects(q,2) q_rects(q,1) q_rects(q,2)]); %%% transparent mask
            end
            
            if (changetrial == 0 && j == 1) || (changetrial == 1 && j == 225)
                if exist('woff1', 'var')
                    Screen('Close', woff1)
                end
                %%all words in offscreen 1
                woff1 = Screen('OpenOffscreenwindow', window, [cfg.ScrBgc 0],TextureBox1);
                Screen('TextFont', woff1, cfg.TextFont);
                Screen('TextSize', woff1, cfg.TextSize);
                Screen('TextStyle',woff1, cfg.TextStyle);
                for www = 1:NumWord
                    Screen('DrawText', woff1, Words{www},TxtXcoord(www),0.5*TextureBox1(4)+0.25*MostHeight,[1 1 1], [], 1);
                end
            end
            if changetrial == 1 && j == 200 
                if exist('woff1', 'var')
                    Screen('Close', woff1)
                end
                %%all words in offscreen 1
                woff1 = Screen('OpenOffscreenwindow', window, [cfg.ScrBgc 0],TextureBox1);
                Screen('TextFont', woff1, cfg.TextFont);
                Screen('TextSize', woff1, cfg.TextSize);
                Screen('TextStyle',woff1, cfg.TextStyle);
                for www = 1:NumWord
                    Screen('DrawText', woff1, Words_change{www},TxtXcoord(www),0.5*TextureBox1(4)+0.25*MostHeight,[1 1 1], [], 1);
                end
            end
            
            %%%%  draw all the words
            colortmp1 = cfg.TextColor;
            Screen('DrawTexture', window, woff1,[], q_rects(q,:),0, [], 1, colortmp1);
            
             if cfg.photoDiode
                Screen('DrawTexture', window, diode_tex,[],diode1_pos{q},0, [], 1, colortmp_p1);
                Screen('DrawTexture', window, diode_tex,[],diode2_pos{q},0, [], 1, colortmp_p2);
            end
        end
        %%% flip the frame
        [vbl] = Screen('Flip', window, vbl + 0.5 * ifi);
        
        %%%=== send triggers
        if ppp == 1
            Result.PureTagON(i,1) = vbl;
            cfg = sendTrigger(cfg,cfg.TriggerPureTagOn);
            ppp = 0;
        end
        %we want to reset the trigger 50ms after the last trigger
        if cfg.triggerSent && GetSecs>(cfg.triggerTime+0.05) && ~cfg.debugmode
            io64(cfg.ioObjTrig,cfg.PortAddress,0);
            cfg.triggerSent=0;
        end
        j = j + 1;
    end
end
%%% close offscreens
Screen('Close', woff1)
Screen('Close', woff2)
Screen('Close', woff3)
  
% % End of block message
if i == nTrials
    %%% recording data of open eye
    for q = 1 :4
        %for some weird ass reason, this only works with supressed output arguments [~,~,~]
        [~,~,~] = DrawFormattedText(window, 'Please fixate on the cross for a while!', 'center', 'center',cfg.TextColor,[],[],[],[],[],q_rects(q,:));
    end
    Screen('Flip', window);
    KbWait; %% waiting for key pres
    %%% fixation onset
    for q = 1 :4
        Screen('DrawLines', window, CrossCoords, lineWidthPix, cfg.TextColor, qcenters(q,:), 2);
    end
    Screen('Flip', window);
    if ~cfg.debugmode
        % sent trigger
        cfg = sendTrigger(cfg,cfg.TriggerOpenEye);
        WaitSecs(0.05);
        io64(cfg.ioObjTrig,cfg.PortAddress,0);
        cfg.triggerSent=0;
    end
    WaitSecs(cfg.EyeTime - 0.05);
    
    %%% recording data of close eye
    for q = 1 :4
        %for some weird ass reason, this only works with supressed output arguments [~,~,~]
        [~,~,~] = DrawFormattedText(window, 'Please close your eyes for a while! \n\n I will tell you when to open your eyes', 'center', 'center',cfg.TextColor,[],[],[],[],[],q_rects(q,:));
    end
    Screen('Flip', window);
    KbWait; %% waiting for key pres
    if ~cfg.debugmode
      % sent trigger
      cfg = sendTrigger(cfg,cfg.TriggerCloseEye);
        WaitSecs(0.05);
        io64(cfg.ioObjTrig,cfg.PortAddress,0);
        cfg.triggerSent=0;
    end
    WaitSecs(cfg.EyeTime - 0.05);
end


%%% end of study
message = 'The End! \n\n Well done! \n\n  THANK YOU !!';
for q = 1 : 4
  [~,~,~]=DrawFormattedText(window, message, 'center', 'center',cfg.TextColor,[],[],[],2,[],q_rects(q,:));
end
Screen('Flip', window);
WaitSecs(3);
    

%stop eyelink & transfer file
if cfg.el.eyelink
    Eyelink('Message', 'end of block');
    el_Stop(cfg);
end

%return to lower priority
if ~cfg.debugmode
    Priority(0);
end
%ListenChar(0);
ShowCursor;
%set propixx to normal state
if ~cfg.debugmode || cfg  .DataPixxOnly
    Datapixx('SetPropixxDlpSequenceProgram', 0);
    Datapixx('RegWrRd');
    Datapixx('close');
end
toc
%Close screen
Screen('CloseAll');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% SubFunctions
% % % %Button box resonse (blocking)
% % % function [t,resp] = BbWait(cfg)
% % %
% % % % loop till broken from
% % % while true
% % %     for i=1:length(cfg.bBox.ActiveKeys) %cycle through active keys/buttons
% % %
% % %         cur=cfg.bBox.ActiveKeys(i);
% % %
% % %         % get current state
% % %         [~,cs]  = cfg.bBox.ljudObj.eDI(cfg.bBox.ljhandle, cur, 1); % check button
% % %
% % %         % get time
% % %         t       = GetSecs();
% % %
% % %         % check if voltage exceeds threshold
% % %         if cs < 1
% % %             resp = cur;
% % %             return
% % %         end
% % %     end
% % %     [ KbkeyIsDown, ~, KbKeyCode ] = KbCheck;
% % %     if KbkeyIsDown && KbKeyCode(cfg.continueKey)
% % %         resp = NaN;
% % %         return
% % %     end
% % % end
% % % end

% % % %Button box resonse (non-blocking)
% % % function [KeyIsDown,t,resp] = BbCheck(cfg)
% % %
% % % %check all active keys
% % % for i=1:length(cfg.bBox.ActiveKeys) %cycle through active keys/buttons
% % %
% % %     cur=cfg.bBox.ActiveKeys(i);
% % %
% % %     % get current state
% % %     [~,cs]  = cfg.bBox.ljudObj.eDI(cfg.bBox.ljhandle, cur, 1); % check button
% % %
% % %     % check if voltage exceeds threshold
% % %     if cs < 1
% % %         KeyIsDown=1;
% % %         t = GetSecs;% get time
% % %         resp = cur;
% % %         break;
% % %     else
% % %         KeyIsDown=0;
% % %         t=[];
% % %         resp=[];
% % %     end
% % % end
% % % end


%function to send MEG and eyelink triggers
function [cfg] = sendTrigger(cfg,trig)

%send trigger to MEG
if ~cfg.debugmode
    io64(cfg.ioObjTrig,cfg.PortAddress,trig);
    cfg.triggerTime = GetSecs;
    cfg.triggerSent = 1;
else
    cfg.triggerTime = GetSecs;
end

%send trigger to eyelink
if cfg.el.eyelink
    Eyelink('Message', ['Trigger_' int2str(trig)]);
end
end

function [] = cleanup(cfg)
%Return propixx to normal state
if  ~cfg.debugmode
    Datapixx('SetPropixxDlpSequenceProgram', 0);
    Datapixx('RegWrRd');
    Datapixx('close');
end

%lower priority
if ~cfg.debugmode
    Priority(0);
end

%stop eyelinkq
if cfg.el.eyelink
    Eyelink('Message', 'end of block - ABORTED');
    el_Stop(cfg);
end

%close screen
Screen('CloseAll');
%ListenChar(0);
ShowCursor;
%throw warning due to prematurely aborted experiment56
warning('Experiment aborted');
end

function pix = usrDeg2Pix(degree,cfg)
ProjectorResolution_y = 0.5*cfg.resy; %% in rapid mode
pix = tan(degree/2/180*pi)*cfg.dist/cfg.height*2*ProjectorResolution_y;
end

function cfg = el_calib_valid(cfg,mode)
%%% set screen back to normal cfg.RT
Datapixx('SetPropixxDlpSequenceProgram', 0);
Datapixx('RegWrRd');

if mode == 0 %% run the eye-tracker setup for the first time
  %%% run el_Start
  cfg = el_Start_SameWindow(cfg);
  %%% get CheckEyeMyself
  cfg.el.defaults.CheckEyeMyself = cfg.CheckEyeMyself;
  cfg.el.defaults.ScrBgc = cfg.ScrBgc;
  cfg.el.defaults.TextColor = cfg.TextColor;
elseif mode == 1 %% run the eye-tracker setup for the non-first time
  %%% re-calibration and re-validation and re-drift correction
  EyelinkDoTrackerSetup(cfg.el.defaults);
elseif mode == 2 
   EyelinkDoDriftCorrection(cfg.el.defaults);
   Eyelink('StartRecording');
    % record a few samples before we actually start displaying
    WaitSecs(0.1);
    % mark zero-plot time in data file
    disp('Sending message')
    Eyelink('Message', 'SYNCTIME');
   
end
%%% set screen to rapid mode
Datapixx('SetPropixxDlpSequenceProgram', 5);
Datapixx('RegWrRd');
%%% set screen to experiment background color
Screen('FillRect', cfg.window, cfg.ScrBgc)
Screen('Flip', cfg.window);
end
