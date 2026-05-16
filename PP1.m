%% =======================
% FULL EMG TRIAL ANALYSIS SCRIPT
% (Ca_total CORRECTED: normalized vs baseline walking)
% =======================
clear; close all; clc;

%% =======================
% SETTINGS
% =======================
n_muscles = 5;

T_force = 180;   % 3 min
T_long  = 360;   % 6 min

vol_i = [0.08, 0.10, 0.17, 0.05, 0.17];

fs_approx = 1000;
fs_new = 800;

baseline_file = 'Trial_4.csv';

adaptation_trials_idx = [1,7];

%% =======================
% FILTER DESIGN
% =======================
[b_bp, a_bp] = butter(4, [20 350]/(fs_new/2), 'bandpass');
[b_lp, a_lp] = butter(4, 6/(fs_new/2), 'low');

%% =======================
% LOAD BASELINE (WALKING)
% =======================
opts = detectImportOptions(baseline_file,'NumHeaderLines',7);
opts.SelectedVariableNames = [1,2,4,6,8,10];
EMG_base_raw = readmatrix(baseline_file, opts);

time_baseline = EMG_base_raw(:,1);
EMG_baseline = EMG_base_raw(:,2:6);

EMG_baseline = str2double(strrep(string(EMG_baseline), ',', '.'));

EMG_baseline = downsample(EMG_baseline, round(fs_approx/fs_new));
time_baseline = downsample(time_baseline, round(fs_approx/fs_new));

EMGenv_base = process_EMG(EMG_baseline, n_muscles, b_bp, a_bp, b_lp, a_lp);

a0_i = weighted_mean_EMG(EMGenv_base, time_baseline, T_long);

%% =======================
% FIND TRIALS
% =======================
files = dir('Trial_*.csv');
allFiles = {files.name};

trial_files = allFiles(~strcmp(allFiles, baseline_file));

trial_numbers = zeros(size(trial_files));

for i = 1:length(trial_files)
    tokens = regexp(trial_files{i}, 'Trial_(\d+)\.csv', 'tokens');
    trial_numbers(i) = str2double(tokens{1});
end

[~, sort_idx] = sort(trial_numbers);
trial_files = trial_files(sort_idx);

n_trials = length(trial_files);

