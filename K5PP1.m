%% 

% =======================
clear; close all; clc

%% =======================
% DEFINE TRIALS
% =======================
files = dir('Trial*.xlsx');
trialFiles = {files.name};

m = 62;    % kg
v = 1.25;  % m/s

% Handmatige volgorde (pas aan indien nodig)
% 1 = rest, 2 = baseline walking, 3..9 = forced
trial_order = [1 2 3 4 5 6 7 8 9]; 
trialFiles_sorted = trialFiles(trial_order);

%% =======================
% DEFINE TRIAL TYPES
% =======================
rest_idx = 1;
baseline_idx = 2;
adaptation_idx = [3 9];  

% Zorg dat baseline niet in adaptation zit
adaptation_idx = setdiff(adaptation_idx, baseline_idx);
adaptation_idx = adaptation_idx(adaptation_idx <= length(trialFiles_sorted));

rest_trial = trialFiles_sorted{rest_idx};
baseline_trial = trialFiles_sorted{baseline_idx};
force_idx = setdiff(1:length(trialFiles_sorted), [rest_idx baseline_idx adaptation_idx]);
force_trials = trialFiles_sorted(force_idx);

disp('Rest trial:'); disp(rest_trial);
disp('Baseline trial:'); disp(baseline_trial);
disp('Adaptation trials:'); disp(trialFiles_sorted(adaptation_idx));
disp('Force trials:'); disp(force_trials);

%% =======================
% REST CoT
% =======================
data_rest = readmatrix(rest_trial);
data_rest = data_rest(4:end,[10,15,16]);
VO2_rest = data_rest(:,2)./1000 ./60;
VCO2_rest = data_rest(:,3)./1000 ./60;
tijd_rest = (0:10:10*(length(VO2_rest)-1))';
EE_rest = 1000*(16.89 .* VO2_rest + 4.82 .* VCO2_rest);

CoT_rest = EE_rest ./ (m .* v);
lastSec = 180;
lastIdx = tijd_rest >= (tijd_rest(end) - lastSec);
meanCoT_rest = mean(CoT_rest(lastIdx));
fprintf('\nRest CoT: %.2f J/kg/m\n', meanCoT_rest);

%% =======================
% BASELINE CoT (NETTO)
% =======================
data_base = readmatrix(baseline_trial);
data_base = data_base(4:end,[10,15,16]);
VO2_base = data_base(:,2)./1000 ./60;
VCO2_base = data_base(:,3)./1000 ./60;
tijd_base = (0:10:10*(length(VO2_base)-1))';
EE_base = 1000* (16.89 .* VO2_base + 4.82 .* VCO2_base);

CoT_base = EE_base ./ (m .* v);
lastIdx = tijd_base >= (tijd_base(end) - lastSec);
meanCoT_base = mean(CoT_base(lastIdx));
meanCoT_base_net = meanCoT_base - meanCoT_rest;
fprintf('Baseline walking CoT (gross): %.2f J/kg/m\n', meanCoT_base);
fprintf('Baseline walking CoT (net): %.2f J/kg/m\n', meanCoT_base_net);

%% =======================
% FORCE TRIALS: GENORMALISEERD CoT
% =======================
figure('Name','Normalized Cost of Transport','NumberTitle','off'); hold on;
colors = lines(length(force_trials));
meanCoT_all = zeros(1,length(force_trials));

for k = 1:length(force_trials)
    data1 = readmatrix(force_trials{k});
    data = data1(4:end,[10,15,16]);
    VO2 = data(:,2)./1000 ./60; VCO2 = data(:,3)./1000 ./60;
    tijd = (0:10:10*(length(VO2)-1))';
    
EE = 1000*(16.89 .* VO2 + 4.82 .* VCO2);

CoT = EE ./ (m .* v);
    
    
    % Netto tov rest
    CoT_net = CoT - meanCoT_rest;
    
    % Normalisatie tov baseline walking
    CoT_norm = CoT_net ;
    
    plot(tijd, CoT_norm, 'LineWidth', 2, 'Color', colors(k,:));
    
    lastIdx = tijd >= (tijd(end) - lastSec);
    meanCoT_all(k) = mean(CoT_norm(lastIdx));
