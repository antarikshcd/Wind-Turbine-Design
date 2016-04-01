clear all
close all
% Script used to estimate the stresses acting on a wind turbine tower and
% its first eigenmodes.

% Load data for optimal radius
load('../Common/optimal_radius.mat');

% Add structure code folder to scripts path
addpath('../Common/functions');

% Linearly scaled turbine file name
turbine_file = ['../Common/SCALED_' num2str(R_optimal) 'm_' num2str(Prated * 1e-6) 'MW.mat'];

optimized_turbine = load([turbine_file '_OPTIMIZED.mat']);

[u_y, u_z, My, Mz, L] = compute_structural_state( optimized_turbine, optimized_turbine.V_rated );

T = L * 3;

reference_turbine = load(['../Common/NREL5MW.mat']);

% ======================================================================= %
%                               VARIABLES
% ======================================================================= %
% DESIGN VARIABLES

% Rotor radius, m
R = 50;

Total_Mass_Top = (R_optimal / 63) ^ 3 * (reference_turbine.Nacelle_Mass + reference_turbine.Hub_Mass) + 3 * optimized_turbine.Blade_Total_Mass;


% Linearly scaled variables
H           = 87.6 * R / 63;%m      Tower height
lr          = H / 87.6;
r2b         = 6 / 2 * lr;   %m      External radius, bottom
r2t         = 3.87 / 2 * lr;%m      External radius, top
tb          = 0.027 * lr;   %m      Thickness, bottom
tt          = 0.019 * lr;   %m      Thickness, top

% Material properties (steel)
E           = 210 * 1e9;    %Pa     Elastic modulus
G           = 80.8 * 1e9;   %Pa     Shear modulus
theta_max   = 250 * 1e6;    %Pa     Ultimate stress
rho         = 8500;         %kg/m^3 (increased to consider bolts and nuts).

% Gravity acceleration
g           = 9.8066;       %m/s^2

% ======================================================================= %
%                               STRESSES
% ======================================================================= %

% Height vector
z = linspace(0, H);

% All geometric properties are varied linearly from bottom to top.

% Radius. r2 = external radius, r1 =
% internal radius. r2 = r1 + t, where t is the thickness of the wall.
r2 = r2b + (r2t - r2b) / H * z;

% Thickness
t = tb + (tt - tb) / H * z;

% Area and moment of inertia
A = pi * (r2 .^ 2 - (r2 - t) .^ 2);
J = pi * (r2 .^ 4 - (r2 - t) .^ 4) / 4;

% Weight force vector. At each value of z, W is equal to the weight of the
% tower "above". Used to compute stresses because of own weight.
W = zeros(size(z)) + Total_Mass_Top;
for i = 1 : length(z)
    W(i) = trapz(A(i : end) .* rho * g) * (z(2) - z(1));
end

% Normal stress due to weight
theta_w = W ./ A; 

% Moment due to thrust as a function of height.
M = T * (H - z);

% Bending stress, computed at r2 for maximum value, as a function of
% height.
theta_m = M .* r2 ./ J;

% Total stress.
theta = abs(theta_m) + abs(theta_w);

% ======================================================================= %
%                          NATURAL FREQUENCIES
% ======================================================================= %

syms x

% Base functions for eigenanalysis. Can be of any type, provided that:
% - it is zero for x = 0;
% - its derivative is zero for x = 0;
% - it is not null everywhere.

U = [ x ^ 2 x ^ 3 x ^ 4 x ^ 5]; % Polynomial base function
Upp = diff(diff(U, x), x);  % Second derivative of the base functions


% Computation of the mass and stiffness matrices
UU = transpose(U) * U;
UUpp = transpose(Upp) * Upp;
S = size(UU);
UU_eval = zeros(S(1), S(2), length(z));
JUU_pp = zeros(S(1), S(2), length(z));

for i = 1: length(z)
    UU_eval(:, :, i) = rho * A(i) * double(subs(UU, x, z(i)));
    JUU_pp(:, :, i) = E * J(i) * double(subs(UUpp, x, z(i)));
end

Km = zeros(size(UU));
Mm = zeros(size(UU));
for i = 1: length(U)
   for j = 1: length(U) 
        Km(i, j) = trapz(reshape(JUU_pp(i, j, :), 1, length(z))) * (z(2) - z(1));
        Mm(i, j) = trapz(reshape(UU_eval(i, j, :), 1, length(z))) * (z(2) - z(1));
   end
end

% Compute the eigensolutions of the omogeneous problem (Km + s^2 Mm)q = 0
[X, V] = eig(Mm\Km);
omega_s = eig(Mm\Km);

% Natural frequencies of the first N natural modes, where N = length(U);
f =  sqrt(omega_s) / ( 2 * pi);
[f, ind] = sort(f);
X = X(:, ind);

% ======================================================================= %
%                                 PLOTS
% ======================================================================= %

figure('units','centimeters','position',[.1 .1 28 14])

subplot(1, 3, 1)
plot([-r2b r2b r2t -r2t -r2b], [0 0 H H 0], 'g')
axis equal
ylim([ 0 1.1 * H]);
title('Geometric dimensions')
xlabel('[m]');
ylabel('[m]');

subplot(1, 3, 2)
plot(theta, z, 'g', [theta_max theta_max], [0 z(end)], 'r')
ylim([ 0 1.1 * H]);
title('Max stress')
xlabel('Max stress [Pa]') % x-axis label
ylabel('[m]');
legend('Total stress', 'Ultimate stress');

subplot(1, 3, 3)
for i = 1: length(U)
    hold on
    modes(i, :) = double(subs(U * X(:, i), z));
    plot(modes(i, :) * 1 / max(abs(modes(i, :))), z);
end

ylim([ 0 1.1 * H]);
title('Eigenmodes')
xlabel('Normalized deformation') % x-axis label
ylabel('[m]');

fprintf('=========== STRESSES ===========\n');
fprintf(['Max stress: ' num2str(max(theta) * 1e-6) 'MPa\n']);
fprintf(['Safety factor: ' num2str( theta_max / max(theta)) '\n']);
fprintf('\n\n');

fprintf('=========== NAT FREQ ===========\n');
for i = 1: length(U)
    strs{i} = ['Mode #' num2str(i)];
    fprintf(['Natural frequency #' num2str(i) ': ' num2str(f(i)) 'Hz or '  num2str(f(i) * 2 * pi) 'rad/s \n']);  
end

legend(strs);

print('../../Images/Tower', '-dpng'); 

