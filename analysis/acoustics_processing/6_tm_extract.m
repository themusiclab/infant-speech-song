%Use this script to extract temporal modulation spectrum information using Ding et al. 2017's TM script

%% Extract important info from files

addpath('libraries/ding_2017');
audio_folder = '..\IDSProject\Clips';
filenames = dir([audio_folder '/*wav*']);

%% Apply Ding's modulation spectrum analysis on all files
analysis = struct.empty;
for i = 1:length(filenames)
   try
       % Save file information
       analysis(i).fileinfo = filenames(i);
       [filepath, name, ext] = fileparts(filenames(i).name);
       analysis(i).id = name;

       % Print progress
       i
       name

       % Run Ding's script
       [ms, rms, f] = getSpec([audio_folder '/' filenames(i).name]);
       analysis(i).ms = ms;
       analysis(i).rms = rms;
       analysis(i).f = f;

       % Get peak
       [max_val, max_idx] = max(rms);
       analysis(i).tm_peak_hz = bin2hz(max_idx);
       
       % Get weighted variance
       idx = 1:600;
       hz = bin2hz(idx);
       amp = analysis(i).rms;
       analysis(i).tm_std_hz = std(hz, amp);
%    
%    catch ERR
%        errTxt = getReport(ERR);
%        analysis(i).error = errTxt;
%        warning(['Something went wrong with file: ' subclip_files(i).name '. The error was: ' errTxt]);
   end
end

%% Export all data
save('tm_data.mat');

%% Export summary data
summary = rmfield(analysis, {'ms', 'rms', 'f', 'fileinfo'});
summary = struct2table(summary);
writetable(summary, 'tm_summary.csv');

%% Maps range 1-600 to 0.5-32
function hz = bin2hz(b)
    hz = (b - 1) * ((32 - 0.5) / 600) + 0.5; 
end
