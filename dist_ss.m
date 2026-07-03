function f = dist_ss(x)

global DIST_PAR

if length(DIST_PAR) < 8
    disp('not enough parameters given in DIST_PAR')
    disp(' ')
    disp('check to see that global DIST_PAR has been defined')
    return
end

alpha = DIST_PAR(1); % relative volatility (2.5)
ns = DIST_PAR(2);    % total number of stages (3)
nf = DIST_PAR(3);    % feed stage (2)
feed = DIST_PAR(4);  % feed flowrate (1)
zfeed = DIST_PAR(5); % feed composition, light comp (0.5)
qf = DIST_PAR(6);    % feed quality (1 = sat'd liqd, 0 = sat'd vapor) (1)
reflux = DIST_PAR(7);% reflux flowrate (3)
vapor = DIST_PAR(8); % reboiler vapor flowrate (3.5)



% rectifying and stripping section liquid flowrates
lr = reflux;
ls = reflux + feed*qf;

% rectifying and stripping section vapor flowrates
vs = vapor;
vr = vs + feed*(1-qf);

% distillate and bottoms rates
dist = vr - reflux;
lbot = ls - vs;

if dist < 0
    disp('error in specifications, distillate flow < 0')
    return
end

if lbot < 0
    disp('error in specifications, stripping section ')
    disp(' ')
    disp('liquid flowrate is negative')
    return
end

% zero the function vector
f = zeros(ns,1);

% calculate the equilibrium vapor compositions
for i = 1:ns
    y(i) = (alpha*x(i)) / (1.0 + (alpha-1.0)*x(i));
end

% material balances

% overhead receiver
f(1) = (vr*y(2) - (dist+reflux)*x(1));

% rectifying (top) section
for i = 2:nf-1
    f(i) = lr*x(i-1) + vr*y(i+1) - lr*x(i) - vr*y(i);
end

% feed stage
f(nf) = lr*x(nf-1) + vs*y(nf+1) - ls*x(nf) - vr*y(nf) + feed*zfeed;

% stripping (bottom) section
for i = nf+1:ns-1
    f(i) = ls*x(i-1) + vs*y(i+1) - ls*x(i) - vs*y(i);
end

% reboiler
f(ns) = (ls*x(ns-1) - lbot*x(ns) - vs*y(ns));

end