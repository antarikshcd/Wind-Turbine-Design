clear all

% Resize a wind turbine according to scaling laws given the initial turbine
% and the new rotor radius

load('../Common/NREL5MW.mat');          % Original wind turbine data
load('../Common/optimal_radius.mat');   % New wind turbine data

R = R_optimal;                          % New radius
R_reference = Blade_Radius(end);        % Original radius

Rated_Power = Prated;                   % New rated power

lr = R / R_reference;                   % Linear scaling ratio


% BLADE SCALING according to scaling laws
Blade_Chord = Blade_Chord * lr;
Blade_Radius = Blade_Radius * lr;
Blade_EIedge = Blade_EIedge * lr ^ 4;
Blade_EIflap = Blade_EIflap * lr ^ 4;
Blade_Mass = Blade_Mass * lr ^ 2;

% TOWER SCALING according to scaling laws
Tower_Height = Tower_Height * lr;
Tower_Mass = Tower_Mass * lr ^ 3;
Tower_OuterDiameter = Tower_OuterDiameter * lr;
Tower_EI = Tower_EI * lr ^ 4;
Tower_BottomThickness = Tower_BottomThickness * lr;
Tower_TopThickness = Tower_TopThickness * lr;

% HUB AND NACELLE SCALING according to scaling laws
Hub_Height = Hub_Height * lr;
Hub_Mass = Hub_Mass * lr ^ 3;
Hub_Overhang = Hub_Overhang * lr;
Nacelle_Diameter = Nacelle_Diameter * lr;

% Save the newely obtained data to file
save(['../Common/SCALED_' num2str(R) 'm_' num2str(Rated_Power * 1e-6) ...
    'MW.mat']);
