% ==============================================================
% main_dist.m - Simulation of an ideal binary distillation column
% ==============================================================
clear; clc; close all;

% --------------------------
% Column & model parameters
% --------------------------
alpha  = 1.5;     % relative volatility
ns     = 10;      % total number of stages (incl. condenser + reboiler)
nf     = 5;       % feed stage number

F      = 1.0;     % feed flowrate (mol/min)
zF     = 0.5;     % feed composition (mole fraction light component)
qF     = 1.0;     % liquid fraction of feed (1 = saturated liquid)

R      = 1.5;     % reflux flowrate (mol/min)
V      = 1.5;     % vapor boilup (mol/min)

Md     = 1.0;     % condenser holdup
Mb     = 1.0;     % reboiler holdup
Mt     = 1.0;     % tray holdup (assumed equal for all trays)

% Pack into parameter vector
DIST_PAR_GLOBAL = [alpha ns nf F zF qF R V Md Mb Mt];
global DIST_PAR_GLOBAL

DIST_PAR_dyn = DIST_PAR_GLOBAL;
global DIST_PAR_dyn

% --------------------------
% Steady-state calculation
% --------------------------
x0_guess = linspace(0.01,0.99,ns)';   % initial guess profile

options_fsolve = optimoptions('fsolve', ...
    'Display','iter', 'TolFun',1e-10, 'TolX',1e-10);

[x_ss, fval, exitflag] = fsolve(@dist_ss, x0_guess, options_fsolve);

if exitflag <= 0
    warning('Steady-state solver may not have converged!');
end

disp('-------------------------------------------------')
disp('Steady-state liquid mole fractions (x_i):')
disp(x_ss')
disp('-------------------------------------------------')

% --------------------------
% Dynamic simulation
% --------------------------
tspan = [0 50];   % time horizon
opts = odeset('RelTol',1e-8,'AbsTol',1e-8);

[t, xdyn] = ode15s(@dist_dyn, tspan, x_ss, opts);

% --------------------------
% Plotting
% --------------------------
figure;
plot(t, xdyn, 'LineWidth', 1.5);
xlabel('Time (min)','FontSize',12);
ylabel('Liquid mole fraction of light component','FontSize',12);
title('Dynamic Response of Distillation Column','FontSize',14);
legend(arrayfun(@(i) sprintf('Stage %d',i), 1:ns,'UniformOutput',false), ...
       'Location','eastoutside');
grid on;
