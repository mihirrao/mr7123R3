%% parent directory
parent = "../Princeton Courses/WRI121/R3_data/";

%% national trends

%% V_sold estimate
national = readtable(parent + "NationalTotalAndSubcategory.xlsx");
% filter by product subcategory
subcategories = ["Regular meat fresh/frozen", "Poultry fresh/frozen", "Regular meat canned", "Regular meat fresh/frozen"];
rows = contains(national.Subcategory, subcategories);
national = national(rows, 1:end);
% compute timestamps and volume totals
get_date = @(date_string) datetime(date_string, 'InputFormat','yyyy-MM-dd');
t_0 = get_date(national.Date(1));
n = length(national.Date);
num_unique = length(unique(national.Date));
t = zeros(1, num_unique); % years
total = zeros(1, num_unique); % volume equivalent units
for i=1:num_unique
    start = (i-1)*(n/num_unique)+1;
    total(i) = sum(national.VolumeSales(start:start+length(subcategories)-1));
    t(i) = yearfrac(t_0, get_date(national.Date(start)));
end
% plot volume total over time w/ fit
figure()
hold on
% filtered data
f1 = plot(t, total, "k.-", "LineWidth", 1.5, "DisplayName", "Filtered USDA ERS Data");
f1.Color(4) = 0.15;
% observed annual seasonality
xline([0.25, 1.25, 2.25, 3.25], "r--", "LineWidth", 2);
% identify and plot mid-cycle data subset for linear fit
mid_start = 0.75; mid_end = 1;
t1 = (t >= mid_start).*(t <= mid_end);
t2 = (t >= 1 + mid_start).*(t <= 1 + mid_end);
t3 = (t >= 2 + mid_start).*(t <= 2 + mid_end);
indices = (t1 + t2 + t3) == 1;
t_subset = t(indices);
total_subset = total(indices);
f2 = plot(t_subset, total_subset, "ro", "LineWidth", 1, "DisplayName", "Mid-Cycle Stability");
% linear fit
ft = fittype("poly1");
[x, y] = prepareCurveData(t_subset, total_subset);
[VSold_model, VSold_gof] = fit(x, y, ft);
dxs = linspace(min(t), 3.5);
f3 = plot(dxs, VSold_model(dxs), "b-", "LineWidth", 1.5, "DisplayName", "V_{sold} Estimate: " + sprintf('%10e', round(VSold_model.p1, 3)) + "\times t + " + sprintf('%10e', round(VSold_model.p2, 3)));
VSold_model
VSold_gof
Vsold_projection95 = predint(VSold_model, dxs, 0.95);
f4 = plot(dxs, Vsold_projection95(1:end,1), "b-", "LineWidth", 1.5, "DisplayName", "V_{sold} 95% Confidence Band (Lower)");
f4.Color(4) = 0.2;
f5 = plot(dxs, Vsold_projection95(1:end,2), "b--", "LineWidth", 1.5, "DisplayName", "V_{sold} 95% Confidence Band (Upper)");
f5.Color(4) = 0.2;
hold off
grid on
grid minor
legend([f1, f2, f3, f4, f5], "Location", "northeast", "FontSize", 15);
xlabel("Time Since October 6, 2019 (Years)", "FontSize", 15);
ylabel("Total Retail Volume Sold (Linearly Combined Unit)", "FontSize", 15);

