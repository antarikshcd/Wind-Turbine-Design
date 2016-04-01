%% Code for beam theory based calculations
%start as script develop as function
%% clear
% close all;
% clear all;
% clc;
function [u_y,u_z, My, Mz]=CantiBeam_Code (x,Py,Pz,EI_1,EI_2,twist)
%% input
N=length(x);
Ty=zeros(N,1);
Tz=zeros(N,1);
My=zeros(N,1);
Mz=zeros(N,1);
theta_y=zeros(N,1);
theta_z=zeros(N,1);
u_y=zeros(N,1);
u_z=zeros(N,1);

%boundary conditions
Ty(N)=0;
Tz(N)=0;
My(N)=0;
Mz(N)=0;

theta_y(1)=0;
theta_z(1)=0;
u_y(1)=0;
u_z(1)=0;

% iterative code
for i=N:-1:2
    Ty(i-1)=Ty(i)+1/2*(Py(i-1)+Py(i))*(x(i)-x(i-1));
    Tz(i-1)=Tz(i)+1/2*(Pz(i-1)+Pz(i))*(x(i)-x(i-1));
    
    My(i-1)=My(i)-Tz(i)*(x(i)-x(i-1))-(1/6*Pz(i-1)+1/3*Pz(i))*...
            (x(i)-x(i-1))^2;
    Mz(i-1)=Mz(i)+Ty(i)*(x(i)-x(i-1))+(1/6*Py(i-1)+1/3*Py(i))*...
            (x(i)-x(i-1))^2;
      
end

M1=My.*cos(twist) - Mz.*sin(twist);
M2=My.*sin(twist) + Mz.*cos(twist);
k1=M1./EI_1;
k2=M2./EI_2;
kz=-k1.*sin(twist)+k2.*cos(twist);
ky=k1.*cos(twist)+k2.*sin(twist);

for i=1:N-1
    theta_y(i+1)=theta_y(i)+1/2*(ky(i+1)+ky(i))*(x(i+1)-x(i));
    theta_z(i+1)=theta_z(i)+1/2*(kz(i+1)+kz(i))*(x(i+1)-x(i));
    
    u_y(i+1)=u_y(i)+theta_z(i)*(x(i+1)-x(i))+(1/6*kz(i+1)+1/3*kz(i))*...
             (x(i+1)-x(i))^2;
    u_z(i+1)=u_z(i)-theta_y(i)*(x(i+1)-x(i))-(1/6*ky(i+1)+1/3*ky(i))*...
             (x(i+1)-x(i))^2;
end

