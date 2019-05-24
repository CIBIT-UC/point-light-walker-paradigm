% Plot spectra 2019
% created for plotting spectra results from freqeuncy tagging experiments
% and for transforming into SNR; averaging between subjects

subj = 1; % use [] if more than one subject

conda = 1; % corresponds to run number (which corresponds to different conditions)
condb = 2;

chan = 55;

clear spectra_AllcondSNRa
clear spectra_AllcondSNRb

if length(subj) == 1
    spectraA = spectra_epoch_Allcond{1,conda}(:,:,subj);
    spectraB = spectra_epoch_Allcond{1,condb}(:,:,subj);
else
    spectraA = mean(spectra_epoch_Allcond{1,conda}(:,:,[subj]),3);
    spectraB = mean(spectra_epoch_Allcond{1,condb}(:,:,[subj]),3);
end

spectra_freqs = spectra_epoch_freqs{1,conda};

sizeSpec = length(spectraA);

minFrq = floor(sizeSpec/900);
maxFrq = floor(sizeSpec/5);

winSNR = 5;

for datapnt = winSNR:length(spectraA)-winSNR
    
    spectra_AllcondSNRa(:,datapnt) = spectraA(:,datapnt)./ ...
        (mean([spectraA(:,(datapnt-winSNR):-1:(datapnt-1)) spectraA(:,(datapnt+1):(datapnt+winSNR))],2));
    
    spectra_AllcondSNRb(:,datapnt) = spectraB(:,datapnt)./ ...
        (mean([spectraB(:,(datapnt-winSNR):-1:(datapnt-1)) spectraB(:,(datapnt+1):(datapnt+winSNR))],2));
    
    spectra_full_freqsSNR = spectra_freqs(2:length(spectra_freqs)-1);
end

% if chan < 100
%     spectra_AllcondSNRa(chan, 45:140) = 0500;
% else
% end

figure; plot(spectra_full_freqsSNR(minFrq:maxFrq),spectra_AllcondSNRa(chan,minFrq:maxFrq)); hold on;
plot(spectra_full_freqsSNR(minFrq:maxFrq),spectra_AllcondSNRb(chan,minFrq:maxFrq), '-r'); hold on;

figure; plot(spectra_freqs(minFrq:maxFrq),spectraA(chan,minFrq:maxFrq)); hold on;
plot(spectra_freqs(minFrq:maxFrq),spectraB(chan,minFrq:maxFrq), '-r'); hold on;

%% Make the results fit in a fieldtrip structure to plot using fieldtrip functions

% get template for the 1020 layout
elec = ft_read_sens('standard_1020.elc');

cfg = [];
cfg.channel = {'-AF7' '-AF5' '-AF1' '-AF2' '-AF6' '-AF8' '-AFz' '-PO1' ...
    '-PO2' 'Fp1' 'Fpz' 'Fp2' 'AF3' 'AF4' 'F7' 'F5' 'F3' ...
    'F1' 'Fz' 'F2' 'F4' 'F6' 'F8' 'FT7' 'FC5' 'FC3' 'FC1' 'FCz' 'FC2' 'FC4' ...
    'FC6' 'FT8' 'T7' 'C5' 'C3' 'C1' 'Cz' 'C2' 'C4' 'C6' 'T8' 'TP7' 'CP5' 'CP3' ...
    'CP1' 'CPz' 'CP2' 'CP4' 'CP6' 'TP8' 'P7' 'P5' 'P3' 'P1' 'Pz' 'P2' 'P4' 'P6' ...
    'P8' 'PO7' 'PO5' 'PO3' 'POz' 'PO4' 'PO6' 'PO8' 'O1' 'Oz' 'O2' 'CB1' 'CB2'};
elec_62 = ft_selectdata(cfg, elec);

FA_ex = [];
FA_ex.freq = spectra_full_freqsSNR; % THIS HAS TO BE FIXED. THIS FIXING WORKS FOR NOW
FA_ex.label = elec_62.label;
FA_ex.dimord = 'chan_freq';

% cumtapcnt and cumsumcnt correspond to number of tapers and number of
% timepoints for each trial (hence it has dimensions ntrials x 1). I'll
% leave it with a low number since this data came from a continuous EEG
% recording
FA_ex.cumtapcnt = ones(3,1)*2;
FA_ex.cumsumcnt = ones(3,1)*10000;
FA_ex.powspctrm = spectra_AllcondSNRa([1:57 59:61], :) - spectra_AllcondSNRb([1:57 59:61], :);


% parameters for topoplot
cfg = [];
cfg.layout ='standard_1020.elc';
cfg.showlabels = 'yes';
cfg.parameter = 'powspctrm';
cfg.xlim      = [1 20];
% cfg.ylim      = [-0.5 1];

% plot spectrum
figure;
ft_multiplotER(cfg, FA_ex)