%% PCA estimate
pca = readtable(parent + "mtpcc.xlsx");
year_start = pca.Year(1);
t = pca.Year(1:end) - year_start; % years since 1909
beef = pca.Beef(1:end);
veal = pca.Veal(1:end);
pork = pca.Pork(1:end);
lamb = pca.Lamb(1:end);
chicken = pca.Chicken(1:end);
total = pca.Total(1:end);
% plot data series
figure()
hold on
f1 = plot(t, beef, "LineWidth", 1.5, "DisplayName", "Beef");
f2 = plot(t, veal, "LineWidth", 1.5, "DisplayName", "Veal");
f3 = plot(t, pork, "LineWidth", 1.5, "DisplayName", "Pork");
f4 = plot(t, lamb, "LineWidth", 1.5, "DisplayName", "Lamb");
f5 = plot(t, chicken, "LineWidth", 1.5, "DisplayName", "Chicken");
f6 = plot(t, total, "b-", "LineWidth", 1.5, "DisplayName", "Total");
% plot fit of total availability over time
ft = fittype("poly1");
[x, y] = prepareCurveData(t, total);
[PCA_model, PCA_gof] = fit(x, y, ft);
dxs = linspace(min(t), 120);
f7 = plot(dxs, PCA_model(dxs), "k-", "LineWidth", 1.5, "DisplayName", "PCA Estimate: " + PCA_model.p1 + "\times t + " + PCA_model.p2);
PCA_model
PCA_gof
PCA_projection95 = predint(PCA_model, dxs, 0.95);
f8 = plot(dxs, PCA_projection95(1:end,1), "k-", "LineWidth", 1.5, "DisplayName", "PCA 95% Confidence Band (Lower)");
f8.Color(4) = 0.2;
f9 = plot(dxs, PCA_projection95(1:end,2), "k--", "LineWidth", 1.5, "DisplayName", "PCA 95% Confidence Band (Upper)");
f9.Color(4) = 0.2;
hold off
grid on
grid minor
legend("Location", "southoutside", "FontSize", 15, 'Orientation','horizontal', 'NumColumns', 3);
xlabel("Time Since 1909 (Years)", "FontSize", 15);
ylabel("Per Capita Retail Volume Availability (lbs)", "FontSize", 15);

%% US Census population projection
popu = readtable(parent + "np2017_d1_mid.xlsx");
year_start = popu.YEAR(1);
t = popu.YEAR(1:45) - year_start; % years since 2016
population = popu.TOTAL_POP(1:45);
figure()
hold on
f1 = plot(t, population./1E6, "bo-", "LineWidth", 1.5, "DisplayName", "U.S. Census Data");
hold off
grid on
grid minor
legend("Location", "best", "FontSize", 15);
xlabel("Time Since 2016 (Years)", "FontSize", 15);
ylabel("Projected U.S. Population Size (millions of people)", "FontSize", 15);
% linear interpolation
ft = fittype("linearinterp");
[x, y] = prepareCurveData(t, population);
[popu_model, popu_gof] = fit(x, y, ft);

%% Overall national projection
years = 2018:2045;
Vsold_projection = VSold_model(years-2019);
PCA_projection = PCA_model(years-1909);
popu_projection = popu_model(years-2016);
k = 1;
Prop_meat = k .* Vsold_projection ./ (PCA_projection .* popu_projection);
k = 0.95/Prop_meat(1); % based on 2018 Gallup survey result
Prop_meat = k .* Prop_meat;
Prop_plant = 1- Prop_meat;
t = years - years(1);
% plots
figure()
hold on
f1 = plot(t, Prop_meat, "k-", "LineWidth", 1.5, "DisplayName", "Projected Prop_{meat}");
f2 = plot(t, Prop_plant, "b-", "LineWidth", 1.5, "DisplayName", "Projected Prop_{plant}");
f3 = yline(0.25, "r--", "LineWidth", 1.5, "DisplayName", "Centola et al. (2018) Critical Mass");
% compute 95% confidence bands
Vsold_projection95 = predint(VSold_model, years-2019, 0.95);
PCA_projection95 = predint(PCA_model, years-1909, 0.95);
popu_projection95 = [popu_projection, popu_projection];
% lower
k = 1;
Prop_meat_lower = k .* Vsold_projection95(1:end, 1) ./ (PCA_projection95(1:end, 2) .* popu_projection95(1:end, 2));
k = 0.95/Prop_meat_lower(1);
Prop_meat_lower = k .* Prop_meat_lower;
Prop_plant_upper = 1 - Prop_meat_lower;
% upper
k = 1;
Prop_meat_upper = k .* Vsold_projection95(1:end, 2) ./ (PCA_projection95(1:end, 1) .* popu_projection95(1:end, 1));
k = 0.95/Prop_meat_upper(1);
Prop_meat_upper = k .* Prop_meat_upper;
Prop_plant_lower = 1 - Prop_meat_upper;
% plot confidence bands
f4 = plot(t, Prop_meat_lower, "k-", "LineWidth", 1.5, "DisplayName", "Projected Prop_{meat} 95% Confidence Band (Lower)");
f5 = plot(t, Prop_meat_upper, "k--", "LineWidth", 1.5, "DisplayName", "Projected Prop_{meat} 95% Confidence Band (Upper)");
f6 = plot(t, Prop_plant_lower, "b-", "LineWidth", 1.5, "DisplayName", "Projected Prop_{plant} 95% Confidence Band (Lower)");
f7 = plot(t, Prop_plant_upper, "b--", "LineWidth", 1.5, "DisplayName", "Projected Prop_{plant} 95% Confidence Band (Upper)");
f4.Color(4) = 0.2; f5.Color(4) = 0.2; f6.Color(4) = 0.2; f7.Color(4) = 0.2; 
hold off
grid on
grid minor
legend([f1, f4, f5, f2, f6, f7, f3], "Location", "southoutside", "FontSize", 15, "NumColumns", 2);
xlabel("Time Since 2018 (Years)", "FontSize", 15);
ylabel("Proportion of U.S. Population", "FontSize", 15);
axis([0,length(years)-1,0,1])

