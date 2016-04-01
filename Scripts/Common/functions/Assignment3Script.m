%Assignment 3: Structures
%The following code encompasses the solution to the problems in Assignment
%3 of Course 46300:Wind Turbine Technology and Aerodynamics
%Authors: Antariksh Dicholkar(s152215)
%Date: 9/12/2015
%Version:1
%% Clear
close all;
clear all;
clc;
%% Input
g_pitch=0.016%*pi/180; % global pitch angle, [rad];
%V0=[8;12;20]; % wind velocity, [m/s]
%omega=[2;2;2]; % rotor speed, [rad/s]
R = 48.2; % rotor blade length, [m]

%blade = [r/R,twist(deg),EI_1(GNm^2),EI_2(GNm^2),mass(kg/m)]
blade_struc = [0.09 0    6.4    6.9    495;
               0.20 16.4 2.2663 5.6012 505.79 ;
               0.30 10.2 0.9427 3.4066 413.46;
               0.40 6.7  0.4766 2.1004 343.53;
               0.50 4.5  0.2393 1.3175 287.10;
               0.60 2.9  0.1191 0.8288 250.38;
               0.70 1.8  0.0552 0.4840 239.21;
               0.80 1.0  0.0216 0.2397 126.78;
               0.90 0.4  0.0061 0.0982 71.82;
               0.94 0.1  0.0025 0.0562 49.54;
               0.97 0.0  0.0014 0.0402 38.04;
               1     0   0.0006 0.0289 30];

x=blade_struc(:,1)*R-3.6;
x(1)=0;
x_act=x+3.6;
R_anal=R-3.6;
twist=blade_struc(:,2)*pi/180;
N=length(x);
%%
%Using the BEM code to obtain the required loading
% In case of pitching first project Pt and Pn on to y-z axes by taking
% their components
u_y=zeros(N);
u_z=zeros(N);
EI_1=blade_struc(:,3)%*10^9; %multiplying by 1e9 to convert the units to Nm2
EI_2=blade_struc(:,4)%*10^9;
%Py=zeros(N,1); %Assuming aerodynamic loads to be zero at clamped position
%Pz=zeros(N,1);

% parameter preallocation
%Pn = zeros(10,numel(V0));
%Pt = zeros(10,numel(V0));

%for i=1:numel(V0)%varying over wind speeds
    %[Pn(:,i),Pt(:,i)]=BEMcode(g_pitch(i),V0(i),omega(i)); %BEM code called
    %[Pn_walk,Pt_walk]=BEMcode_walker(g_pitch(i),V0(i),omega(i));%BEM code
    Py(2:N-1)=Pt(:,i).*cos(g_pitch)-Pn(:,i).*sin(g_pitch);
    Pz(2:N-1)=Pt(:,i).*sin(g_pitch)+Pn(:,i).*cos(g_pitch);
    [u_y(:,i),u_z(:,i)]= CantiBeam_Code(x,Py,Pz,EI_1,EI_2,twist);
%end



%% plots
figure (1);
plot(x, u_y, 'b0-');
hold on;
grid on;
plot(x, u_z, 'rx-');
title('Deflections of the blade');
xlabel('Radial distance');
ylabel('Deflection');
legend('Flapwise','Edgewise');
hold off;