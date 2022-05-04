%Use this script to extract tempo, pulse clarity, attack slope, roughness, rolloff, and inharmonicity in addition to appropriate statistics from both concatenated and split IDS files using MIRToolbox 1.7.2. 

% Add libraries
addpath(genpath([pwd '\MIRtoolbox1.7.2\MIRToolbox']));
addpath(genpath([pwd '\mPraat-master']));

% Gather filepaths
clip_loc = ['..\IDSProject\Clips'];
subclip_loc = ['..\IDSProject\Concatenated']; % reconcatenated with concatenate.py
tg_loc = ['..\IDSProject\Textgrids'];

clip_files = dir([clip_loc '/*.wav']);
subclip_files = dir([subclip_loc '/*.wav']);

% Re-write the .csvs every 100 clips to save progress
rewrite_rate = 100;

%% mirtempo / mirpulseclarity
tempo_pulseclarity = struct();
for i = 1:length(clip_files)
    try
        % File ID
        [pth, name, ext] = fileparts(clip_files(i).name);
        tempo_pulseclarity(i).id = name;
        
        % This miraudio computation is needed for most other metrics
        aud = miraudio([clip_loc '/' clip_files(i).name]);
        aud_path = [clip_loc '/' clip_files(i).name]
        
        % Get mirtempo
        [tempo, autocorrelation] = mirtempo(aud);
        tempo_pulseclarity(i).mir_tempo = mirgetdata(tempo);
        
        % Get mirpulsesclarity
        pulseclarity = mirpulseclarity(autocorrelation);
        tempo_pulseclarity(i).mir_pulseclarity = mirgetdata(pulseclarity);
        
        if mod(i, rewrite_rate) == 0
            writetable(struct2table(tempo_pulseclarity), 'tempo_pulseclarity.csv');
        end
    catch ERR
        errTxt = getReport(ERR);
        tempo_pulseclarity(i).error = errTxt;
        warning(['Something went wrong with file: ' clip_files(i).name '. The error was: ' errTxt]);
    end
end
writetable(struct2table(tempo_pulseclarity), 'tempo_pulseclarity.csv');

%% mirattackslope
reconcatenated_attack = struct();
for i = 1:length(subclip_files)
    try
        [pth, name, ext] = fileparts(subclip_files(i).name);
        reconcatenated_attack(i).id = name;
        
        % Extract attack slopes
        [attackslope, events] = mirattackslope([subclip_loc '/' subclip_files(i).name]);
        reconcatenated_attack(i).attackslope = attackslope;
        reconcatenated_attack(i).events = events;
        
    catch ERR
        errTxt = getReport(ERR);
        reconcatenated_attack(i).error = errTxt;
        warning(['Something went wrong with file: ' subclip_files(i).name '. The error was: ' errTxt]);
    end
end

% Save intermediate attackslope data
save('reconcatenated_attack.mat', 'reconcatenated_attack')

%% attackslope - compute summary statistics
for i = 1:length(subclip_files)
    % Extract individual frames
    frames = mirgetdata(reconcatenated_attack(i).attackslope);
    frames_pos = get(reconcatenated_attack(i).attackslope, 'FramePos');
    
    if ~isempty(frames)
        reconcatenated_attack(i).mir_attack_mean = nanmean(frames);
        reconcatenated_attack(i).mir_attack_std = nanstd(frames);
        reconcatenated_attack(i).mir_attack_range = range(frames);
        quantiles = quantile(frames, [0 0.25 0.5 0.75 1]);
        reconcatenated_attack(i).mir_attack_min = quantiles(1);
        reconcatenated_attack(i).mir_attack_first_quart = quantiles(2);
        reconcatenated_attack(i).mir_attack_median = quantiles(3);
        reconcatenated_attack(i).mir_attack_third_quart = quantiles(4);
        reconcatenated_attack(i).mir_attack_max = quantiles(5);
        reconcatenated_attack(i).mir_attack_iqr = iqr(frames);
    end
end

% Save summary in .csv
attack_summary = reconcatenated_attack;
attack_summary = rmfield(attack_summary, {'attackslope'});
writetable(struct2table(attack_summary), 'mir_reconcatenated_attack_summary.csv');

