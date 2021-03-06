clear all
close all

% Load data for optimal radius
load('../Common/optimal_radius.mat');

% Add structure code folder to scripts path
addpath('../Common/functions');

% Linearly scaled turbine file name
turbine_file = ['../Common/SCALED_' num2str(R_optimal) 'm_' num2str(Prated * 1e-6) 'MW.mat'];


pitch = linspace(-8, 4, 10);
lambda = linspace(4, 16, 10);

optimized_turbine = load([turbine_file '_OPTIMIZED.mat']);
omega_ci = 7.55 / 60 * 2 * pi;
V0 = omega_ci * R_optimal ./ lambda;

lambda_optimal = optimized_turbine.Rated_TipSpeedRatio;

% for i = 1: length(pitch)
%     for j = 1: length(lambda)
%         
%         optimized_turbine.Rated_TipSpeedRatio = lambda(j);
%         Cp(i, j) = compute_CP_raw(pitch(i), optimized_turbine.Blade_Chord, optimized_turbine.Blade_Twist, optimized_turbine);
%         P(i,j) = 0.5 * 1.225 * V0(j) .^ 3 * (pi * R_optimal ^ 2) .* Cp(i,j);
% 
%     end
% end
% 
% mesh(lambda, pitch, Cp);
% 
% figure
% 
% mesh(lambda, pitch, P - 31508);
% hold on
% contour(lambda, pitch, P, [1 31508]);

V_ci = omega_ci * R_optimal / 13;

V_t = omega_ci * R_optimal / lambda_optimal;

V = linspace(V_ci, 25, 100);

for i = 1: length(V)
    if V(i) < V_ci
        P_aero(i) = 0;
    end
    
    if V(i) >= optimized_turbine.V_rated
        P_aero(i) = optimized_turbine.Prated;
        
    end
    
    if V(i) >= V_ci && V(i) < V_t
        lambda = omega_ci * R_optimal / V(i);
        pitch = linspace(-8, 4, 10);
        optimized_turbine.Rated_TipSpeedRatio = lambda;
        for k = 1: length(pitch)
            Cp_powercurve(k) = compute_CP_raw(pitch(k), optimized_turbine.Blade_Chord, optimized_turbine.Blade_Twist, optimized_turbine);
        end
        
        P_aero(i) = 0.5 * 1.225 * V(i) ^ 3 * (pi * R_optimal ^ 2) * max(Cp_powercurve);
        
    end
    
    
    if V(i) >= V_t && V(i) < V_rated
       
        P_aero(i) = 0.5 * 1.225 * V(i) ^ 3 * (pi * R_optimal ^ 2) * optimized_turbine.new_CP;
        
    end
    
    

end


figure('units','centimeters','position',[.1 .1 14 14])
plot(V, P_aero);

%P_loss = 31508;
%eta_tot = 0.995 ^ 3 * 0.9715;
%P_out = eta_tot * (P_aero - P_loss);

%hold on

%plot(V, P_out);
grid on
%legend('Aerodynamic power curve', 'Electric power curve');
xlabel('Wind speed [m/s]');
ylabel('Power [MW]');

print('../../Images/power_curve_aero', '-dpng');