%% demographic-specific trends

% state-independent pca
t = pca.Year(1:end) - year_start; % years since 1909
pca_total = pca.Total(1:end);
ft = fittype("poly1");
[x, y] = prepareCurveData(t, pca_total);
[pca_model, pca_gof] = fit(x, y, ft); % input years since 1909

% state volume data
state_data = readtable(parent + "StateAndCategory.xlsx");
rows = state_data.Category == "Meats, eggs, and nuts";
state_data = state_data(rows, 1:end);
states = unique(state_data.State);

% state population data
state_pop = readtable(parent + "nst-est2019-01.xlsx");

% store tipping point difference from national prediction
tips = zeros(1, length(states));

for i=1:length(states) % for each state
    % V_sold
    state_subset = state_data(contains(state_data.State, states(i)), 1:end);
    t_0 = get_date(state_subset.Date(1));
    n = length(state_subset.Date);
    t = zeros(1,n);
    total = zeros(1,n);
    for j=1:n
        t(j) = yearfrac(t_0, get_date(state_subset.Date(j)));
        total(j) = state_subset.VolumeSales(j);
    end
    % moving mean smoothing to enable automated data processing pipeline
    t = smoothdata(t, "movmean");
    total = smoothdata(total, "movmean");
    % linear volume fit
    ft = fittype("poly1");
    [x, y] = prepareCurveData(t, total);
    [volume_model, volume_gof] = fit(x, y, ft); % input years since t_0
    
    % popu
    row = state_pop(contains(state_pop.Var1, states(i)), 1:end);
    pop = table2array(row(1,2:end));
    t = 0:9; % years since 2010 for 2010-2019 (inclusive)
    ft = fittype("poly4");
    [x, y] = prepareCurveData(t, pop);
    [pop_model, pop_gof] = fit(x, y, ft); % input years since 2010

    % Prop_meat starting at 2018 for 2018-2045
    t = 0:27;
    k = 1;
    Prop_meat = k .* volume_model(yearfrac(t_0, 2018 + t)) ./ (pca_model((2018 + t)-1909) .* pop_model((2018 + t)-2010));
    k = 0.95/Prop_meat(1); % based on 2018 Gallup survey result
    Prop_meat = k .* Prop_meat;
    Prop_plant = 1 - Prop_meat;
    
    % compute tipping point year
    ft = fittype('poly4');
    [x, y] = prepareCurveData(Prop_plant, t);
    [model, gof] = fit(x, y, ft);
    if gof.rsquare > 0 % prevent invalid fits
        pred = model(0.25);
        if pred > 0 % eliminate bad predictions due to bad data
            tips(i) = pred;
        else
            tips(i) = NaN;
        end
    else
        tips(i) = NaN;
    end
end

% convert to year
tips= tips + 2018;

% eliminate nans
nan_rows = isnan(tips);
tips = tips(~nan_rows);

%% age demographic data
age_data = readtable(parent + "age.xlsx");
age_data = age_data(contains(age_data.state, states), 1:end);
age_data = age_data(~nan_rows,1:end);
median_age = age_data.MedianAge;
figure()
hold on
scatter(median_age, tips, "kx", "LineWidth", 1.5, "DisplayName", "Predicted Tipping Points");
% linear fit
ft = fittype("poly1");
[x, y] = prepareCurveData(median_age, tips);
[age_model, age_gof] = fit(x, y, ft)
dxs = linspace(30, 50, 100);
plot(dxs, age_model(dxs), "b-", "LineWidth", 1.5, "DisplayName", "Linear Fit: " + age_model.p1 + "x - " + abs(age_model.p2));
hold off
grid on
grid minor
xlabel("State Median Age (Years)", "FontSize", 15);
ylabel("Consumer Behavior Model Prediction", "FontSize", 15);
legend("Location", "southeast", "FontSize", 15);