%% mirroughness / mirrolloff / mirinharmonicity - for reconcatenated subclips
roughness_rolloff_inharm = struct();
for i = 1:length(subclip_files)
    try
        [pth, name, ext] = fileparts(subclip_files(i).name);
        roughness_rolloff_inharm(i).id = name;
        
        % This miraudio computation is needed for most other metrics
        aud = miraudio([subclip_loc '/' subclip_files(i).name]);
        
        % Get RMS-normalized mean of mirroughness vis-a-vis Buyens et al. (2017)
        roughness = mirroughness(aud, 'Frame', .05);
        roughness_rolloff_inharm(i).mir_roughness = roughness;
        mean_roughness = mean(mirgetdata(roughness)) / mirgetdata(mirrms(aud));
        roughness_rolloff_inharm(i).mir_roughness_mean = mean_roughness; 
        
        % Get mirrolloff
        rolloff = mirrolloff(aud, 'Threshold', .85);
        roughness_rolloff_inharm(i).mir_rolloff85 = mirgetdata(rolloff);
        
        % Get mirinharmonicity
        inharmonicity = mirinharmonicity(aud);
        roughness_rolloff_inharm(i).mir_inharmonicity = mirgetdata(inharmonicity);
        
    catch ERR
        errTxt = getReport(ERR);
        roughness_rolloff_inharm(i).error = errTxt;
        warning(['Something went wrong with file: ' subclip_files(i).name '. The error was: ' errTxt]);
    end
end

save('roughness_rolloff_inharm.mat', 'roughness_rolloff_inharm')
%% Get roughness summary statistics
for i = 1:length(subclip_files)
    % Extract individual roughness frames
    frames = mirgetdata(roughness_rolloff_inharm(i).mir_roughness);
    frames_pos = get(roughness_rolloff_inharm(i).mir_roughness, 'FramePos');
    frames_pos = frames_pos{1}{1}(1,:); % extract just the beginnings of each frame
    
    % Get other summary statistics
    roughness_rolloff_inharm(i).mir_roughness_std = nanstd(frames);
    roughness_rolloff_inharm(i).mir_roughness_range = range(frames);
    quantiles = quantile(frames, [0.25 0.5 0.75 1]);
    roughness_rolloff_inharm(i).mir_roughness_first_quart = quantiles(1);
    roughness_rolloff_inharm(i).mir_roughness_median = quantiles(2);
    roughness_rolloff_inharm(i).mir_roughness_third_quart = quantiles(3);
    roughness_rolloff_inharm(i).mir_roughness_max = quantiles(4);
    roughness_rolloff_inharm(i).mir_roughness_iqr = iqr(frames);
end

roughness_rolloff_inharm_summary = roughness_rolloff_inharm;
roughness_rolloff_inharm_summary = rmfield(roughness_rolloff_inharm_summary, {'mir_roughness'});
writetable(struct2table(roughness_rolloff_inharm_summary), 'roughness_rolloff_inharm.csv');

%% Computes distance in a metric (vals) per second (times)
function vel = velocity(vals, times)
dist = 0;
dist_x = 0;
for j = 1:length(vals)-1
    d_x = times(j) - times(j+1);
    d_y = vals(j) - vals(j+1);
    dist = dist + sqrt(d_x^2 + d_y^2);
    dist_x = dist_x + abs(d_x);
end
vel = dist / dist_x;
end

%% Helper function to reference the textgrids to find whether a certain timepoint (in seconds) is sounding
% test = isSounding('WEL05A', 4.5129, tg_loc)
% test2 = arrayfun(@(x) isSounding('WEL05B', x), attack_pos_sec, tg_loc)
function b = isSounding(id, time, loc)
tgrid = tgRead([loc '/' id '.TextGrid']);
labels = tgrid.tier{1}.Label;
intervals = [tgrid.tier{1}.T1; tgrid.tier{1}.T2];
for i = 1:length(intervals)
    if(intervals(1, i) < time) && (intervals(2, i) > time)
        b = length(labels{i}) == 1;
    end
end
end
