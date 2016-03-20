clear all
close all
clc 

    
%% read data

[wind_speed, wind_direction] = read_data();

length_data = length(wind_speed);


%%
% Calculate mean and std


mean_wind_speed = mean(wind_speed);
std_wind_speed = std(wind_speed);

mean_wind_direction = mean(wind_direction);
std_wind_direction = std(wind_direction);

histogram(wind_speed)

%%
% Plot the wind rose

wind_rose(wind_direction,wind_speed);

%%
% c) Calculate Weibull and Rayleigh parameter 

% wblfit and raylfit 

weibull_fit_wind_speed = wblfit(wind_speed+0.001); % how to use wblfit if data has zero entries?
rayleigh_fit_wind_speed = raylfit(wind_speed);

clear wind_direction
clear wind_speed

save('../Common/Weibull_Data.mat');
