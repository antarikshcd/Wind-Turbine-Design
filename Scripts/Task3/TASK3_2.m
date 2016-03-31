close all
clear all

% Compute the optimal chord and twist distributions for maximum CP

% NUMBER OF FREE PARAMETERS TO BE USED TO OPTIMIZE THE CHORD AND TWIST
% DISTRIBUTION. IN TOTAL, THE OPTIMIZED PARAMETERS WILL BE:
% - 1 VALUE FOR THE PITCH OFFSET;
% - N_PARAMS VALUES FOR THE TWIST DISTR. (0 to 1);
% - N_PARAMS VALUES FOR THE CHORD DISTR. (0 to 1);
% 
% An high value for N_PARAMS allows for better optimization but requires
% more computation times. The optimized values are RELATIVE INCREMENTS of
% the initial values of the scaled turbine. I.e., if a value of the
% optimized parameters for the chord is 0.1, it means that the new chord at
% that location is (0.1 - 0.5) * CHORD_LIMITS times the original chord. The  
% value of CHORD_LIMITS and TWIST_LIMITS allow to limit the maximum 
% difference between the orginial turbine an the optimized one. 
% If CHORD_LIMITS is 0.5, the new chord will not be larger than 1.5 times
% the original chord or smaller than 0.5 times the original chord.
% If N_PARAMS is different from the number of values specified for the 
% original turbine (which is 49 right now) an interpolation is used.
                 
N_PARAMS = 10; 
CHORD_LIMITS = 1;
TWIST_LIMITS = 1;

% Load the reference turbine data
load('../Common/NREL5MW.mat');
% Load the data of the new turbine from preliminar design
load('../Common/optimal_radius.mat');
% Filename of the turbine to be optimized
turbine_file = ['../Common/SCALED_' num2str(R_optimal) 'm_' num2str(Prated * 1e-6) 'MW.mat'];

addpath('functions');

% Radiuses of the optimal and reference turbines
R = R_optimal;
R_ref = Blade_Radius(end);

% Maximum tip speed of the reference turbine
Max_tip_speed_ref = 80; % <------- MUST BE MANUALLY CHANGED IF REQUIRED!!!!

% Update maximum tip speed from scaling laws:
% Generated sound pressure is a function of the 5-th power of the tip speed;
% Sensed sound pressure is a function of the inverse of 2-nd power of the
% radius.
max_tip_speed = ((R / R_ref) ^ 2) ^ (1 / 5) * Max_tip_speed_ref


% New tip speed ratio
lambda = max_tip_speed / V_rated;
omega = max_tip_speed / R;

% Create a structure with the data of the turbine to be optimized to be
% passed to the optimizer
turbine_struct = load(turbine_file);
load(turbine_file);
turbine_struct.Rated_TipSpeedRatio = lambda;

% Temporary anonymous function required to pass the turbine structure to
% the optimizer
temp_function = @(x) compute_CP(x, turbine_struct, CHORD_LIMITS, ...
    TWIST_LIMITS);

% Options for the optimizer
options = optimoptions('fmincon', 'TolFun', 1e-3, 'Display','iter');

% Call the optimizer
fprintf('Starting optimizer...\n');
fprintf('At every iteration CP is equal to -f(x).\n');
fprintf('Iteration 0 is used to numerically approximate the Jacobian.\n');
optimized_values = fmincon(temp_function, 0.5 * ...
    ones(1, N_PARAMS * 2 + 1), [], [], [], [], ...
    zeros(1, 2 * N_PARAMS + 1), ones(1, N_PARAMS * 2 + 1) , [], options);

% Optimized Pitch Offset
Blade_PitchOffset = optimized_values(1);

% Remove the pitch offset from the optimized values
optimized_values = optimized_values(2:end);

% Radius arrays to interpolate the optimized values
temp_r = linspace(0, Blade_Radius(end), length(optimized_values) / 2);
r = linspace(0, R, length(Blade_Twist) );

new_twist = Blade_Twist .* (1 + (interp1(temp_r, ...
    optimized_values(1: end / 2)', Blade_Radius, 'pchip') - 0.5) ...
    * TWIST_LIMITS);
new_chord = Blade_Chord .* (1 + (interp1(temp_r, ...
    optimized_values(end / 2 + 1: end)', Blade_Radius, 'pchip') - 0.5) ...
    * CHORD_LIMITS);

% Plot the new twist distribution
figure('units','centimeters','position',[.1 .1 14 14])
subplot(2, 1, 1)
plot(r, Blade_Twist, r, smooth(new_twist), 'LineWidth', 2);
hold on
plot(r, new_twist, 'g--');
grid on
legend('Original twist', 'Optimized and smoothed twist', ...
    'Raw optimized twist');
xlabel('Radius [m]');
ylabel('Twist [°]');

% Plot the new chord distribution
subplot(2, 1, 2)
plot(r, Blade_Chord, r, smooth(new_chord), 'LineWidth', 2);
hold 
plot(r, new_chord, 'g--');
legend('Original chord', 'Optimized and smoothed chord',...
    'Raw optimized chord');
axis equal
grid on
xlabel('Radius [m]');
ylabel('Chord [m]');
print('../../Images/twist_and_chord','-dpng')

figure('units','centimeters','position',[.1 .1 14 14])
plot(r, smooth(new_twist), 'LineWidth', 2);
grid on
xlabel('Radius [m]');
ylabel('Twist [°]');
print('../../Images/twist','-dpng')

figure('units','centimeters','position',[.1 .1 14 14])
plot(r, smooth(new_chord), 'LineWidth', 2);
axis equal
grid on
xlabel('Radius [m]');
ylabel('Chord [m]');
print('../../Images/chord','-dpng')

% Save the optimized values in a new mat file
Rated_TipSpeedRatio = lambda;



Blade_Chord = smooth(new_chord);
Blade_Twist = smooth(new_twist);
save([turbine_file '_OPTIMIZED.mat']);

test_turbine = load([turbine_file '_OPTIMIZED.mat']);
[new_CP, a] = compute_CP_raw(Blade_PitchOffset, Blade_Chord, ...
    Blade_Twist, test_turbine);

save([turbine_file '_OPTIMIZED.mat']);


fprintf('Final optimized CP = %f \n', new_CP);

test_turbine = load('../Common/NREL5MW.mat');
[asd, test_turbine.a] = compute_CP_raw(test_turbine.Blade_PitchOffset, ...
    test_turbine.Blade_Chord, test_turbine.Blade_Twist, test_turbine);
test_turbine.omega = 80 / test_turbine.Blade_Radius(end);
save('../Common/NREL5MW.mat', '-struct', 'test_turbine');

