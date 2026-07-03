function xdot = dist_dyn(t,x)

    global DIST_PAR

    if isempty(DIST_PAR) || length(DIST_PAR) < 11
        error('DIST_PAR is not defined or has too few parameters. Run the main script first.');
    end

    alpha   = DIST_PAR(1);    % relative volatility
    ns      = DIST_PAR(2);    % total number of stages
    nf      = DIST_PAR(3);    % feed stage
    feedi   = DIST_PAR(4);    % initial feed flowrate
    zfeedi  = DIST_PAR(5);    % initial feed composition
    qf      = DIST_PAR(6);    % feed quality
    refluxi = DIST_PAR(7);    % initial reflux flowrate
    vapori  = DIST_PAR(8);    % initial reboiler vapor flowrate
    md      = DIST_PAR(9);    % distillate molar hold-up
    mb      = DIST_PAR(10);   % bottoms molar hold-up
    mt      = DIST_PAR(11);   % stage molar hold-up

    % while setting other potential (but unused) disturbances to zero.
    if length(DIST_PAR) >= 13
        stepr = DIST_PAR(12);   % magnitude step in reflux
        tstepr = DIST_PAR(13);  % time of reflux step change
    else
        stepr = 0;
        tstepr = 0;
    end
    % Set other disturbances to zero as they are not defined in the input dialog
    stepv = 0; tstepv = 0;
    stepzf = 0; tstepzf = 0;
    stepf = 0; tstepf = 0;


    % Check disturbances in reflux, vapor boil-up, feed composition and feed flowrate
    if t < tstepr
        reflux = refluxi;
    else
        reflux = refluxi + stepr;
    end

    if t < tstepv
        vapor = vapori;
    else
        vapor = vapori + stepv;
    end

    if t < tstepzf
        zfeed = zfeedi;
    else
        zfeed = zfeedi + stepzf;
    end

    if t < tstepf
        feed = feedi;
    else
        feed = feedi + stepf;
    end

    % Rectifying and stripping section liquid flowrates
    lr = reflux;
    ls = reflux + feed*qf;

    % Rectifying and stripping section vapor flowrates
    vs = vapor;
    vr = vs + feed*(1-qf);

    % Distillate and bottoms rates
    dist = vr - reflux;
    lbot = ls - vs;

    if dist < 0
        error('Error in specifications: Distillate flow < 0. Check parameters.');
    end

    if lbot < 0
        error('Error in specifications: Bottoms flow < 0. Check parameters.');
    end

    % Pre-allocate vectors for speed
    xdot = zeros(ns,1);
    y = zeros(ns,1);

    % Calculate the equilibrium vapor compositions
    for i = 1:ns
        y(i) = (alpha*x(i)) / (1.0 + (alpha-1.0)*x(i));
    end

    % --- Material Balances ---

    % Overhead accumulator (Stage 1)
    xdot(1) = (1/md) * (vr*y(2) - (dist+reflux)*x(1));

    % Rectifying (top) section (Stages 2 to nf-1)
    for i = 2:nf-1
        xdot(i) = (1/mt) * (lr*x(i-1) + vr*y(i+1) - lr*x(i) - vr*y(i));
    end

    % Feed stage (Stage nf)
    xdot(nf) = (1/mt) * (lr*x(nf-1) + vs*y(nf+1) - ls*x(nf) - vr*y(nf) + feed*zfeed);

    % Stripping (bottom) section (Stages nf+1 to ns-1)
    for i = nf+1:ns-1
        xdot(i) = (1/mt) * (ls*x(i-1) + vs*y(i+1) - ls*x(i) - vs*y(i));
    end

    % Reboiler (Stage ns)
    xdot(ns) = (1/mb) * (ls*x(ns-1) - lbot*x(ns) - vs*y(ns));

end