% Data processing - MATLAB script for EEGlab preprocessing of data.


%% Get raw data from folder x
raw_folder='C:\Users\bdireito\Documents\MATLAB\data\EEG_humanmotion\raw';
raw_files=dir(fullfile(raw_folder, '*.cnt'));

results_filepath='C:\Users\bdireito\Documents\MATLAB\data\EEG_humanmotion\processed';

% Init EEGLAB
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% Process data according to common preprocessing
for f = 1:numel(raw_files)
    EEG = pop_loadcnt(fullfile(raw_files(f).folder, raw_files(f).name),...
        'dataformat','auto',...
        'memmapfile', '');
    
    EEG.setname=sprintf('run_%i_raw', f);
    
    % Change first trigger.
    EEG.event(1).type=11;
    
    % Add channel location.
    EEG = pop_chanedit(EEG, 'lookup','C:\\Users\\bdireito\\Documents\\MATLAB\\toolbox\\eeglab14_1_2b\\plugins\\dipfit2.3\\standard_BESA\\standard-10-5-cap385.elp');
    
    % Remove bad chans.
    EEG = pop_select( EEG,'nochannel',{'EKG' 'EMG' 'VEO' 'MEO' 'M1' 'M2' 'CB1' 'CB2' });
    
    
    % Filter data (bandass(.5, 100).
    EEG = pop_eegfiltnew(EEG, 0.5, 100, 6600, 0, [], 1);
    
    % RE-reference avg
    EEG = pop_reref( EEG, [] );
    
    % Create epoch for analysis
    EEG = pop_epoch( EEG, {  '11'  }, [10  120], 'newname', 'run_4_raw_epochs', 'epochinfo', 'yes');
    EEG = eeg_checkset( EEG );
    EEG = pop_rmbase( EEG, [10000  119999]);
    
    % Store the dataset into EEGLAB
    [ALLEEG EEG CURRENTSET ] = eeg_store(ALLEEG, EEG);
    
    EEG = pop_saveset(EEG, 'filename',sprintf('run_%i_epoch_processed.set', f),...
        'filepath','C:\\Users\\bdireito\\Documents\\MATLAB\\data\\EEG_humanmotion\\processed\\')
    
    
end