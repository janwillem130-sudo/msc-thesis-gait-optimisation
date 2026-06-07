%% =======================
% LOAD + ANALYSIS SCRIPT
% CoT aangepast:
% -> GEEN polynomial fit meer
% -> minimum datapunt + bijbehorende force
% =======================

clear; close all; clc;

%% =======================
% LOAD DATA
% =======================
dataFolder = 'C:\Users\janwi\MRP\DATA';
load(fullfile(dataFolder,'allPP.mat'));
%% ===== REMOVE PP9 =====

names = fieldnames(allPP);

[~, idx] = sort(cellfun(@(x) ...
    str2double(regexp(x,'\d+','match','once')), names));

PP_names = names(idx);
%% ===== SELECT PP's =====
PP_select = [1 2 3 4 5];   % <-- HIER kies je welke PP's je wil

PP_names = PP_names(PP_select);
n_PP = length(PP_names);
n_PP = length(PP_names);

%% =======================
% OPSLAG ARRAYS
% =======================
all_Ca2_fit   = zeros(n_PP,300);
all_CaVol_fit = zeros(n_PP,300);
all_CaMax_fit = zeros(n_PP,300);
all_CoT_fit = nan(n_PP,300);

x_fit = linspace(0, ...
    max(cellfun(@(x) max(x.Force_sorted), struct2cell(allPP))),300);

adapt_force_all = zeros(n_PP,2);

adapt_Ca2_all   = zeros(n_PP,2);
adapt_CaVol_all = zeros(n_PP,2);
adapt_CaMax_all = zeros(n_PP,2);
adapt_CoT_all   = zeros(n_PP,2);

%% =======================
% LOOP OVER PARTICIPANTS
% =======================
for i = 1:n_PP

    PP = allPP.(PP_names{i});

    force_i = PP.Force_sorted(:);

    Ca2_i   = [1, PP.Ca2_force];
    CaVol_i = [1, PP.CaVol_force];
    CaMax_i = [1, PP.CaMax_force];

    CoT_i   = PP.CoT_sorted(:);

    % =========================
    % POLYNOMIAL FITS
    % =========================
    all_Ca2_fit(i,:)   = polyval(polyfit(force_i,Ca2_i,2),x_fit);

    all_CaVol_fit(i,:) = polyval(polyfit(force_i,CaVol_i,2),x_fit);

    all_CaMax_fit(i,:) = polyval(polyfit(force_i,CaMax_i,2),x_fit);

    % =========================
    % ADAPTATION DATA
    % =========================
    adapt_force_all(i,:) = ...
        [PP.Force_adapt1, PP.Force_adapt2];

    adapt_Ca2_all(i,:) = ...
        [PP.Ca2_adapt1, PP.Ca2_adapt2];

    adapt_CaVol_all(i,:) = ...
        [PP.CaVol_adapt1, PP.CaVol_adapt2];

    adapt_CaMax_all(i,:) = ...
        [PP.CaMax_adapt1, PP.CaMax_adapt2];

    adapt_CoT_all(i,:) = ...
        [PP.CoT_adapt1, PP.CoT_adapt2];

end

%% =======================
% GROUP MEANS
% =======================
adapt_force_mean = mean(adapt_force_all,1);

adapt_Ca2_mean   = mean(adapt_Ca2_all,1);
adapt_CaVol_mean = mean(adapt_CaVol_all,1);
adapt_CaMax_mean = mean(adapt_CaMax_all,1);
adapt_CoT_mean   = mean(adapt_CoT_all,1);

%% =======================
% MEAN + STD FITS
% =======================
Ca2_fit_mean   = mean(all_Ca2_fit,1);
Ca2_fit_std    = std(all_Ca2_fit,0,1);

CaVol_fit_mean = mean(all_CaVol_fit,1);
CaVol_fit_std  = std(all_CaVol_fit,0,1);

CaMax_fit_mean = mean(all_CaMax_fit,1);
CaMax_fit_std  = std(all_CaMax_fit,0,1);

%% =======================
% CoT GROUP MEAN
% GEEN FIT -> echte data
% =======================
all_force_raw = [];
all_CoT_raw   = [];

for i = 1:n_PP

    PP = allPP.(PP_names{i});

    all_force_raw = [all_force_raw; PP.Force_sorted(:)];
    all_CoT_raw   = [all_CoT_raw; PP.CoT_sorted(:)];

