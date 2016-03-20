close all
clear all
clc
load('../Common/Weibull_Data.mat');

% Compute the optimal radius for minimum energy cost

% ======================================================================= %
%                               VARIABLES
% ======================================================================= %

% DESIGN VARIABLE

% Rated power, W
Prated = 2.0 * 1e6; 
% Efficiency
Cp = 0.5; 

rho = 1.225;        %kg/m^3

R_init = 30;        %m      Initial radius 
R_final = 120;      %m      Final radius

% ======================================================================= %
%                             OPTIMAL RADIUS
% ======================================================================= %

% Reference radius obtained from linear scaling, m
Rref = 63 * sqrt(Prated / 5e6);   

% Radius vector
R = linspace(R_init, R_final);

% Rotor area
A = pi * R .^ 2;    %m^2

% Windspeed vector
v = linspace(0, 25);

% Weibull distribution for working hours
h = 365 * 24 * wblpdf(v, weibull_fit_wind_speed(1),weibull_fit_wind_speed(2));


% Cycle through 
for i = 1: length(R)

    % Theoretical power curve
    P = (Cp .* 0.5 .* rho .* A(i)) .* v .^ 3;
    
    % Cutoff at rated power
    P(P >= Prated) = Prated;

    % Energy yield
    E_y(i) = P * h' * (v(2) - v(1));

    % Normalized cost
    C_norm(i) = (0.7 + 0.3 * (R(i) / Rref) ^ 2.6);

    % Performance function: energy yield over normalized cost
    Perf(i) = C_norm(i) / E_y(i);

end

[Perf_min, ind] = min(Perf);

subplot(1, 2, 1)
plot(R, Perf / max(Perf), 'b', R, E_y / max(E_y), 'g', R, C_norm / max(C_norm), 'r', [R(ind) R(ind)], [0 Perf_min / max(Perf)], 'k--', [R(ind)], [Perf_min / max(Perf)], 'gs')
legend('Normalized energy cost', 'Normalized energy yield', 'Normalized cost');
xlabel('Radius [m]');
grid on
ylim([0, 1.25]);

txt = ['R(min cost) = ' num2str(R(ind)) 'm'];
text(R(ind), Perf_min / max(Perf) - 0.02, txt, 'HorizontalAlignment', 'center')

% Theoretical power curve
P = (Cp .* 0.5 .* rho .* A(ind)) .* v .^ 3;
% Cutoff at rated power
P(P >= Prated) = Prated;

ind_rated = find(P == Prated);

subplot(1, 2, 2)
plot(v, P / Prated, 'g', v, h / max(h), 'b', [v(ind_rated(1)) v(ind_rated(1))], [0 1], 'k--', [6.7044 6.7044], [0 1], 'k--')
grid on
ylim([0, 1.25]);

legend('Normalized power curve', 'Normalized wind distribution');

txt = ['v rated = ' num2str(v(ind_rated(1))) ' m/s'];
text(v(ind_rated(1)), 1.02, txt, 'HorizontalAlignment', 'center')

txt = ['v mean = ' num2str(6.7044) ' m/s'];
text(mean_wind_speed, 1.05, txt, 'HorizontalAlignment', 'center')
xlabel('Wind speed [m/s]');

R_optimal = R(ind);
V_rated = v(ind_rated(1));

save('../Common/optimal_radius.mat', 'R_optimal', 'V_rated', 'Prated');
 