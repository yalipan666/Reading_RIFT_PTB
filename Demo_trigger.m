%declare variables
PortAddress = hex2dec('BFF8');
ioObjTrig = io64;
status = io64(ioObjTrig);
io64(ioObjTrig,PortAddress,0); %trigger 0 (reset)
cfg.PortAddress = PortAddress;
cfg.ioObjTrig = ioObjTrig;

%%%% initiation, no trigger sent yet
cfg.triggerSent=0;

%%% send trigger; trig can be integer from 1 to 255 (8 trigger channels)
cfg = sendTrigger(cfg,trig);

%we want to reset the trigger 50ms after the last trigger
if cfg.triggerSent && GetSecs>(cfg.triggerTime+0.05)
    io64(cfg.ioObjTrig,cfg.PortAddress,0);
    cfg.triggerSent=0;
end

%function to send MEG and eyelink triggers
function [cfg] = sendTrigger(cfg,trig)
%send trigger to MEG
if ~cfg.debugmode
    io64(cfg.ioObjTrig,cfg.PortAddress,trig);
    cfg.triggerSent = 1;
end
%send trigger to eyelink
if cfg.el.eyelink
    Eyelink('Message', ['Trigger_' int2str(trig)]);
end
cfg.triggerTime = GetSecs;
end