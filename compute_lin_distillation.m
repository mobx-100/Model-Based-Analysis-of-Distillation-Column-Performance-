% compute_lin_distillation.m
% Computes steady-state from dist_ss.m, numerically linearizes the dynamics
% (A,B matrices), forms C and builds state-space and transfer functions.
% Requires dist_ss.m and dist_dyn.m from Bequette Module 10 to be on the path.
% (c) 2025 - example script

clear; close all; clc;
global DIST_PAR

%% --- (1) Define column parameters in DIST_PAR (example values)
% [alpha, ns, nf, feed, zfeed, qf, reflux, vapor, md, mb, mt, ...]
% The dist_* functions expect at least first 11 entries; adjust per your case.
% Example: 41-stage example from Module 10
alpha = 1.5;
ns    = 41;
nf    = 21;
feed  = 1.0;
zfeed = 0.5;
qf    = 1.0;
reflux = 2.706;   % steady reflux (LR)
vapor  = 3.206;   % steady vapor (Vs)
md = 5;  % overhead receiver holdup
mb = 5;  % bottoms holdup
mt = 0.5; % tray holdup

DIST_PAR = zeros(1,19);
DIST_PAR(1) = alpha;
DIST_PAR(2) = ns;
DIST_PAR(3) = nf;
DIST_PAR(4) = feed;
DIST_PAR(5) = zfeed;
DIST_PAR(6) = qf;
DIST_PAR(7) = reflux;  % LR
DIST_PAR(8) = vapor;   % Vs
DIST_PAR(9) = md;
DIST_PAR(10)= mb;
DIST_PAR(11)= mt;
% rest (12:19) left as zero unless you need step options

%% --- (2) Solve steady state with dist_ss.m using fsolve
x0 = 0.5*ones(ns,1); % initial guess
options = optimoptions('fsolve','Display','iter','TolFun',1e-10,'TolX',1e-10);
% dist_ss expects global DIST_PAR. It returns vector x of length ns.
xs = fsolve(@dist_ss,x0,options);    % steady-state liquid compositions
fprintf('Solved steady state, top x1 = %.6f, bottom xN = %.6f\n', xs(1), xs(end));

%% --- (3) Check steady-state residual (should be ~0)
% dist_dyn returns xdot; call it at steady state
xdot0 = dist_dyn(0,xs);
maxRes = max(abs(xdot0));
fprintf('Max steady-state residual |xdot| = %g (should be near 0)\n', maxRes);

%% --- (4) Numerical linearization (finite differences)
n = ns;
m = 2; % inputs: u1 = reflux (DIST_PAR(7)), u2 = vapor (DIST_PAR(8))
A = zeros(n,n);
B = zeros(n,m);

% baseline xdot at steady state (should be ~0)
xdot_base = xdot0;

% finite difference step sizes
eps_x = 1e-6;
eps_u = 1e-6;

% Build A by perturbing each state
for i=1:n
    xp = xs;
    xp(i) = xp(i) + eps_x;
    xdot_p = dist_dyn(0,xp);
    A(:,i) = (xdot_p - xdot_base) / eps_x;
end

% Build B by perturbing each input via DIST_PAR
% Save original DIST_PAR values to restore after perturbation
orig_reflux = DIST_PAR(7);
orig_vapor  = DIST_PAR(8);

% perturb reflux (u1)
DIST_PAR(7) = orig_reflux + eps_u;
xdot_p = dist_dyn(0,xs);
B(:,1) = (xdot_p - xdot_base) / eps_u;

% perturb vapor (u2)
DIST_PAR(7) = orig_reflux; % restore
DIST_PAR(8) = orig_vapor + eps_u;
xdot_p = dist_dyn(0,xs);
B(:,2) = (xdot_p - xdot_base) / eps_u;

% restore original inputs
DIST_PAR(7) = orig_reflux;
DIST_PAR(8) = orig_vapor;

%% --- (5) Build C for outputs [top; bottom]
C = zeros(2,n);
C(1,1) = 1;     % overhead composition y1 = x1
C(2,end) = 1;   % bottoms composition yN = xN

%% --- (6) Display some diagnostics
fprintf('A size: %dx%d, B size: %dx%d, C size: %dx%d\n', size(A,1),size(A,2),size(B,1),size(B,2),size(C,1),size(C,2));
eigA = eig(A);
fprintf('Rightmost eigenvalues of A (real parts):\n');
disp(sort(real(eigA),'descend')');

%% --- (7) Create state-space and transfer function models
sys = ss(A,B,C,0);   % linear LTI sys in deviations
G = tf(sys);         % matrix of TFs (2 outputs x 2 inputs)

% steady-state (DC) gain matrix
G0 = -C*(A\B); % equals C*(0I-A)^{-1}*B
disp('DC gain matrix (y / u) =');
disp(G0);

%% --- (8) Examples: step responses (deviation form)
figure;
subplot(2,1,1);
step(sys(1,1)); title('Step response: overhead x1 to reflux (u1)');
subplot(2,1,2);
step(sys(2,1)); title('Step response: bottoms xN to reflux (u1)');

%% --- (9) Bode and poles/zeros
figure; bode(sys(1,1)); title('Bode: overhead vs reflux');
figure; pzmap(sys); title('Pole-zero map');

%% --- (10) Save A,B,C for later use
save('lin_dist_ABCs.mat','A','B','C','xs','DIST_PAR','G','G0');
fprintf('A,B,C saved to lin_dist_ABCs.mat\n');