end

xlabel('Tijd (s)'); ylabel('Netto CoT / baseline (-)');
title('Genormaliseerde Cost of Transport (Force Trials)');
legend(force_trials, 'Interpreter','none','Location','best'); grid on;

fprintf('\n=== GENORMALISEERDE CoT ===\n');
for k = 1:length(force_trials)
    fprintf('%s: %.2f (-)\n', force_trials{k}, meanCoT_all(k));
end

%% =======================
% FORCE vs CoT PLOT
% =======================
% Gemeten volgorde in experiment (in %)
force_levels_unsorted = [100 60 20 80 40];  

[force_levels_sorted, sort_idx] = sort(force_levels_unsorted);
force_levels_sorted = force_levels_sorted(:)';  
CoT_sorted = meanCoT_all(sort_idx); CoT_sorted = CoT_sorted(:)';

% Voeg baseline toe
force_all = [0 force_levels_sorted];
CoT_all_plot = [meanCoT_base_net CoT_sorted];  % baseline = 1

% 2e orde fit
p = polyfit(force_all, CoT_all_plot, 2);
x_fit = linspace(0,100,200);
y_fit = polyval(p, x_fit);

% Plot
figure('Name','Force vs CoT','NumberTitle','off'); hold on;
plot(force_all, CoT_all_plot,'o','MarkerSize',8,'LineWidth',2);
plot(x_fit, y_fit,'LineWidth',2);
xlabel('Force (%)'); ylabel('Genormaliseerde CoT (-)');
title('Force vs Cost of Transport (incl. baseline)'); grid on;
legend('Data','2nd order fit','Location','best');

% Optimum
opt_force = -p(2)/(2*p(1));
fprintf('\nOptimum force: %.1f %%\n', opt_force);

%% =======================
% GENORMALISEERDE ADAPTATION TRIALS (laatste 6 min)
% =======================
lastSec_adapt = 360;  % 6 minuten
CoT_adapt = zeros(1,length(adaptation_idx));

for k = 1:length(adaptation_idx)
    trial_name = trialFiles_sorted{adaptation_idx(k)};
    data1 = readmatrix(trial_name);
    data = data1(4:end,[10,15,16]);
    VO2 = data(:,2)./60 ./1000; VCO2 = data(:,3)./60 ./1000;
    tijd = (0:10:10*(length(VO2)-1))';
    
EE = 1000*(16.89 .* VO2 + 4.82 .* VCO2);

CoT = EE ./ (m .* v);
    
    CoT_net = CoT - meanCoT_rest;
   
    
    lastIdx = tijd >= (tijd(end) - lastSec_adapt);
    CoT_adapt(k) = mean(CoT_net(lastIdx));
end

for k = 1:length(CoT_adapt)
    fprintf('Adaptation trial %d (laatste 6 min): %.2f (-)\n', adaptation_idx(k), CoT_adapt(k));
end

%% =======================
% OPSLAAN IN allPP
% =======================
PP_name = 'PP1';  % pas aan naar juiste PP
dataFolder = 'C:\Users\janwi\MRP\DATA';
masterFile = fullfile(dataFolder,'allPP.mat');

if exist(masterFile,'file')
    load(masterFile,'allPP');
else
    allPP = struct();
end

if isfield(allPP, PP_name)
    existing_PP = allPP.(PP_name);
else
    existing_PP = struct();
end


existing_PP.CoT_sorted = CoT_all_plot;

% Adaptation CoT opslaan
existing_PP.CoT_adapt1 = CoT_adapt(1);
existing_PP.CoT_adapt2 = CoT_adapt(2);

allPP.(PP_name) = existing_PP;
save(masterFile,'allPP');

disp(['PP ' PP_name ' bijgewerkt in allPP.mat met gesorteerde CoT + adaptation CoT']);
