    clear; close all; clc;
    
    outExcelFile = "Distillation_Simulation_Results.xlsx";
    
    DIST_PAR_defaults.alpha   = 1.5;   % relative volatility
    DIST_PAR_defaults.ns      = 41;    % number of stages (top condenser = 1, reboiler = ns)
    DIST_PAR_defaults.nf      = 21;    % feed stage
    DIST_PAR_defaults.feed    = 1.0;   % feed flow (mol/min)
    DIST_PAR_defaults.zfeed   = 0.5;   % feed composition (mole fraction light)
    DIST_PAR_defaults.qf      = 1.0;   % feed quality (1 = saturated liquid)
    DIST_PAR_defaults.reflux  = 2.706; % initial reflux (mol/min)
    DIST_PAR_defaults.vapor   = 3.206; % initial reboiler vapor boil-up (mol/min)
    % holdups (mol)
    % holdups (mol)
    DIST_PAR_defaults.md      = 5;     % overhead receiver holdup (stage 1)
    DIST_PAR_defaults.mf      = 0.5;   % feed tray holdup (stage nf)
    DIST_PAR_defaults.mb      = 5;     % reboiler holdup (stage ns)
    DIST_PAR_defaults.mt      = 5;     % holdup for intermediate trays (NOT 0.5)
    
    % Simulation time parameters
    tspan = [0 400];  % minutes
    t_plot = linspace(tspan(1), tspan(2), 201);
    
    % Parameter sweep setup (each row is one run). Example sweeping reflux values:
    % You can change the grid: here we sweep reflux and boil-up
    reflux_values = [2.6, 2.706, 2.8];   % examples (mol/min)
    vapor_values  = [3.0, 3.206, 3.4];    % boil-up values (mol/min)
    

   global DEFAULT_STEPS
    DEFAULT_STEPS = [ struct('type','reflux','mag',0.1,'time',5) ];

    
    % ========== Prepare Excel file: remove if exists ==========
    if isfile(outExcelFile)
        delete(outExcelFile);
    end
    
    % ========== Loop over parameter combinations ==========
    run_id = 0;
    summary_rows = {};
    summary_header = {'RunID','reflux_init','vapor_init','feed','zfeed','qf','alpha','ns','nf','steady_D_x','steady_B_x','max_delta_distillate','max_delta_bottoms','notes'};
    
    for R = reflux_values
        for V = vapor_values
            run_id = run_id + 1;
            fprintf('Running simulation %d: reflux=%.4g, vapor=%.4g\n', run_id, R, V);
    
           
            dp = DIST_PAR_defaults;
            dp.reflux = R;
            dp.vapor  = V;
    
            DIST_PAR = zeros(1,19); % we will fill required entries; unused remain zero
            DIST_PAR(1) = dp.alpha;
            DIST_PAR(2) = dp.ns;
            DIST_PAR(3) = dp.nf;
            DIST_PAR(4) = dp.feed;
            DIST_PAR(5) = dp.zfeed;
            DIST_PAR(6) = dp.qf;
            DIST_PAR(7) = dp.reflux;
            DIST_PAR(8) = dp.vapor;
            DIST_PAR(9) = dp.md;
            DIST_PAR(10)= dp.mb;
            DIST_PAR(11)= dp.mt;
    
            % ========== Steady-state solve using dist_ss ==========
  
            x0 = linspace(dp.zfeed, 0.01, dp.ns)';  % column vector
            % make DIST_PAR global for dist_ss as in original implementation
            global DIST_PAR_GLOBAL
            DIST_PAR_GLOBAL = DIST_PAR;
            options = optimoptions('fsolve','Display','none','FunctionTolerance',1e-10,'StepTolerance',1e-10,'MaxIterations',400);
            try
                x_ss = fsolve(@dist_ss, x0, options);
            catch ME
                warning('fsolve failed for run %d: %s', run_id, ME.message);
                x_ss = x0; % fallback
            end
    
            % compute y steady via equilibrium relation
            alpha = DIST_PAR(1);
            y_ss = (alpha .* x_ss) ./ (1 + (alpha - 1).* x_ss);
    
            % steady distillate composition (stage 1) and bottoms composition (stage ns)
            steady_D_x = x_ss(1);
            steady_B_x = x_ss(end);
    
            % ========== Dynamic simulation ==========
      
            x_initial = x_ss;
    
       
            global DIST_PAR_dyn DEFAULT_STEPS_GLOBAL
            DIST_PAR_dyn = DIST_PAR;
            DEFAULT_STEPS_GLOBAL = DEFAULT_STEPS;
    
            
            odefun = @(t,x) dist_dyn(t,x);
    
            % solve with ode45 and interpolate to uniform times t_plot
            opts_ode = odeset('RelTol',1e-6,'AbsTol',1e-9);
            [t_sim, x_sim] = ode45(odefun, tspan, x_initial, opts_ode);
            x_interp = interp1(t_sim, x_sim, t_plot);
    
            % obtain outputs (distillate x = x(1), bottoms x = x(ns))
            distillate_ts = x_interp(:,1);
            bottoms_ts    = x_interp(:,end);
    
            % compute transient metrics
            max_delta_D = max(abs(distillate_ts - steady_D_x));
            max_delta_B = max(abs(bottoms_ts - steady_B_x));
    
            % ========== Write TimeSeries sheet for this run ==========
            sheetName = sprintf('TimeSeries_run%d', run_id);
            % build table: time | x1 x2 ... x_ns | y1 y2 ... y_ns
            T_time = table(t_plot', 'VariableNames', {'time_min'});
            % append x columns
            for i = 1:dp.ns
                varname = sprintf('x_stage%02d', i);
                T_time.(varname) = x_interp(:,i);
            end
            % add vapor compositions y (via equilibrium)
            for i = 1:dp.ns
                varname = sprintf('y_stage%02d', i);
                xcol = x_interp(:,i);
                ycol = (dp.alpha .* xcol) ./ (1 + (dp.alpha-1).* xcol);
                T_time.(varname) = ycol;
            end
    
            % Write the table to Excel (writetable will create sheet)
            writetable(T_time, outExcelFile, 'Sheet', sheetName, 'WriteRowNames', false);
    
            % ========== Write summary row ==========
            notes = '';
            summary_rows(end+1,:) = {run_id, R, V, dp.feed, dp.zfeed, dp.qf, dp.alpha, dp.ns, dp.nf, steady_D_x, steady_B_x, max_delta_D, max_delta_B, notes};
    
            % optionally save plots to image files or to workbook (Excel chart creation not done here)
            % Display brief progress plot in MATLAB
            figure(1); clf;
            subplot(2,1,1); plot(t_plot, distillate_ts); hold on; yline(steady_D_x,'--'); ylabel('x_D'); title(sprintf('Run %d: x_D vs time',run_id));
            subplot(2,1,2); plot(t_plot, bottoms_ts); hold on; yline(steady_B_x,'--'); ylabel('x_B'); xlabel('time (min)');
            drawnow;
        end
    end
    
    % write summary sheet
    SummaryT = cell2table(summary_rows, 'VariableNames', summary_header);
    writetable(SummaryT, outExcelFile, 'Sheet', 'Summary', 'WriteRowNames', false);
    
    fprintf('All runs done. Excel file saved: %s\n', outExcelFile);
