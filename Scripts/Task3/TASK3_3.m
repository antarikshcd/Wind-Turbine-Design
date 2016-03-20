clear all
close all

% Load data for optimal radius
load('../Common/optimal_radius.mat');

% Add structure code folder to scripts path
addpath('functions');

% Linearly scaled turbine file name
turbine_file = ['../Common/SCALED_' num2str(R_optimal) 'm_2MW.mat'];

% Optimized turbine structure
optimized_turbine = load([turbine_file '_OPTIMIZED.mat']);

% Linearly scaled turbine structure
old_turbine = load([turbine_file]);
reference_turbine = load('../Common/NREL5MW.mat');
%load([turbine_file '_OPTIMIZED.mat']);

% Chord ratio from linearly scaled to optimized turbine
chord_ratio = optimized_turbine.Blade_Chord ./ old_turbine.Blade_Chord;

% Update the values of the structural properites of the turbine according
% to scaling laws.
optimized_turbine.Blade_Mass = old_turbine.Blade_Mass .* ...
    chord_ratio .^ 2;
optimized_turbine.Blade_EIflap = old_turbine.Blade_EIflap .* ...
    chord_ratio .^ 4;
optimized_turbine.Blade_EIedge = old_turbine.Blade_EIedge .* ...
    chord_ratio .^ 4;

% Compute stresses and deflections for the optimized and reference turbine
[optimized_turbine.u_y, optimized_turbine.u_z, optimized_turbine.My, ...
    optimized_turbine.Mz] = compute_structural_state( optimized_turbine, ...
    optimized_turbine.V_rated );
[reference_turbine.u_y, reference_turbine.u_z, reference_turbine.My, ...
    reference_turbine.Mz] = compute_structural_state( ...
    reference_turbine, 11.5 );

% Compute the stress ratio from the reference to the optimized turbine.
% The very last values are removed because moments become very low and the
% ratio becomes very high. At that points, however, stresses are usually
% low and geometry is constrained from technological reasons.
sigma_ratio_y = optimized_turbine.My(1: end - 5) ./ ...
    reference_turbine.My(1: end - 5) .* ...
    reference_turbine.Blade_EIedge(1: end - 5) ./ ...
    optimized_turbine.Blade_EIedge(1: end - 5) .* ...
    optimized_turbine.Blade_Chord(1: end - 5) ./ ...
    reference_turbine.Blade_Chord(1: end - 5); 
sigma_ratio_z = optimized_turbine.Mz(1: end - 5) ./ ...
    reference_turbine.Mz(1: end - 5) .* ...
    reference_turbine.Blade_EIflap(1: end - 5) ./ ...
    optimized_turbine.Blade_EIflap(1: end - 5) .* ...
    optimized_turbine.Blade_Chord(1: end - 5) ./ ...
    reference_turbine.Blade_Chord(1: end - 5); 

% Normalized radius for plots
r = optimized_turbine.Blade_Radius(1:end -5) /...
    optimized_turbine.Blade_Radius(end);

% Plot the values before the correction
figure
plot(r, sigma_ratio_y, r, sigma_ratio_z);
xlabel('Normalized radius [-]');
ylabel('Stress ratio [-]');
legend('Sigma ratio flap direction', 'Sigma ratio edge direction');
title('Stress ratio BEFORE the correction');

% Compute the initial mass of the blade
Initial_Blade_Total_Mass = trapz(optimized_turbine.Blade_Mass) * ...
    (optimized_turbine.Blade_Radius(2) - optimized_turbine.Blade_Radius(1)); 

% Use the higher stress value to resize the inertia.
Inertia_Adjust = max(sigma_ratio_y, sigma_ratio_z);

% Add some 1s at the end of the vector (we have removed them before because
% the moment was very low)
Inertia_Adjust = [Inertia_Adjust; ...
    ones(length(optimized_turbine.Blade_Radius) - ...
    length(Inertia_Adjust), 1) .* Inertia_Adjust(end)];

% Compute the new values for the inertia and the distributed mass,
% according to scaling law. Inertia is proportional to A^4, mass is
% porportional to A^2.
optimized_turbine.Blade_EIedge = optimized_turbine.Blade_EIedge .* ...
    Inertia_Adjust;
optimized_turbine.Blade_EIflap = optimized_turbine.Blade_EIflap .* ...
    Inertia_Adjust;
optimized_turbine.Blade_Mass = optimized_turbine.Blade_Mass .* ...
    sqrt(Inertia_Adjust);

% Recompute the structural state of the turbine
[optimized_turbine.u_y, optimized_turbine.u_z, optimized_turbine.My, ...
    optimized_turbine.Mz] = compute_structural_state( optimized_turbine, ...
    optimized_turbine.V_rated );

% Recompute the stresses in the blade to check the results
sigma_ratio_y = optimized_turbine.My(1: end - 5) ./ ...
    reference_turbine.My(1: end - 5) .* ...
    reference_turbine.Blade_EIedge(1: end - 5) ./ ...
    optimized_turbine.Blade_EIedge(1: end - 5) .* ...
    optimized_turbine.Blade_Chord(1: end - 5) ./ ...
    reference_turbine.Blade_Chord(1: end - 5); 
sigma_ratio_z = optimized_turbine.Mz(1: end - 5) ./ ...
    reference_turbine.Mz(1: end - 5) .* ...
    reference_turbine.Blade_EIflap(1: end - 5) ./ ...
    optimized_turbine.Blade_EIflap(1: end - 5) .* ...
    optimized_turbine.Blade_Chord(1: end - 5) ./ ...
    reference_turbine.Blade_Chord(1: end - 5); 

% Plot the values before the correction
figure
plot(r, sigma_ratio_y, r, sigma_ratio_z);
xlabel('Normalized radius [-]');
ylabel('Stress ratio [-]');
legend('Sigma ratio flap direction', 'Sigma ratio edge direction');
title('Stress ratio AFTER the correction');

% Final blade mass value
Final_Blade_Total_Mass = trapz(optimized_turbine.Blade_Mass) * ...
    (optimized_turbine.Blade_Radius(2) - optimized_turbine.Blade_Radius(1)); 

fprintf('Blade mass changed by %f%% \n', (Final_Blade_Total_Mass - ...
    Initial_Blade_Total_Mass) /  Initial_Blade_Total_Mass * 100);

% Save the new properties for the optimized data
save([turbine_file '_OPTIMIZED.mat'], '-struct', 'optimized_turbine')