end

unique_forces = unique(all_force_raw);

CoT_mean = zeros(size(unique_forces));
CoT_std  = zeros(size(unique_forces));

for j = 1:length(unique_forces)

    idx_force = all_force_raw == unique_forces(j);

    CoT_mean(j) = mean(all_CoT_raw(idx_force));
    CoT_std(j)  = std(all_CoT_raw(idx_force));

end


%% =======================
% DISTANCE TO OPTIMUM
% =======================
metrics = {'Ca2','CaVol','CaMax','CoT'};

dist_to_min = struct();

for m = 1:length(metrics)

    dist_to_min.(metrics{m}).adapt1 = zeros(n_PP,1);
    dist_to_min.(metrics{m}).adapt2 = zeros(n_PP,1);
    dist_to_min.(metrics{m}).opt_force = zeros(n_PP,1);

end

for i = 1:n_PP

    %% =====================
    % Ca2
    % =====================
    [~,idx] = min(all_Ca2_fit(i,:));

    x_opt = x_fit(idx);

    dist_to_min.Ca2.opt_force(i) = x_opt;

    dist_to_min.Ca2.adapt1(i) = ...
        abs(adapt_force_all(i,1) - x_opt);

    dist_to_min.Ca2.adapt2(i) = ...
        abs(adapt_force_all(i,2) - x_opt);

    %% =====================
    % CaVol
    % =====================
    [~,idx] = min(all_CaVol_fit(i,:));

    x_opt = x_fit(idx);

    dist_to_min.CaVol.opt_force(i) = x_opt;

    dist_to_min.CaVol.adapt1(i) = ...
        abs(adapt_force_all(i,1) - x_opt);

    dist_to_min.CaVol.adapt2(i) = ...
        abs(adapt_force_all(i,2) - x_opt);

    %% =====================
    % CaMax
    % =====================
    [~,idx] = min(all_CaMax_fit(i,:));

    x_opt = x_fit(idx);

    dist_to_min.CaMax.opt_force(i) = x_opt;

    dist_to_min.CaMax.adapt1(i) = ...
        abs(adapt_force_all(i,1) - x_opt);

    dist_to_min.CaMax.adapt2(i) = ...
        abs(adapt_force_all(i,2) - x_opt);

    %% =====================
    % CoT
    % ECHT MINIMUM DATAPUNT
    % =====================
    force_i = allPP.(PP_names{i}).Force_sorted(:);
    CoT_i   = allPP.(PP_names{i}).CoT_sorted(:);

    [~,idx_min] = min(CoT_i);

    x_opt = force_i(idx_min);

    dist_to_min.CoT.opt_force(i) = x_opt;

    dist_to_min.CoT.adapt1(i) = ...
        abs(adapt_force_all(i,1) - x_opt);

    dist_to_min.CoT.adapt2(i) = ...
        abs(adapt_force_all(i,2) - x_opt);

end





%% =======================
% TWO SUBPLOTS: ADAPTATION PHASE 1 & 2
% =======================

figure('Name','Distance to optimal cost','NumberTitle','off');
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

colors = lines(n_PP);


nexttile;
hold on; grid on;

Ca2_vals = dist_to_min.Ca2.adapt1;
CoT_vals = dist_to_min.CoT.adapt1;

means1 = [mean(Ca2_vals), mean(CoT_vals)];
b1 = bar(means1, 'FaceAlpha', 0.4);
b1.DisplayName = 'Group mean';

for i = 1:n_PP
    
    jitter = 0.04;
    x1 = 1 + (rand-0.5)*jitter;
    x2 = 2 + (rand-0.5)*jitter;
    
    plot(x1, Ca2_vals(i), 'o', ...
        'Color', colors(i,:), ...
        'MarkerFaceColor', colors(i,:), ...
        'MarkerSize', 7, ...
        'DisplayName', PP_names{i});
    
    plot(x2, CoT_vals(i), 'o', ...
        'Color', colors(i,:), ...
        'MarkerFaceColor', colors(i,:), ...
        'MarkerSize', 7, ...
        'HandleVisibility','off');
    
    plot([x1 x2], [Ca2_vals(i) CoT_vals(i)], ...
        '-', 'Color', colors(i,:), ...
        'LineWidth', 2, ...
        'HandleVisibility','off');
end

