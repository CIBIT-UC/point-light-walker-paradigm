% funcao para calcular o espectro de varios datasets
% de teste para frequency tagging e hMT localizer

% spec_nonTL_Coh = [];
% spec_nonTL_Unc = [];
clc
clear

nomes_subs = {'BD'};

% filepath = 'F:\Pos-Doc 2017\Teste_EEG\hMT localiser\';
filepath = 'C:\Users\bdireito\Documents\MATLAB\data\EEG_humanmotion\processed';
p_files = dir(fullfile(filepath, '*.set'));

load('chanlocs62.mat')

clear ALLEEG

file_offset=3;

for subs = 1:numel(nomes_subs)
    
    for files = 1:3
        
        subject = cell2mat(nomes_subs(subs));
        
        filename = sprintf('%s%d.set', subject, files+file_offset);
        
        ALLEEG(1) = pop_loadset('filename', p_files(files+file_offset).name,...
        'filepath', p_files(files+file_offset).folder);
        
        % ----------------------------------------------------------------
        %                compute spectra for epoched data
        % ----------------------------------------------------------------
        
        % divide 100s epochs into 10s epochs for fft (frequency res = 0.1Hz
        % which is fine)
        for epoch = 1:10
            
            % points
            epochTimes = [1 10000; 10001 20000; 20001 30000; 30001 40000; 40001 50000; 50001 60000; ...
                60001 70000; 70001 80000; 80001 90000; 90001 100000];
            
            for channel = 1:size(ALLEEG.data,1)
                sizeEpo = length(ALLEEG.data(channel,epochTimes(epoch,1):epochTimes(epoch,2)));
                fftsig = fft(ALLEEG.data(channel,epochTimes(epoch,1):epochTimes(epoch,2)), sizeEpo);
                
                spectra(channel,:, epoch) = abs(fftsig(1:length(fftsig)/2));
            end
            
            spectra_epoch_Allcond{files}(:,:,subs) = mean(spectra,3);
            
            spectra_epoch_freqs_temp{files}(:,:,subs) = (0:1/(sizeEpo):1-1/(sizeEpo)).*ALLEEG.srate;
            
            spectra_epoch_freqs{files}(:,:,subs) =...
                spectra_epoch_freqs_temp{files}(1:length(spectra_epoch_freqs_temp{files})/2);
            
            %                 Freq = ((0:1/length(ALLEEG.data(49,:)):1-1/length(ALLEEG.data(49,:)))*ALLEEG.srate).';
            %                 figure; [spectra,freqs,speccomp,contrib,specstd] = spectopo(ALLEEG(dataset).data(1:58,251:750,:), 500, 500, 'freqrange', [2 100], 'freqfac', 2, 'overlap', 128);
            %                 close
            %                 if dataset == 1
            %                     spec_nonTL_Coh{files} = spectra;
            %                 elseif dataset == 2
            %                     spec_nonTL_Unc{files} = spectra;
            %                 else
            %                 end
            
        end
        
        % ----------------------------------------------------------------
        %                compute spectra for continuous data
        % ----------------------------------------------------------------
        %
        for channel = 1:size(ALLEEG.data,1)
            
            sizeData = length(ALLEEG.data(channel,:));
            
            fftsig = fft(ALLEEG.data(channel,:), sizeData);
            
            spectrafull(channel,:) = abs(fftsig(1:length(fftsig)/2));
            
            % Get fourier spectra of each channel for computing the CSD
            % later on (it is the spectrum of only the first 10th because
            % this contains the frequencies from 0-100Hz)
            fourier(channel,:) = fftsig(1:length(fftsig)/10);
        end
        
        spectra_full_Allcond{files}(:,:,subs) = spectrafull;
        spectra_full_freqs_temp{files}(:,:,subs) = (0:1/(sizeData):1-1/(sizeData)).*ALLEEG.srate;
        spectra_full_freqs{files}(:,:,subs) = spectra_full_freqs_temp{files}(1:length(spectra_full_freqs_temp{files})/2);
        
        % ----------------------------------------------------------------
        %                compute CSD for beamforming
        % ----------------------------------------------------------------
%         tic
%         chancmb = 1;
%         for chana = 1:size(spectra_full_Allcond{files},1);
%             for chanb = chana:size(spectra_full_Allcond{files},1);
%                 if chana == chanb
%                     % skip
%                 else
%                     csd_full_Alcond{files}.crsspctrm(chancmb,:) = fourier(chanb,:) .*conj(fourier(chana,:));
%                     
%                     csd_full_Alcond{files}.labelcmb{chancmb,1} = chanlocs(chanb).labels;
%                     csd_full_Alcond{files}.labelcmb{chancmb,2} = chanlocs(chana).labels;
%                     
%                     chancmb = chancmb + 1;
%                 end
%             end
%         end
%         toc
    end
end


save('spectraresults_5hz','spectra_full_freqs','spectra_epoch_freqs');