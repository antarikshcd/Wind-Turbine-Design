function [perf] = compute_CP(new_values, turbine_struct, CHORD_LIMITS, TWIST_LIMITS)


% load variables from turbine structure
Blade_Radius = turbine_struct.Blade_Radius;
Blade_Twist = turbine_struct.Blade_Twist * pi/180;
Blade_Chord = turbine_struct.Blade_Chord;
Blade_NFoil = turbine_struct.Blade_NFoil;
NBlades = turbine_struct.NBlades;
WindSpeed_Cutin = turbine_struct.WindSpeed_Cutin;
WindSpeed_Cutout = turbine_struct.WindSpeed_Cutout;
Generator_Efficiency = turbine_struct.Generator_Efficiency;
Gearbox_Efficiency = turbine_struct.Gearbox_Efficiency;
Rated_Power = turbine_struct.Rated_Power;
TSR = turbine_struct.Rated_TipSpeedRatio;
AoA = turbine_struct.AoA * pi/180;


Pitch = new_values(1) * pi/180;

temp_r = linspace(0, Blade_Radius(end), length(new_values) / 2);

new_values = new_values(2:end);

Blade_Twist = Blade_Twist .* (1 + (interp1(temp_r, new_values(1: end / 2)', Blade_Radius, 'pchip') - 0.5) * TWIST_LIMITS);
Blade_Chord = Blade_Chord .* (1 + (interp1(temp_r, new_values(end / 2 + 1: end)', Blade_Radius, 'pchip') - 0.5) * CHORD_LIMITS);

for i = 1:length(Blade_NFoil)
    CL(:,i) = turbine_struct.CL(:,Blade_NFoil(i));
    CD(:,i) = turbine_struct.CD(:,Blade_NFoil(i));
end

% Local tip speed ratio and solidity
r = Blade_Radius/Blade_Radius(end);

lambdar = TSR * r;
sigmar = NBlades*Blade_Chord./(2*pi*Blade_Radius);


% Initial induction factors
anew = 1/3*ones(size(Blade_Radius));
a_new = zeros(size(Blade_Radius));
for iter = 1:100

    a = anew;
    a_ = a_new;

    % Inflow angle
    phi = real(atan((1-a)./((1+a_).*lambdar)));

    % Tip loss correction
    F = 2/pi * acos(exp(-NBlades/2*(1-r)./(r.*sin(phi))));

    % Aerodynamic force coefficients
    alpha = phi - Pitch - Blade_Twist;
    for j = 1:length(Blade_Radius) 
        Cl(j) = interp1(AoA,CL(:,j),alpha(j));
        Cd(j) = interp1(AoA,CD(:,j),alpha(j));
    end
    Cl = Cl(:);
    Cd = Cd(:);
    Cl(isnan(Cl)) = 1e-6;
    Cd(isnan(Cd)) = 0;
    Cl(Cl == 0) = 1e-6;

    % Thrust coefficient
    CT = sigmar.*(1-a).^2.*(Cl.*cos(phi)+Cd.*sin(phi))./(sin(phi).^2);
    

    % New induction factors
    for j = 1:length(Blade_Radius)
        if CT(j) < 0.96
            anew(j) = 1/(1+4*F(j)*sin(phi(j))^2/(sigmar(j)*Cl(j)*cos(phi(j))));
        else
            anew(j) = (1/F(j))*(0.143+sqrt(0.0203-0.6427*(0.889-CT(j))));
        end
    end
    a_new = 1./(4*F.*cos(phi)./(sigmar.*Cl)-1);
        

    if max(abs(anew - a)) < 0.01 && max(abs(a_new - a_)) < 0.002
        break
    end

end

% Power coefficient
dCP = (8*(lambdar-[0; lambdar(1:end-1)])./TSR^2).*F.*sin(phi).^2.*(cos(phi)-lambdar.*sin(phi)).*(sin(phi)+lambdar.*cos(phi)).*(1-(Cd./Cl).*(cot(phi))).*lambdar.^2;
CP = real(sum(dCP(~isnan(dCP))));

perf = -CP;
end