xlim([0.5 2.5]);
xticks([1 2]);
xticklabels({'Ca^{2}', 'CoT'});

ylabel('dF (N/kg)', 'FontSize', 15);
title('Pre-exploration', 'FontSize', 16);

set(gca, 'FontSize', 14);

legend('Location','bestoutside', 'FontSize', 12);


nexttile;
hold on; grid on;

Ca2_vals = dist_to_min.Ca2.adapt2;
CoT_vals = dist_to_min.CoT.adapt2;

means2 = [mean(Ca2_vals), mean(CoT_vals)];
b2 = bar(means2, 'FaceAlpha', 0.4);
b2.DisplayName = 'Group mean';

for i = 1:n_PP
    
    jitter = 0.04;
    x1 = 1 + (rand-0.5)*jitter;
    x2 = 2 + (rand-0.5)*jitter;
    
    plot(x1, Ca2_vals(i), 'o', ...
        'Color', colors(i,:), ...
        'MarkerFaceColor', colors(i,:), ...
        'MarkerSize', 7, ...
        'DisplayName', PP_names{i});
    
    plot(x2, CoT_vals(i), 'o', ...
        'Color', colors(i,:), ...
        'MarkerFaceColor', colors(i,:), ...
        'MarkerSize', 7, ...
        'HandleVisibility','off');
    
    plot([x1 x2], [Ca2_vals(i) CoT_vals(i)], ...
        '-', 'Color', colors(i,:), ...
        'LineWidth', 2, ...
        'HandleVisibility','off');
end

xlim([0.5 2.5]);
xticks([1 2]);
xticklabels({'Ca^{2}', 'CoT'});

ylabel('dF (N/kg)', 'FontSize', 15);
title('Post-exploration', 'FontSize', 16);

set(gca, 'FontSize', 14);

legend('Location','bestoutside', 'FontSize', 12);


%% =======================
% STATISTICAL ANALYSIS
% =======================
%=============
% 1. Paired t-tests: Ca2 vs CoT within each adaptation phase
% =======================

fprintf('\n=== PAIRED T-TESTS: Ca2 vs CoT ===\n');

% Adaptation 1
[~, p_Ca2_CoT_adapt1, ~, stats1] = ttest(dist_to_min.Ca2.adapt1, ...
                                          dist_to_min.CoT.adapt1);

fprintf('Adaptation 1: p = %.4f, t(%d) = %.3f\n', ...
    p_Ca2_CoT_adapt1, stats1.df, stats1.tstat);

% Adaptation 2
[~, p_Ca2_CoT_adapt2, ~, stats2] = ttest(dist_to_min.Ca2.adapt2, ...
                                          dist_to_min.CoT.adapt2);

fprintf('Adaptation 2: p = %.4f, t(%d) = %.3f\n', ...
    p_Ca2_CoT_adapt2, stats2.df, stats2.tstat);


% =======================
% 2. Paired t-tests: Adaptation 1 vs 2 (within metric)
% =======================

fprintf('\n=== PAIRED T-TESTS: Adaptation 1 vs 2 ===\n');

metrics = {'Ca2','CaVol','CaMax','CoT'};

for m = 1:length(metrics)
    
    metric = metrics{m};
    
    data1 = dist_to_min.(metric).adapt1;
    data2 = dist_to_min.(metric).adapt2;
    
    [~, p, ~, stats] = ttest(data1, data2);
    
    fprintf('%s: p = %.4f, t(%d) = %.3f\n', ...
        metric, p, stats.df, stats.tstat);
end


