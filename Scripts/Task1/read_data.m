function [wind_speed, wind_direction] = read_data()



% data are ten-minute averages, 144 samples / day
   
%open and read datafile

data = [];

for i = 0 : 3

    fprintf(['Reading file ' 'Data/WM04_201' num2str(i) '.csv\n']);
    temp_data = csvread(['Data/WM04_201' num2str(i) '.csv'], 17, 2);
    fprintf(['Loaded data dimensions are: ' num2str(size(temp_data)) '\n']);
    data = [data; temp_data(:, 1: 44)];
    
end


data = data(~any(isnan(data),2),:); 

% [data]    = xlsread('Bantiger_10mindata.xls');

wind_speed     = data(:, 1);
wind_direction = data(:, 21);

%%
 figure
  
  subplot(2, 1, 1)
     plot(wind_speed ,'r-.','LineWidth',3,'MarkerSize',9,'MarkerEdgeColor',[1 0 0],'MarkerFaceColor',[1 0 0]);
     hold on;
     ylabel('wind speed (m/s) ','fontsize',16,'fontweight','b')
     xlabel('time (10mins)   ','fontsize',16,'fontweight','b')
  
    subplot(2, 1, 2)
     plot(wind_direction ,'b-.','LineWidth',3,'MarkerSize',9,'MarkerEdgeColor',[0 0 1],'MarkerFaceColor',[0 0 1]);
     hold on;
     ylabel('wind direction (deg.) ','fontsize',16,'fontweight','b')
     xlabel('time (10mins)   ','fontsize',16,'fontweight','b')
     
end