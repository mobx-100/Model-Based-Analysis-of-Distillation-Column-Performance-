function xdot = dist_dyn(t, x)
% dist_dyn - time derivatives for liquid stage compositions
% Uses global DIST_PAR_dyn and DEFAULT_STEPS_GLOBAL
global DIST_PAR_dyn DEFAULT_STEPS_GLOBAL
if isempty(DIST_PAR_dyn)
    error('DIST_PAR_dyn not set');
end
dp = DIST_PAR_dyn;

alpha = dp(1);
ns = round(dp(2));
nf = round(dp(3));
feed_i = dp(4);
zfeed_i = dp(5);
qf = dp(6);
reflux_i = dp(7);
vapor_i = dp(8);
md = dp(9);    % overhead receiver holdup (stage 1)
mb = dp(10);   % reboiler holdup (stage ns)
mt = dp(11);   % interior tray holdup default

% check for feed tray holdup (mf)
if length(dp) >= 12 && dp(12) > 0
    mf = dp(12);
else
    mf = 0.5;
end

% default steady inputs
reflux = reflux_i;
vapor  = vapor_i;
feed   = feed_i;
zfeed  = zfeed_i;

% apply global step changes
if ~isempty(DEFAULT_STEPS_GLOBAL)
    for s = 1:length(DEFAULT_STEPS_GLOBAL)
        st = DEFAULT_STEPS_GLOBAL(s);
        if t >= st.time
            switch lower(st.type)
                case 'reflux'
                    reflux = reflux_i + st.mag;
                case 'vapor'
                    vapor = vapor_i + st.mag;
                case 'feed'
                    feed = feed_i + st.mag;
                case 'zfeed'
                    zfeed = zfeed_i + st.mag;
            end
        end
    end
end

% derived flows
lr = reflux;                      
ls = reflux + feed*qf;            
vr = vapor + feed*(1-qf);         
vs = vapor;                       

dist = vr - lr;
lbot = ls - vs;

% build per-stage holdup vector M(i)
M = ones(ns,1) * mt;  
M(1) = md;            
M(ns) = mb;           
M(nf) = mf;           

% clamp x to [0,1] to prevent drift
x = min(max(x, 0), 1);

% equilibrium vapor compositions
y = (alpha .* x) ./ (1 + (alpha - 1).* x);
y = min(max(y, 0), 1);  % clamp y to [0,1]

xdot = zeros(ns,1);

% overhead receiver xdot(1)
xdot(1) = (1 / M(1)) * ( vr * y(2) - (dist + lr) * x(1) );

% rectifying section i = 2 .. nf-1
for i = 2:(nf-1)
    xdot(i) = (1 / M(i)) * ( lr * x(i-1) + vr * y(i+1) - lr * x(i) - vr * y(i) );
end

% feed stage nf
xdot(nf) = (1 / M(nf)) * ( lr * x(nf-1) + vs * y(nf+1) - lr * x(nf) - vs * y(nf) + feed * zfeed );

% stripping section i = nf+1 .. ns-1
for i = (nf+1):(ns-1)
    xdot(i) = (1 / M(i)) * ( ls * x(i-1) + vs * y(i+1) - ls * x(i) - vs * y(i) );
end

% reboiler stage ns
xdot(ns) = (1 / M(ns)) * ( ls * x(ns-1) - lbot * x(ns) - vs * y(ns) );

end
