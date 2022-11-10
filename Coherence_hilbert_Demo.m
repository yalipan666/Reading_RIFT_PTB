%% ======= calculating coherence using hilbert transformation 

%%%% parameters
freqrange = 40:2:80;
freq_halfwidth = 5; %%% for hilbert filter

%%%% just to get a dummy coherence struct
cfg            = [];
cfg.output     = 'fourier';
cfg.channel    = {'MEGGRAD','MISC004'};
cfg.method     = 'mtmconvol';
cfg.taper      = 'hanning';
cfg.foi        = freqrange;
cfg.toi        = -0.5:0.5:0.5;
cfg.t_ftimwin  = ones(length(cfg.foi),1).*0.5;
cfg.keeptrials = 'yes';
cfg.pad        = 'nextpow2';
fourier = ft_freqanalysis(cfg, epochdata);
%%% get coherence spctrm
cfg            = [];
cfg.method     = 'coh';
cfg.channelcmb = {'MEGGRAD', 'MISC004'}; %% all channell combinations calculated together
coh            = ft_connectivityanalysis(cfg, fourier); %% the raw coherence
coh.label      = fourier.label(1:length(coh.labelcmb));
coh.time       = epochdata.time{1}; %% get the time from the raw epochdata

%%%% do the real coherence using hilbert complex
coh.cohspctrm = zeros(length(coh.label),length(coh.freq),length(coh.time));
for fff = 1:length(freqrange)
    %%%% get hilbert filert data
    cfg = [];
    cfg.channel    = {'MEGGRAD','MISC004'};
    cfg.bpfilter   = 'yes';
    cfg.bpfreq     = [freqrange(fff)-freq_halfwidth freqrange(fff)+freq_halfwidth];
    cfg.hilbert    = 'complex';
    cfg.keeptrials = 'yes';
    fltdata = ft_preprocessing(cfg, epochdata);
    for chan = 1:length(fltdata.label)-1
        for ttt = 1:length(fltdata.trial)
            sig1(:,ttt) = fltdata.trial{ttt}(chan,:);
            sig2(:,ttt) = fltdata.trial{ttt}(end,:);
        end
        spec1 = nanmean(sig1.*conj(sig1),2);
        spec2 = nanmean(sig2.*conj(sig2),2);
        specX = abs(nanmean(sig1.*conj(sig2),2)).^2;
        coh.cohspctrm(chan,fff,:) = specX./(spec1.*spec2);
    end
end






%% ======= permutation test of coherence 
%%%get fourier spctrm --- no time domain
cfg              = [];
cfg.output       = 'fourier';
cfg.channel      = {'MEGGRAD','MISC004'};
cfg.method       = 'mtmfft';
cfg.taper        = 'hanning';
cfg.foi          = tagfreq;
cfg.pad          = 'nextpow2';
fourier          = ft_freqanalysis(cfg,data_all);%=% tfr.powspctrm:3D data: trialnum*channelnum*freqpoint
fourier_bl       = ft_freqanalysis(cfg,epoch_BL_Cross);

%%%% statistical test of coherence (here i just run test over the occipital
%%%% sensors to save time, you can run the test over all sensors)
load OccipSens_full
nchancom = length(OccipSens_full);
stat_mask = zeros(nchancom,1);

tic
for i = 1:nchancom
    cfg            = [];
    cfg.channel    = {OccipSens_full{i},'MISC004'};
    fourier_tmp    = ft_selectdata(cfg, fourier);
    fourier_bl_tmp = ft_selectdata(cfg, fourier_bl);
    
    cfg                  = [];
    cfg.parameter        = 'fourierspctrm';
    cfg.frequency        = tagfreq;
    cfg.statistic        = 'ft_statfun_indepsamplesZcoh';  %%%% take fourierspctrm as input, so no time domain information
    cfg.method           = 'montecarlo';
    cfg.tail             = 1; %% right sided, grp1 is bigger than grp2
    cfg.alpha            = 0.01;
    cfg.numrandomization = 10000;
    ntrl_1 = size(fourier.fourierspctrm,1);
    ntrl_2 = size(fourier_bl.fourierspctrm,1);
    design = zeros(1, ntrl_1 + ntrl_2);
    design(1,1:ntrl_1) = 1;
    design(1,(ntrl_1 +1):(ntrl_1 + ntrl_2))= 2;
    cfg.design = design;
    cfg.ivar   = 1;
    cfg.design = design;
    stat = ft_freqstatistics(cfg, fourier_tmp, fourier_bl_tmp);
    stat_mask(i) = stat.mask;
    stat_p(i,1)  = stat.prob;
end
toc
TagCoh.Stat(:,1) = stat_mask;
