disp('Gevonden trials:')
disp(trial_files')

%% =======================
% STORAGE
% =======================
Ca2_all      = zeros(n_trials,1);
Ca_max_all   = zeros(n_trials,1);
Ca_vol_all   = zeros(n_trials,1);
Ca_total_all = zeros(n_trials,1);

A_all = zeros(n_trials, n_muscles);

%% =======================
% LOOP TRIALS
% =======================
for k = 1:n_trials
    
    file = trial_files{k};
    fprintf('\nVerwerk trial: %s\n', file);
    
    opts = detectImportOptions(file,'NumHeaderLines',7);
    opts.SelectedVariableNames = [1,2,4,6,8,10];
    EMG_raw = readmatrix(file, opts);
    
    time_trial = EMG_raw(:,1);
    EMG_trial = EMG_raw(:,2:6);
    
    EMG_trial = str2double(strrep(string(EMG_trial), ',', '.'));
    
    EMG_trial = downsample(EMG_trial, round(fs_approx/fs_new));
    time_trial = downsample(time_trial, round(fs_approx/fs_new));
    
    EMGenv_trial = process_EMG(EMG_trial, n_muscles, b_bp, a_bp, b_lp, a_lp);
    
    % ---- TIJDVENSTER ----
    if ismember(k, adaptation_trials_idx)
        T_use = T_long;
    else
        T_use = T_force;
    end
    
    a_i = weighted_mean_EMG(EMGenv_trial, time_trial, T_use);
    
    % =======================
    % NORMALISATIE vs BASELINE
    % =======================
    A_i = a_i ./ a0_i;
    
    % =======================
    % COST METRICS
    % =======================
    Ca2    = mean(A_i.^2, 'omitnan');
    Ca_max = max(A_i);
    Ca_vol = sum(vol_i .* A_i)/sum(vol_i);
    
    % ⭐ CORRECTED TOTAL COST (baseline-normalized)
    Ca_total = mean(A_i, 'omitnan');
    
    % =======================
    % STORE
    % =======================
    Ca2_all(k)      = Ca2;
    Ca_max_all(k)   = Ca_max;
    Ca_vol_all(k)   = Ca_vol;
    Ca_total_all(k) = Ca_total;
    
A_all(k,:) = A_i;

    fprintf('A_i: %s\n', num2str(A_i));
    fprintf('Ca^2: %.3f | Ca_max: %.3f | Ca_vol: %.3f | Ca_total: %.3f\n', ...
        Ca2, Ca_max, Ca_vol, Ca_total);
end

%% =======================
% BAR PLOT
% =======================
figure
bar([Ca2_all, Ca_vol_all, Ca_total_all])
legend('Ca^2','Ca_{vol}','Ca_{total}')
xlabel('Trial')
ylabel('Normalized Cost')
title('EMG Activatiekosten per trial (vs baseline walking)')
grid on

%% =======================
% FORCE RELATION PLOT
% =======================
force_map = [NaN, 92.45, 54.44, 13.75, 75.66, 31.37, NaN];

normal_idx = true(1,n_trials);
normal_idx(adaptation_trials_idx) = false;

force_full = [0, force_map(normal_idx)];

Ca2_full     = [1, Ca2_all(normal_idx)'];
CaMax_full   = [1, Ca_max_all(normal_idx)'];
CaVol_full   = [1, Ca_vol_all(normal_idx)'];
CaTotal_full = [1, Ca_total_all(normal_idx)'];

[force_sorted, sort_idx] = sort(force_full);

Ca2_sorted      = Ca2_full(sort_idx);
Ca_max_sorted   = CaMax_full(sort_idx);
Ca_vol_sorted   = CaVol_full(sort_idx);
Ca_total_sorted = CaTotal_full(sort_idx);

figure; hold on; grid on;
xlabel('Percentage Force (%)');
ylabel('Cost (normalized vs baseline)');
title('Force vs EMG cost');
xlim([0 100]);

plot(force_sorted, Ca2_sorted, 'ro','LineWidth',2)
plot(force_sorted, Ca_max_sorted, 'gs','LineWidth',2)
plot(force_sorted, Ca_vol_sorted, 'b^','LineWidth',2)
plot(force_sorted, Ca_total_sorted, 'k*','LineWidth',2)

x_fit = linspace(0,100,300);

plot(x_fit, polyval(polyfit(force_sorted, Ca2_sorted,2), x_fit),'r-')
plot(x_fit, polyval(polyfit(force_sorted, Ca_max_sorted,2), x_fit),'g-')
plot(x_fit, polyval(polyfit(force_sorted, Ca_vol_sorted,2), x_fit),'b-')
plot(x_fit, polyval(polyfit(force_sorted, Ca_total_sorted,2), x_fit),'k-')

legend('Ca^2','Ca_{max}','Ca_{vol}','Ca_{total}','Location','best')

%% =======================
% SAVE PP STRUCT
% =======================
PP.name = 'PP1';

PP.Ca2_adapt1   = Ca2_all(adaptation_trials_idx(1));
PP.Ca2_adapt2   = Ca2_all(adaptation_trials_idx(2));

PP.CaMax_adapt1 = Ca_max_all(adaptation_trials_idx(1));
PP.CaMax_adapt2 = Ca_max_all(adaptation_trials_idx(2));

PP.CaVol_adapt1 = Ca_vol_all(adaptation_trials_idx(1));
PP.CaVol_adapt2 = Ca_vol_all(adaptation_trials_idx(2));

PP.CaTotal_adapt1 = Ca_total_all(adaptation_trials_idx(1));
PP.CaTotal_adapt2 = Ca_total_all(adaptation_trials_idx(2));

PP.Ca2_force     = Ca2_sorted(2:end);
PP.CaMax_force   = Ca_max_sorted(2:end);
PP.CaVol_force   = Ca_vol_sorted(2:end);
PP.CaTotal_force = Ca_total_sorted(2:end);

dataFolder = 'C:\Users\janwi\MRP\DATA';

if ~exist(dataFolder,'dir')
    mkdir(dataFolder);
end

masterFile = fullfile(dataFolder,'allPP.mat');

if exist(masterFile,'file')
    load(masterFile,'allPP');

names = fieldnames(allPP);

% Sorteer op PP nummer
[~, idx] = sort(cellfun(@(x) str2double(regexp(x,'\d+','match','once')), names));

names = names(idx);  % <-- vanaf nu ALTIJD juiste volgorde
    
else
    allPP = struct();
end



% Volgorde spieren:
% 1 = Biceps femoris caput longum
% 2 = Gastrocnemius medialis
% 3 = Soleus
% 4 = Tibialis anterior
% 5 = Vastus medialis

PP.BicepsFemoris_force   = A_force_sorted(:,1);
PP.Gastrocnemius_force   = A_force_sorted(:,2);
PP.Soleus_force          = A_force_sorted(:,3);
PP.TibialisAnterior_force = A_force_sorted(:,4);
PP.VastusMedialis_force  = A_force_sorted(:,5);

PP.BicepsFemoris_adapt1   = A_adapt(1,1);
PP.BicepsFemoris_adapt2   = A_adapt(2,1);

PP.Gastrocnemius_adapt1   = A_adapt(1,2);
PP.Gastrocnemius_adapt2   = A_adapt(2,2);

PP.Soleus_adapt1          = A_adapt(1,3);
PP.Soleus_adapt2          = A_adapt(2,3);

PP.TibialisAnterior_adapt1 = A_adapt(1,4);
PP.TibialisAnterior_adapt2 = A_adapt(2,4);

PP.VastusMedialis_adapt1  = A_adapt(1,5);
PP.VastusMedialis_adapt2  = A_adapt(2,5);



allPP.(PP.name) = PP;

save(masterFile,'allPP');

disp(['PP ' PP.name ' opgeslagen!']);


%% =======================
% MUSCLE ACTIVATION PLOTS
% =======================

% Labels in juiste volgorde
trial_labels = {'0%', '13.75%', '31.37%', '54.44%', ...
                '75.66%', '92.45%', ...
                'Adapt 1', 'Adapt 2'};

% Sorteervolgorde van force trials
force_order_idx = sort_idx(2:end) - 1;

% Data voorbereiden
A_force_sorted = A_all(normal_idx,:);
A_force_sorted = A_force_sorted(force_order_idx,:);

A_adapt = A_all(adaptation_trials_idx,:);

% Finale volgorde:
% baseline (=1), force trials, adaptations
A_plot = [
    ones(1,n_muscles);
    A_force_sorted;
    A_adapt
];

muscle_names = {'Muscle 1','Muscle 2','Muscle 3','Muscle 4','Muscle 5'};

figure

for m = 1:n_muscles
    
    subplot(3,2,m)
    
    plot(A_plot(:,m), '-o', 'LineWidth',2, 'MarkerSize',6)
    
    xticks(1:length(trial_labels))
    xticklabels(trial_labels)
    xtickangle(45)
    
    ylabel('Activation / Baseline')
    title(muscle_names{m})
    
    grid on
    
end

sgtitle('Normalized Muscle Activations per Trial')


%% =======================
% MUSCLE ACTIVATION BAR PLOTS
% =======================

% Labels in juiste volgorde
trial_labels = {'0%', '13.75%', '31.37%', '54.44%', ...
                '75.66%', '92.45%', ...
                'Adapt 1', 'Adapt 2'};

% Sorteervolgorde van force trials
force_order_idx = sort_idx(2:end) - 1;

% Data voorbereiden
A_force_sorted = A_all(normal_idx,:);
A_force_sorted = A_force_sorted(force_order_idx,:);

A_adapt = A_all(adaptation_trials_idx,:);

% Finale volgorde:
% baseline (=1), force trials, adaptations
A_plot = [
    ones(1,n_muscles);
    A_force_sorted;
    A_adapt
];

muscle_names = {'Muscle 1','Muscle 2','Muscle 3','Muscle 4','Muscle 5'};

figure

for m = 1:n_muscles
    
    subplot(3,2,m)
    
    bar(A_plot(:,m))
    
    xticks(1:length(trial_labels))
    xticklabels(trial_labels)
    xtickangle(45)
    
    ylabel('Activation / Baseline')
    title(muscle_names{m})
    
    ylim([0 max(A_plot(:))*1.1])
    
    grid on
    
end

sgtitle('Normalized Muscle Activations per Trial')


%% =======================
% FUNCTIONS
%% =======================

function EMGenv = process_EMG(EMG_data, n_muscles, b_bp, a_bp, b_lp, a_lp)
    EMGenv = zeros(size(EMG_data));
    
    for m = 1:n_muscles
        emg = EMG_data(:,m);
        
        idx_bad = ~isfinite(emg);
        if any(idx_bad)
            good_idx = find(~idx_bad);
            if length(good_idx) > 1
                emg(idx_bad) = interp1(good_idx, emg(good_idx), find(idx_bad), 'linear', 'extrap');
            else
                emg(idx_bad) = 0;
            end
        end
        
        emg_filt = filtfilt(b_bp, a_bp, emg);
        emg_rect = abs(emg_filt);
        EMGenv(:,m) = filtfilt(b_lp, a_lp, emg_rect);
    end
end

function a_i = weighted_mean_EMG(EMGenv, time_vec, T)
    n_muscles = size(EMGenv,2);
    a_i = zeros(1,n_muscles);
    
    t = time_vec(:);
    
    for m = 1:n_muscles
        EMG = EMGenv(:,m);
        
        min_len = min(length(EMG), length(t));
        EMG = EMG(1:min_len);
        t_local = t(1:min_len);
        
        t_start = max(t_local(end)-T, t_local(1));
        idx = t_local >= t_start;
        
        EMG_last = EMG(idx);
        t_last   = t_local(idx);
        
        if length(t_last) < 2 || (t_last(end)-t_last(1))==0
            a_i(m) = NaN;
        else
            dt = diff(t_last);
            a_i(m) = sum(EMG_last(1:end-1).*dt) / (t_last(end)-t_last(1));
        end
    end
end