% =======================
% 3. Effect sizes (Cohen's d for paired samples)
% =======================

fprintf('\n=== EFFECT SIZES (Cohen''s d) ===\n');

% Function for paired Cohen's d
cohens_d_paired = @(x,y) mean(x-y) / std(x-y);

% Adaptation 1 Ca2 vs CoT
d1 = cohens_d_paired(dist_to_min.Ca2.adapt1, dist_to_min.CoT.adapt1);

% Adaptation 2 Ca2 vs CoT
d2 = cohens_d_paired(dist_to_min.Ca2.adapt2, dist_to_min.CoT.adapt2);

fprintf('Adapt1 Ca2 vs CoT: d = %.3f\n', d1);
fprintf('Adapt2 Ca2 vs CoT: d = %.3f\n', d2);


% =======================
% 4. Descriptive statistics summary
% =======================

fprintf('\n=== DESCRIPTIVE STATS (mean ± SD) ===\n');

for m = 1:length(metrics)
    
    metric = metrics{m};
    
    fprintf('\n%s:\n', metric);
    
    fprintf('  Adapt1: %.3f ± %.3f\n', ...
        mean(dist_to_min.(metric).adapt1), ...
        std(dist_to_min.(metric).adapt1));
    
    fprintf('  Adapt2: %.3f ± %.3f\n', ...
        mean(dist_to_min.(metric).adapt2), ...
        std(dist_to_min.(metric).adapt2));
end

%% =======================
% Cost landscapes
% rows = participants
% cols = metrics
% =======================

metricNames = {'Ca2','CaVol','CaMax','CoT'};
nMetrics = 4;

colors = lines(n_PP);

figure('Name','PP Cost Landscapes','NumberTitle','off');

tiledlayout(n_PP, nMetrics, 'TileSpacing','compact','Padding','compact');

set(gcf,'DefaultAxesFontSize',16);
set(gcf,'DefaultTextFontSize',16);

for i = 1:n_PP
    
    PP = allPP.(PP_names{i});
    force_i = PP.Force_sorted(:);
    
    for m = 1:nMetrics
        
        nexttile;
        set(gca,'LineWidth',1.2);
        hold on; grid on;
        
        metric = metricNames{m};
        
        % =========================
        % SELECT DATA
        % =========================
        switch metric
            
            case 'Ca2'
                raw_y = [1, PP.Ca2_force];
                adapt_y = adapt_Ca2_all(i,:);
                
            case 'CaVol'
                raw_y = [1, PP.CaVol_force];
                adapt_y = adapt_CaVol_all(i,:);
                
            case 'CaMax'
                raw_y = [1, PP.CaMax_force];
                adapt_y = adapt_CaMax_all(i,:);
                
            case 'CoT'
                raw_y = PP.CoT_sorted;
                adapt_y = adapt_CoT_all(i,:);
        end
        
        raw_y = raw_y(:);
        
        % =========================
        % ALIGN LENGTH
        % =========================
        minLen = min(length(force_i), length(raw_y));
        f = force_i(1:minLen);
        y = raw_y(1:minLen);
        
        % =========================
        % PLOT RAW DATA
        % =========================
        scatter(f, y, 25, ...
            'filled', ...
            'MarkerFaceColor', colors(i,:), ...
            'MarkerFaceAlpha', 0.25, ...
            'HandleVisibility','off');
        
        % =========================
        % CURVE + OPTIMUM
        % =========================
        if strcmp(metric,'CoT')
            
            % ===== SORTED RAW ONLY (NO LINE) =====
            [fs, idx] = sort(f);
            ys = y(idx);
            
            % alleen punten
            scatter(fs, ys, 30, ...
                'filled', ...
                'MarkerFaceColor', colors(i,:), ...
                'MarkerEdgeColor', 'none', ...
                'MarkerFaceAlpha', 1, ...
                'HandleVisibility','off');
            
            % minimum datapunt
            [y_opt, idx_min] = min(ys);
            x_opt = fs(idx_min);
            
        else
            
            % ===== POLY FIT =====
            p = polyfit(f, y, 2);
            
            x_fit_local = linspace(min(f), max(f), 150);
            y_fit_local = polyval(p, x_fit_local);
            
            % =========================
            % RESIDUALS → CI
            % =========================
            y_pred = polyval(p, f);
            res = y - y_pred;
            
            sigma = std(res, 'omitnan');
            ci = 1.96 * sigma;
            
            upper = y_fit_local + ci;
            lower = y_fit_local - ci;
            
            % =========================
            % PLOT CI BAND
            % =========================
            fill([x_fit_local fliplr(x_fit_local)], ...
                 [upper fliplr(lower)], ...
                 colors(i,:), ...
                 'FaceAlpha',0.12, ...
                 'EdgeColor','none', ...
                 'HandleVisibility','off');
            
            % =========================
            % PLOT FIT LINE
            % =========================
            plot(x_fit_local, y_fit_local, ...
                'Color', colors(i,:), ...
                'LineWidth', 2, ...
                'HandleVisibility','off');
            
            % =========================
            % OPTIMUM
            % =========================
            [y_opt, idx_min] = min(y_fit_local);
            x_opt = x_fit_local(idx_min);
        end
        
        % =========================
        % OPTIMUM MARKER
        % =========================
        h_min = plot(x_opt, y_opt, 'k^', ...
            'MarkerFaceColor','k', ...
            'MarkerSize',7);
        
   % =========================
% ADAPTATION POINTS
% =========================

% PRE-EXPLORATION = RED CIRCLE
h_pre = plot(adapt_force_all(i,1), adapt_y(1), 'o', ...
    'Color', 'r', ...
    'MarkerFaceColor', 'r', ...
    'MarkerSize',7);

% POST-EXPLORATION = RED SQUARE
h_post = plot(adapt_force_all(i,2), adapt_y(2), 's', ...
    'Color', 'r', ...
    'MarkerFaceColor', 'r', ...
    'MarkerSize',7);
        
        % =========================
        % TITLES ONLY ON TOP ROW
        % =========================
        if i == 1
            title(metric,'FontSize',18);
        end
        
        % =========================
        % LABELS ONLY LEFT COLUMN
        % =========================
        if m == 1
            ylabel(PP_names{i}, ...
                'Interpreter','none', ...
                'FontSize',16);
        end
        
if m == 4

    ylabel('CoT(kJ kg^{-1} m^{-1})', ...
        'FontSize',10);
end

        if i == n_PP
            xlabel('Force (N/kg)','FontSize',16);
        end
        
    end
end

% =========================
% GLOBAL LEGEND
% =========================
lgd = legend([h_min h_pre h_post], ...
    {'Minimum','Pre-exploration','Post-exploration'}, ...
    'Orientation','horizontal', ...
    'FontSize',15);

lgd.Layout.Tile = 'south';



%% =======================
% ADAPTATION 1 vs 2 DIFFERENCES (Ca2 & CoT)
% =======================

fprintf('\n=== ADAPTATION 1 vs 2 DIFFERENCES ===\n');

% =======================
% Ca2
% =======================
diff_Ca2 = dist_to_min.Ca2.adapt1 - dist_to_min.Ca2.adapt2;

mean_diff_Ca2 = mean(diff_Ca2);
sd_diff_Ca2   = std(diff_Ca2);

[~, p_Ca2, ~, stats_Ca2] = ttest(dist_to_min.Ca2.adapt1, ...
                                 dist_to_min.Ca2.adapt2);

fprintf('\nCa2:\n');
fprintf('Adapt1 - Adapt2: %.4f ± %.4f\n', mean_diff_Ca2, sd_diff_Ca2);
fprintf('t(%d) = %.3f, p = %.4f\n', ...
    stats_Ca2.df, stats_Ca2.tstat, p_Ca2);

% =======================
% CoT
% =======================
diff_CoT = dist_to_min.CoT.adapt1 - dist_to_min.CoT.adapt2;

mean_diff_CoT = mean(diff_CoT);
sd_diff_CoT   = std(diff_CoT);

[~, p_CoT, ~, stats_CoT] = ttest(dist_to_min.CoT.adapt1, ...
                                  dist_to_min.CoT.adapt2);

fprintf('\nCoT:\n');
fprintf('Adapt1 - Adapt2: %.4f ± %.4f\n', mean_diff_CoT, sd_diff_CoT);
fprintf('t(%d) = %.3f, p = %.4f\n', ...
    stats_CoT.df, stats_CoT.tstat, p_CoT);

%% =======================
%DIFFERENCE Ca2 vs CoT + ADAPT 1 vs 2 COMPARISON
% =======================

fprintf('\n=== DIFFERENCE Ca² vs CoT (paired) ===\n');

% =======================
% Adaptation 1
% =======================
diff1 = dist_to_min.Ca2.adapt1 - dist_to_min.CoT.adapt1;

mean_diff1 = mean(diff1);
sd_diff1   = std(diff1);

fprintf('Adaptation 1 (Ca² - CoT): %.4f ± %.4f\n', ...
    mean_diff1, sd_diff1);

% =======================
% Adaptation 2
% =======================
diff2 = dist_to_min.Ca2.adapt2 - dist_to_min.CoT.adapt2;

mean_diff2 = mean(diff2);
sd_diff2   = std(diff2);

fprintf('Adaptation 2 (Ca² - CoT): %.4f ± %.4f\n', ...
    mean_diff2, sd_diff2);

%% =======================
% CHANGE BETWEEN ADAPT 1 AND 2
% =======================

fprintf('\n=== CHANGE BETWEEN ADAPTATION PHASES ===\n');

% Ca² change
delta_Ca = dist_to_min.Ca2.adapt2 - dist_to_min.Ca2.adapt1;

mean_delta_Ca = mean(delta_Ca);
sd_delta_Ca   = std(delta_Ca);

fprintf('Ca² (Adapt2 - Adapt1): %.4f ± %.4f\n', ...
    mean_delta_Ca, sd_delta_Ca);

% CoT change
delta_CoT = dist_to_min.CoT.adapt2 - dist_to_min.CoT.adapt1;

mean_delta_CoT = mean(delta_CoT);
sd_delta_CoT   = std(delta_CoT);

fprintf('CoT (Adapt2 - Adapt1): %.4f ± %.4f\n', ...
    mean_delta_CoT, sd_delta_CoT);




%% =======================
% GROUP MUSCLE ACTIVATION PLOTS
% Mean across participants + individual PP points
% =======================
muscle_fields = { ...
    'BicepsFemoris_force', ...
    'Gastrocnemius_force', ...
    'Soleus_force', ...
    'TibialisAnterior_force', ...
    'VastusMedialis_force'};
muscle_titles = { ...
    'Biceps femoris', ...
    'Gastrocnemius medialis', ...
    'Soleus', ...
    'Tibialis anterior', ...
    'Vastus medialis'};
trial_labels = { ...
    '20%', ...
    '40%', ...
    '60%', ...
    '80%', ...
    '100%', ...
    'Adapt 1', ...
    'Adapt 2'};

nMuscles  = length(muscle_fields);
nTrials   = length(trial_labels);
force_idx = 1:5;   % only connect the 20%-100% bars with a line

figure('Name','Group muscle activations','NumberTitle','off');
tiledlayout(3,2,'TileSpacing','compact','Padding','compact');

for m = 1:nMuscles
    % =========================
    % COLLECT DATA
    % =========================
    muscle_data = zeros(n_PP, nTrials);
    for i = 1:n_PP
        PP = allPP.(PP_names{i});
        force_vals = PP.(muscle_fields{m})(:);
        switch muscle_fields{m}
            case 'BicepsFemoris_force'
                adapt_vals = [PP.BicepsFemoris_adapt1, PP.BicepsFemoris_adapt2];
            case 'Gastrocnemius_force'
                adapt_vals = [PP.Gastrocnemius_adapt1, PP.Gastrocnemius_adapt2];
            case 'Soleus_force'
                adapt_vals = [PP.Soleus_adapt1, PP.Soleus_adapt2];
            case 'TibialisAnterior_force'
                adapt_vals = [PP.TibialisAnterior_adapt1, PP.TibialisAnterior_adapt2];
            case 'VastusMedialis_force'
                adapt_vals = [PP.VastusMedialis_adapt1, PP.VastusMedialis_adapt2];
        end
        muscle_data(i,:) = [force_vals(:)' adapt_vals(:)'];
    end

    % =========================
    % MEAN ONLY
    % =========================
    mean_vals = mean(muscle_data, 1, 'omitnan');

    % =========================
    % PLOT
    % =========================
    nexttile;
    hold on; grid on;

    % Mean bar (excluded from legend)
    b = bar(mean_vals, 'FaceAlpha', 0.7);
    b.Annotation.LegendInformation.IconDisplayStyle = 'off';

    % Get color order before plotting PP
    colors = get(gca, 'ColorOrder');

    % Individual PP points + line only between 20%-100%
    for i = 1:n_PP
        c = colors(mod(i-1, size(colors,1))+1, :);

        % line only through force conditions (1:5)
        plot(force_idx, muscle_data(i, force_idx), ...
            '-', ...
            'Color', c, ...
            'LineWidth', 1.2, ...
            'HandleVisibility', 'off');

        % dots for all conditions (1:7)
        plot(1:nTrials, muscle_data(i,:), ...
            '.', ...
            'MarkerSize', 20, ...
            'Color', c, ...
            'DisplayName', PP_names{i});
    end

    xticks(1:nTrials);
    xticklabels(trial_labels);
    xtickangle(45);
    ylabel('A_i', 'FontSize', 14);
    title(muscle_titles{m});
    ylim([0 max(max(muscle_data))*1.2]);
    legend('Location', 'northwest', 'FontSize', 10);

    set(gca, ...
        'FontSize', 15, ...
        'LineWidth', 1);
end
%% =======================
% SIGNED DEVIATION - ADAPT 1 vs ADAPT 2 (1 FIGUUR)
% =======================

figure('Name','Signed deviation Ca2 vs CoT','NumberTitle','off');
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

colors = lines(n_PP);

for phase = 1:2
    
    nexttile;
    hold on; grid on;
    
    if phase == 1
        adapt_label = 'Pre-exploration';
        adapt_idx = 1;
    else
        adapt_label = 'Post-exploration';
        adapt_idx = 2;
    end
    
    dev_Ca2 = zeros(n_PP,1);
    dev_CoT = zeros(n_PP,1);
    
    for i = 1:n_PP
        
        opt_Ca2 = dist_to_min.Ca2.opt_force(i);
        opt_CoT = dist_to_min.CoT.opt_force(i);
        
        dev_Ca2(i) = adapt_force_all(i,adapt_idx) - opt_Ca2;
        dev_CoT(i) = adapt_force_all(i,adapt_idx) - opt_CoT;
    end
    
    % ===== GROUP MEAN BAR =====
    b = bar([mean(dev_Ca2), mean(dev_CoT)], 'FaceAlpha', 0.4);
    b.DisplayName = 'Mean';
    
    % ===== INDIVIDUAL POINTS =====
    hPP = gobjects(n_PP,1); % voor legend handling
    
    for i = 1:n_PP
        
        jitter = 0.04;
        x1 = 1 + (rand-0.5)*jitter;
        x2 = 2 + (rand-0.5)*jitter;
        
        hPP(i) = plot(x1, dev_Ca2(i), 'o', ...
            'Color', colors(i,:), ...
            'MarkerFaceColor', colors(i,:), ...
            'MarkerSize', 7, ...
            'DisplayName', PP_names{i});
        
        plot(x2, dev_CoT(i), 'o', ...
            'Color', colors(i,:), ...
            'MarkerFaceColor', colors(i,:), ...
            'MarkerSize', 7, ...
            'HandleVisibility','off');
        
        plot([x1 x2], [dev_Ca2(i) dev_CoT(i)], ...
            '-', 'Color', colors(i,:), ...
            'LineWidth', 2, ...
            'HandleVisibility','off');
    end
    
    xlim([0.5 2.5]);
    xticks([1 2]);
    xticklabels({'Ca^{2}','CoT'});
    
    yline(0,'k--');
    
    ylabel('\Delta Force (N/kg)');
    title(adapt_label);
    
    set(gca,'FontSize',16);
    
    % ===== LEGEND FIX =====
    if phase == 2
        legend([b; hPP], ['Mean'; PP_names(:)], 'Location','bestoutside');
    end
end





%% =======================
% INDIVIDUAL MUSCLE ACTIVATION PLOTS
% Rows = participants
% Columns = muscles
% =======================

muscle_fields = { ...
    'BicepsFemoris_force', ...
    'Gastrocnemius_force', ...
    'Soleus_force', ...
    'TibialisAnterior_force', ...
    'VastusMedialis_force'};

muscle_titles = { ...
    'Biceps femoris', ...
    'Gastrocnemius', ...
    'Soleus', ...
    'Tibialis anterior', ...
    'Vastus medialis'};

trial_labels = { ...
    '20%', ...
    '40%', ...
    '60%', ...
    '80%', ...
    '100%', ...
    'Pre', ...
    'Post'};

nMuscles = length(muscle_fields);

figure('Name','Individual Muscle Activations', ...
       'NumberTitle','off', ...
       'Color','w');

tiledlayout(n_PP, nMuscles, ...
    'TileSpacing','compact', ...
    'Padding','compact');

for i = 1:n_PP
    
    PP = allPP.(PP_names{i});
    
    for m = 1:nMuscles
        
        % =========================
        % GET FORCE VALUES
        % =========================
        force_vals = PP.(muscle_fields{m})(:);
        
        % =========================
        % GET ADAPT VALUES
        % =========================
        switch muscle_fields{m}
            
            case 'BicepsFemoris_force'
                adapt_vals = [PP.BicepsFemoris_adapt1, ...
                              PP.BicepsFemoris_adapt2];
                
            case 'Gastrocnemius_force'
                adapt_vals = [PP.Gastrocnemius_adapt1, ...
                              PP.Gastrocnemius_adapt2];
                
            case 'Soleus_force'
                adapt_vals = [PP.Soleus_adapt1, ...
                              PP.Soleus_adapt2];
                
            case 'TibialisAnterior_force'
                adapt_vals = [PP.TibialisAnterior_adapt1, ...
                              PP.TibialisAnterior_adapt2];
                
            case 'VastusMedialis_force'
                adapt_vals = [PP.VastusMedialis_adapt1, ...
                              PP.VastusMedialis_adapt2];
        end
        
        % Combine all trials
        vals = [force_vals(:)' adapt_vals(:)'];
        
        % =========================
        % SUBPLOT
        % =========================
        nexttile;
        hold on;
        grid on;
        
        bar(vals, 'FaceAlpha',0.7);
        
  
        
        xticks(1:length(vals));
        xticklabels(trial_labels);
        xtickangle(45);
        
        ylim([0 max(vals)*1.2 + eps]);
        
        % =========================
        % TITLES
        % =========================
        
        % Top row = muscle titles
        if i == 1
            title(muscle_titles{m}, ...
                'FontSize',20, ...
                'FontWeight','bold');
        end
        
        % First column = participant labels
        if m == 1
            ylabel(PP_names{i}, ...
                'FontSize',18, ...
                'FontWeight','bold');
        end
        
        % Styling
        set(gca, ...
            'FontSize',14, ...
            'LineWidth',1.5);
        
    end
end


%% =======================
% RMSE / NRMSE PER PARTICIPANT & METRIC (ROBUST + PRINT)
% =======================

metrics = {'Ca2','CaVol','CaMax','CoT'};

rmse_all = struct();
nrmse_all = struct();

for m = 1:length(metrics)
    rmse_all.(metrics{m}) = zeros(n_PP,1);
    nrmse_all.(metrics{m}) = zeros(n_PP,1);
end

for i = 1:n_PP
    
    PP = allPP.(PP_names{i});
    f_base = PP.Force_sorted(:);
    
    %=======================
    % CA2 / CaVol / CaMax
    % =======================
   for m = 1:length(metrics)
        
        metric = metrics{m};
        
        % -----------------------
        % SELECT DATA
        % -----------------------
        switch metric
            case 'Ca2'
                y = PP.Ca2_force(:);
            case 'CaVol'
                y = PP.CaVol_force(:);
            case 'CaMax'
                y = PP.CaMax_force(:);
            case 'CoT'
                y = PP.CoT_sorted(:);
        end
        
        % -----------------------
        % ALIGN LENGTH
        % -----------------------
        minLen = min(length(f_base), length(y));
        f = f_base(1:minLen);
        y = y(1:minLen);
        
        % -----------------------
        % FIT (ALWAYS QUADRATIC)
        % -----------------------
        p = polyfit(f, y, 2);
        y_pred = polyval(p, f);
        
        % -----------------------
        % RMSE
        % -----------------------
        err = y - y_pred;
        rmse = sqrt(mean(err.^2));
        
        rmse_all.(metric)(i) = rmse;
        
        % -----------------------
        % NRMSE
        % -----------------------
        nrmse_all.(metric)(i) = rmse / range(y);
    end
    
    % =======================
    % CoT (no model)
    % =======================
    y = PP.CoT_sorted(:);
    
    minLen = min(length(f_base), length(y));
    y = y(1:minLen);
    
    err = y - mean(y);
    
    rmse = sqrt(mean(err.^2));
    
    rmse_all.CoT(i) = rmse;
    nrmse_all.CoT(i) = rmse / range(y);
end


%=======================
% PRINT RMSE
% =======================

fprintf('\n=====================================\n');
fprintf('RMSE SUMMARY (MEAN ± SD)\n');
fprintf('=====================================\n');

for m = 1:length(metrics)
    metric = metrics{m};
    
    vals = rmse_all.(metric);
    nvals = nrmse_all.(metric);
    
    fprintf('%s:\n', metric);
    fprintf('  RMSE  : %.4f ± %.4f\n', mean(vals), std(vals));
    fprintf('  NRMSE : %.4f ± %.4f\n', mean(nvals), std(nvals));
end


grid on;
