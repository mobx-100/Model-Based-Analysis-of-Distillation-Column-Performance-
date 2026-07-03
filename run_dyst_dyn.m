% =========================================================================
% DYNAMIC BINARY DISTILLATION SIMULATOR
% =========================================================================

clear; clc; close all; 
disp(' ');
global DIST_PAR

title1	= 'Distillation Parameters';
ind1	= {'Relative volatility (1.5)','Total number of stages (41)','Feed stage (21)',...
      'Initial feed flowrate (1)','Initial feed composition (0.5), light comp (0.5)',...
      'Feed quality (1 = sat_d liqd,0 = sat_d vapor)(1)',...
      'Initial reflux flowrate (2.706)','Initial reboiler vapor flowrate (3.206)',...
      'Distillate molar hold-up (5)','Bottoms molar hold-up (5)','Stage molar hold-up (0.5)',...
      'Magnitude step in reflux (0.02706)','Time of reflux step change (5)'};
setpar	=	{'1.5','41','21','1','0.5','1','2.706','3.206','5','5','0.5','0.02706','5'};

M = inputdlg(ind1, title1, 1, setpar);

if isempty(M)
    disp('Simulation cancelled by user.');
    return;
end
DIST_PAR = str2double(M); % Convert string inputs to numbers


% The initial guess is a linear interpolation between top and bottom compositions
x0 = linspace(0.99, 0.01, DIST_PAR(2))';

if length(x0) == DIST_PAR(2)
   disp(' ');
   disp(['Number of initial conditions: ' num2str(length(x0))]);
   disp(' ');
   disp('       ==================================================================');
   disp('                  Distillation Parameters & Values');
   disp('       ==================================================================');
   % Display the parameters being used for the simulation
   for i = 1:length(ind1)
       fprintf('%-50s: %g\n', ind1{i}, DIST_PAR(i));
   end
   disp('       ==================================================================');
   disp(' ');

   op = menu('Choose the final time (tf)', ...
       'tf = 10',...
       'tf = 50',...
       'tf = 100',...
       'tf = 300');
   switch op
       case 1
          tf 	= 10 ;
       case 2
          tf 	= 50 ;
       case 3
          tf 	= 100 ;
          disp('This might take a few seconds...');
       case 4
          tf 	= 300 ;
          disp('This might take a while...');
       otherwise
          disp('No time selected. Exiting.');
          return;
   end
else
   disp(' ');
   disp('Error: Number of initial conditions does not match the number of stages!');
   return; % Stop the script if there is a mismatch
end


disp('Starting ODE solver...');

[t,x] = ode45(@dist_dyn, [0, tf], x0);
disp('Simulation complete.');

%  PLOT THE RESULTS ---------------------------------

plotButton = questdlg('Plot Results?', 'Plot Simulation', 'Yes', 'No', 'Yes');
if strcmp(plotButton, 'Yes')
   disp('Plotting results...');
   figure; % Create a new figure window
   plot(t,x);
   title('Dynamic Response of Stage Compositions');
   xlabel('Time (s)');
   ylabel('Mole Fraction of Light Component');
   grid on;
   % Create a legend for all stages programmatically
   legendText = cellstr(num2str((1:DIST_PAR(2))', 'Stage %d'));
   legend(legendText, 'Location', 'eastoutside');
else
   disp('Finished. No plot generated.');
end


exportButton = questdlg('Export full dataset to Excel?', 'Export Data', 'Yes', 'No', 'Yes');
if strcmp(exportButton, 'Yes')
    filename = 'distillation_simulation_results.xlsx';
    disp(['Preparing data for export to ' filename '...']);

    disp('Writing simulation results to sheet: SimulationData');
    num_stages = size(x, 2);
    sim_headers = {'Time (s)'}; 
    for i = 1:num_stages
        sim_headers{end+1} = ['Stage ' num2str(i)];
    end
    data_to_export = [t, x];
    
    writecell(sim_headers, filename, 'Sheet', 'SimulationData', 'Range', 'A1');
    writematrix(data_to_export, filename, 'Sheet', 'SimulationData', 'Range', 'A2');

    disp('Writing input parameters to sheet: InputParameters');
    
    parameter_data = [ind1', M]; 
    parameter_headers = {'Parameter', 'Value'};
    
    full_parameter_export = [parameter_headers; parameter_data];

    writecell(full_parameter_export, filename, 'Sheet', 'InputParameters', 'Range', 'A1');
    
    disp('Export complete!');
    fprintf('Data saved in %s with two sheets: SimulationData and InputParameters.\n', filename);
else
    disp('Data was not exported.');
end

disp('Script finished.');

