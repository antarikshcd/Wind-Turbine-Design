function [u_y, u_z, My, Mz, L] = compute_structural_state( turbine_struct, U )

for i = 1:length(turbine_struct.Blade_NFoil)
    CL(:,i) = turbine_struct.CL(:, turbine_struct.Blade_NFoil(i));
    CD(:,i) = turbine_struct.CD(:, turbine_struct.Blade_NFoil(i));
    
    phi = atan2(U * (1 - turbine_struct.a(i)), turbine_struct.omega * turbine_struct.Blade_Radius(i)) * 180 / pi;
    
    alpha(i) = phi - (turbine_struct.Blade_Twist(i) + turbine_struct.Blade_PitchOffset);
    
    Cl(i) = interp1(turbine_struct.AoA, CL(:,i),alpha(i));
    Cd(i) = interp1(turbine_struct.AoA, CD(:,i),alpha(i));
    
    V(i) = sqrt((U * (1 - turbine_struct.a(i))) ^ 2 + (turbine_struct.omega * turbine_struct.Blade_Radius(i))  ^ 2);
    
    dL_dl(i) = 0.5 * 1.225 * V(i) ^ 2 * Cl(i) * turbine_struct.Blade_Chord(i); 
    dD_dl(i) = 0.5 * 1.225 * V(i) ^ 2 * Cd(i) * turbine_struct.Blade_Chord(i); 
    
    phi = phi * pi / 180;
    
    temp_v = [sin(phi), -cos(phi); cos(phi), sin(phi)] * [dL_dl(i); dD_dl(i)];
    dFy_dl(i) = temp_v(1);
    dFz_dl(i) = temp_v(2);
end


dFy_dl(isnan(dFy_dl)) = 0;
dFz_dl(isnan(dFz_dl)) = 0;
x = turbine_struct.Blade_Radius - turbine_struct.Blade_Radius(1);
L = trapz(turbine_struct.Blade_Radius, dFz_dl);

[u_y, u_z, My, Mz]= CantiBeam_Code(x, dFy_dl', dFz_dl', turbine_struct.Blade_EIedge, turbine_struct.Blade_EIflap, turbine_struct.Blade_Twist * pi / 180 + turbine_struct.Blade_PitchOffset);


%% plots
figure('units','centimeters','position',[.1 .1 14 14])
plot(x, u_y, 'bo-');
hold on;
grid on;
plot(x, u_z, 'rx-');
title('Deflections of the blade');
xlabel('Radial distance');
ylabel('Deflection');
legend('Edgewise', 'Flapwise');
hold off;

end

