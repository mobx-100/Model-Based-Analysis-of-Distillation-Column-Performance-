function example_M10_1_gain
    % Parameters (Example M10.1)
    global DIST_PAR
    alpha  = 1.5;
    NS     = 41;   % total stages
    NF     = 21;   % feed stage
    F      = 1.0;  % feed mol/min
    zF     = 0.5;  % feed composition
    qF     = 1.0;  % saturated liquid
    D      = 0.5;  % distillate mol/min
    
    % Derived values 
    R_nom  = 2.706; 
    B  = F - D;           % bottoms flow
    Ls = R_nom + F*qF;    % stripping liquid
    V  = Ls - B;          % reboiler vapor
    
    % Range of reflux values
    R_vals = linspace(2.66, 2.74, 15);
    xD = zeros(size(R_vals)); % distillate composition
    xB = zeros(size(R_vals)); % bottoms composition
    
    for k = 1:length(R_vals)
        R = R_vals(k);
        DIST_PAR = [alpha NS NF F zF qF R V];
        
        % Initial guess
        x0 = linspace(0.9,0.01,NS);
        
        % Solve steady state
        options = optimoptions('fsolve','Display','off','TolFun',1e-9,'TolX',1e-9);
        x = fsolve(@dist_ss, x0, options);
        
        % Store outputs
        xD(k) = x(1);     % distillate composition
        xB(k) = x(end);   % bottoms composition
    end
    
    % Plot results
    figure;
    subplot(2,1,1);
    plot(R_vals, xD,'b-o','LineWidth',1.5);
    xlabel('Reflux (mol/min)'); ylabel('Distillate composition (x_1)');
    title('Input–Output Relationship: Distillate vs Reflux');
    grid on;
    
    subplot(2,1,2);
    plot(R_vals, xB,'r-s','LineWidth',1.5);
    xlabel('Reflux (mol/min)'); ylabel('Bottoms composition (x_{41})');
    title('Input–Output Relationship: Bottoms vs Reflux');
    grid on;
    
    fprintf('At R=%.3f, Distillate xD=%.3f, Bottoms xB=%.3f\n', ...
            R_nom, xD(R_vals==R_nom), xB(R_vals==R_nom));
end

function f = dist_ss(x)
    global DIST_PAR
    alpha = DIST_PAR(1); NS = DIST_PAR(2); NF = DIST_PAR(3);
    F = DIST_PAR(4); zF = DIST_PAR(5); qF = DIST_PAR(6);
    R = DIST_PAR(7); V = DIST_PAR(8);
    
    % Flowrates
    Lr = R;          % rectifying liquid
    Ls = R + F*qF;   % stripping liquid
    Vr = V + F*(1-qF); % rectifying vapor
    Vs = V;          % stripping vapor
    Dist = Vr - R;
    B = Ls - Vs;
    
    % Equilibrium relation
    y = alpha*x ./ (1 + (alpha-1).*x);
    
    f = zeros(NS,1);
    
    % Stage 1 (overhead condenser)
    f(1) = Vr*y(2) - (Dist+R)*x(1);
    
    % Rectifying section (2..NF-1)
    for i=2:NF-1
        f(i) = Lr*x(i-1) + Vr*y(i+1) - Lr*x(i) - Vr*y(i);
    end
    
    % Feed stage
    f(NF) = Lr*x(NF-1) + Vs*y(NF+1) + F*zF ...
            - Ls*x(NF) - Vr*y(NF);
    
    % Stripping section (NF+1..NS-1)
    for i=NF+1:NS-1
        f(i) = Ls*x(i-1) + Vs*y(i+1) - Ls*x(i) - Vs*y(i);
    end
    
    % Reboiler (stage NS)
    f(NS) = Ls*x(NS-1) - B*x(NS) - Vs*y(NS);
end
