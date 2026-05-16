
%% =======================
% LOADCELL CALIBRATIE MET FORCE / BODY MASS
% =======================
clear; clc; close all;

%% -------- SETTINGS --------
calibFolder = 'C:/Users/janwi/MRP/DATA/PP1/Loadcell';  
adaptation_idx = [2 8];        % Adaptatiepunten

fs_loadcell = 200;      

adapt_minutes  = 6;  % Adaptatie trials
normal_minutes = 3;  % Normale trials

body_mass = 62; % gram 

% Gegeven kalibratie (volt → Newton)
gain = 6.2728e+04;   % N/V
offset_cal = 4.1315;  % N

%% -------- BESTANDEN INLEZEN --------
files = dir(fullfile(calibFolder,'*.gai'));
if isempty(files)
    error('Geen .gai bestanden gevonden in map %s', calibFolder);
end

% Sorteer bestanden numeriek
file_nums = zeros(1,length(files));
for i = 1:length(files)
    tokens = regexp(files(i).name,'TN0*(\d+)\.gai','tokens');
    file_nums(i) = str2double(tokens{1});
end
[~, sort_idx] = sort(file_nums);
files = files(sort_idx);

%% -------- GEMIDDELDE VOLTAGES EN FORCE --------
volt_means = zeros(1,length(files));
Force = zeros(1,length(files));

for i = 1:length(files)
    file = fullfile(calibFolder, files(i).name);
    data = readmatrix(file,'FileType','text');
    volt = data(:,3);
    
    % ---- Bepaal lengte segment ----
    if ismember(i, adaptation_idx)
        samples_needed = adapt_minutes * 60 * fs_loadcell;
    else
        samples_needed = normal_minutes * 60 * fs_loadcell;
    end
    
    % ---- Selecteer laatste segment ----
    if length(volt) > samples_needed
        volt_segment = volt(end - samples_needed + 1:end);
    else
        volt_segment = volt;
        
        if ismember(i, adaptation_idx)
            typeStr = 'Adaptatie';
        else
            typeStr = 'Normaal';
        end
        
        warning('%s (%s) is korter dan gewenste tijd (%d min)', ...
            files(i).name, typeStr, samples_needed/(60*fs_loadcell));
    end
    
    % Gemiddelde voltage
    volt_mean = mean(volt_segment);
    volt_means(i) = volt_mean;
    
    % Force in N (offset_cal toepassen)
    Force(i) = -(gain * volt_mean + offset_cal);
end

% Force normaliseren naar N/kg
Force_norm = Force / body_mass;

%% -------- PRINT --------
fprintf('\nForce (N/kg) per file:\n');
for i = 1:length(files)
    if ismember(i, adaptation_idx)
        fprintf('%s: %.4f N/kg (Adaptatiepunt)\n', files(i).name, Force_norm(i));
    else
        fprintf('%s: %.4f N/kg\n', files(i).name, Force_norm(i));
    end
end

%% -------- SORTEREN OP FORCE (klein → groot) --------
[Force_sorted, sort_idx] = sort(Force_norm, 'ascend');

volt_sorted = volt_means(sort_idx);
is_adapt_sorted = ismember(sort_idx, adaptation_idx);

%% -------- LINEAIRE FIT --------
p = polyfit(volt_sorted, Force_sorted,1);
volt_fit = linspace(min(volt_sorted), max(volt_sorted), 300);
force_fit = polyval(p, volt_fit);

%% -------- PLOT --------
figure; hold on; grid on;

% Normale meetpunten
plot(volt_sorted(~is_adapt_sorted), Force_sorted(~is_adapt_sorted),'o','MarkerSize',8,'LineWidth',1.5,'DisplayName','Meetpunten');

% Adaptatiepunten
plot(volt_sorted(is_adapt_sorted), Force_sorted(is_adapt_sorted),'s','MarkerSize',8,'LineWidth',1.5,'DisplayName','Adaptatiepunten');

% Lineaire fit
plot(volt_fit, force_fit,'r-','LineWidth',2,'DisplayName','Lineaire fit');

