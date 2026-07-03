function F = dist_ss(x)
% dist_ss - steady-state residuals for binary distillation

global DIST_PAR_GLOBAL
dp = DIST_PAR_GLOBAL;

alpha  = dp(1);
ns     = round(dp(2));
nf     = round(dp(3));
F_in   = dp(4);
zF     = dp(5);
qF     = dp(6);
R      = dp(7);
V      = dp(8);

% Derived flows
Lr = R;
Ls = R + F_in*qF;
Vr = V + F_in*(1-qF);
Vs = V;

D  = Vr - Lr;
B  = Ls - Vs;

% Vapor-liquid equilibrium
y = (alpha .* x) ./ (1 + (alpha - 1).* x);

F = zeros(ns,1);

% -----------------------------------
% Condenser (stage 1)
% -----------------------------------
if ns > 1
    F(1) = Vr*y(2) - (D + Lr)*x(1);
else
    F(1) = - (D + Lr)*x(1);  % degenerate case
end

% -----------------------------------
% Rectifying section (2..nf-1)
% -----------------------------------
for i = 2:(nf-1)
    F(i) = Lr*x(i-1) + Vr*y(i+1) - Lr*x(i) - Vr*y(i);
end

% -----------------------------------
% Feed stage
% -----------------------------------
if nf < ns
    F(nf) = Lr*x(nf-1) + Vs*y(nf+1) - Lr*x(nf) - Vs*y(nf) + F_in*zF;
else
    % feed on last stage? treat carefully
    F(nf) = Lr*x(nf-1) - Lr*x(nf) - Vs*y(nf) + F_in*zF;
end

% -----------------------------------
% Stripping section (nf+1..ns-1)
% -----------------------------------
for i = (nf+1):(ns-1)
    F(i) = Ls*x(i-1) + Vs*y(i+1) - Ls*x(i) - Vs*y(i);
end

% -----------------------------------
% Reboiler (stage ns)
% -----------------------------------
if ns > 1
    F(ns) = Ls*x(ns-1) - B*x(ns) - Vs*y(ns);
end

end