xlabel('Gemiddelde Voltage (V)');
ylabel('Force / Body Mass (N/kg)');
title('Loadcell Kalibratie (Genormaliseerde Kracht)');
legend('Location','best');

fprintf('\nLineaire fit (N/kg): y = %.4f*V + %.4f\n', p(1), p(2));

%% -------- SAVE DATA --------
PP_name = 'PP1';
dataFolder = 'C:\Users\janwi\MRP\DATA';
if ~exist(dataFolder,'dir')
    mkdir(dataFolder);
end
masterFile = fullfile(dataFolder,'allPP.mat');

% Bestand veilig laden of aanmaken
if exist(masterFile,'file')
    load(masterFile,'allPP');  
else
    allPP = struct();
end

% Bestaande PP-struct behouden
if isfield(allPP, PP_name)
    existing_PP = allPP.(PP_name);
else
    existing_PP = struct();
end

% Nieuwe velden toevoegen/overschrijven
existing_PP.Force_adapt1 = Force_norm(adaptation_idx(1));          
existing_PP.Force_adapt2 = Force_norm(adaptation_idx(2));

normal_trials_idx = setdiff(1:length(Force_norm), adaptation_idx);
existing_PP.Force_all    = Force_norm(normal_trials_idx);          
existing_PP.Force_sorted = Force_sorted(~is_adapt_sorted);         

% Zet terug in allPP
allPP.(PP_name) = existing_PP;
save(masterFile,'allPP');

disp(['PP ' PP_name ' bijgewerkt in allPP.mat, bestaande velden behouden!']);


%% =======================
% EXTRA PLOT: FULL TIME ADAPTATIE (ECHT VERLOOP)
% =======================
adapt_trials_idx = [2, length(files)];   % adaptatiepunten

figure('Name','Adaptatie Force over volledige tijd','NumberTitle','off'); 
hold on; grid on;
colors = lines(length(adapt_trials_idx));

for k = 1:length(adapt_trials_idx)
    idx = adapt_trials_idx(k);
    
    file = fullfile(calibFolder, files(idx).name);
    data = readmatrix(file,'FileType','text');
    volt = data(:,3);
    
    % Tijdvector
    time_vec = (0:length(volt)-1)/fs_loadcell;
    
    % Punt-voor-punt omzetten naar kracht
    force_vec = -(gain * volt + offset_cal);
    
    % Normaliseren
    force_norm_vec = force_vec / body_mass;
    
    % Plot echte tijdserie
    plot(time_vec, force_norm_vec, 'Color', colors(k,:), 'LineWidth',1.5, ...
        'DisplayName', files(idx).name);
end

xlabel('Tijd (s)');
ylabel('Force / Body Mass (N/kg)');
title('Adaptatie Force over volledige tijd (ruwe data)');
legend('Location','best');


%% =======================
% SAVE FULL TIME ADAPTATION (RAW DATA)
% =======================

adapt_trials_idx = [2, length(files)];

Loadadapt = cell(length(adapt_trials_idx),1);

for k = 1:length(adapt_trials_idx)
    
    idx = adapt_trials_idx(k);
    
    file = fullfile(calibFolder, files(idx).name);
    data = readmatrix(file,'FileType','text');
    volt = data(:,3);
    
    % =========================
    % VOLLEDIGE TIJD
    % =========================
    time_vec = (0:length(volt)-1)/fs_loadcell;
    
    % voltage → force
    force_vec = -(gain * volt + offset_cal);
    force_norm_vec = force_vec / body_mass;
    
    % =========================
    % GEEN KNIP MEER!
    % =========================
    
    Loadadapt{k}.force = force_norm_vec(:);
    Loadadapt{k}.time  = time_vec(:);
end

% =======================
% SAVE IN ALLPP
% =======================
existing_PP.Loadadapt = Loadadapt;
allPP.(PP_name) = existing_PP;
save(masterFile,'allPP');

disp('Loadadapt (VOLLEDIGE RUWE TIJDREEKS) opgeslagen');