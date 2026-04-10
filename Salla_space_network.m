%% LUNAR CONSTELLATION SIMULATION & SIGNAL GRAPHING
clear; clc; close all;

% --- 1. GLOBAL CONSTANTS ---
MU_EARTH = 3.986004418e14;   % m^3/s^2
R_EARTH  = 6371e3;           % meters
FREQ_HZ  = 12e9;
P_T      = 10.0;             % Watts
G_T      = 2000;
G_R      = 1250.0;
C        = 299792458;        % Speed of light

% Ground Station (GS) position and normal
GS_NORMAL = [0.3453, 0.1888, 0.9194];
GS_POS    = [2199925.3, 1202868.5, 5857351.4];

% --- 2. USER INPUTS ---
num_sats    = input('Enter number of satellites: ');
alt_km      = input('Enter orbit altitude (km): ');
dt          = input('Enter time step (seconds): ');
total_steps = input('Enter total steps: ');

% --- 3. PRESET ORBIT NORMALS (focused around Finland ~25 deg E) ---
% i = 90 degrees (Polar), RAAN range: 20 deg to 47 deg
preset_normals = [ ...
    0.3420, -0.9397, 0.0000;   % RAAN = 20 deg
    0.3907, -0.9205, 0.0000;   % RAAN = 23 deg
    0.4384, -0.8988, 0.0000;   % RAAN = 26 deg
    0.4848, -0.8746, 0.0000;   % RAAN = 29 deg
    0.5299, -0.8480, 0.0000;   % RAAN = 32 deg
    0.5736, -0.8192, 0.0000;   % RAAN = 35 deg
    0.6157, -0.7880, 0.0000;   % RAAN = 38 deg
    0.6561, -0.7547, 0.0000;   % RAAN = 41 deg
    0.6947, -0.7193, 0.0000;   % RAAN = 44 deg
    0.7314, -0.6820, 0.0000;   % RAAN = 47 deg
];

% Per-orbit colour palette (one distinct colour per orbit plane)
orbit_colors = [ ...
    0.25, 0.70, 1.00;   % orbit 1  – NASA blue
    0.30, 1.00, 0.60;   % orbit 2  – mint
    1.00, 0.60, 0.20;   % orbit 3  – amber
    0.90, 0.30, 1.00;   % orbit 4  – violet
    1.00, 0.35, 0.35;   % orbit 5  – coral
    0.20, 0.85, 0.95;   % orbit 6  – cyan
    1.00, 0.90, 0.20;   % orbit 7  – yellow
    0.60, 1.00, 0.30;   % orbit 8  – lime
    0.80, 0.50, 1.00;   % orbit 9  – lavender
    0.95, 0.55, 0.20;   % orbit 10 – orange
];

% --- 4. SATELLITE ASSIGNMENT ---
% Distribute satellites as evenly as possible across the 10 preset orbits.
n_orbits      = size(preset_normals, 1);
base_count    = floor(num_sats / n_orbits);
remainder     = mod(num_sats, n_orbits);
assign_counts = base_count + (1:n_orbits <= remainder);   % extra sat to first orbits

assign_idx = zeros(num_sats, 1);
cur = 1;
for j = 1:n_orbits
    if assign_counts(j) > 0
        assign_idx(cur : cur + assign_counts(j) - 1) = j;
        cur = cur + assign_counts(j);
    end
end

% --- 5. INITIALIZATION ---
alt_m = alt_km * 1000;
r_mag = R_EARTH + alt_m;

sat_positions  = zeros(num_sats, 3);
sat_normals    = zeros(num_sats, 3);
history_signal = nan(total_steps, num_sats);

for i = 1:num_sats
    % Assign orbit normal from preset table
    sat_normals(i, :) = preset_normals(assign_idx(i), :);

    % Build in-plane orthonormal basis
    n_hat = sat_normals(i, :);
    v_ref = [1, 0, 0];
    if abs(dot(v_ref, n_hat)) > 0.9
        v_ref = [0, 1, 0];
    end
    v1 = cross(n_hat, v_ref);
    v1 = v1 / norm(v1);
    v2 = cross(n_hat, v1);

    % Random starting phase so satellites in the same orbit are spread out
    theta = deg2rad(randi([0, 360]));
    sat_positions(i, :) = r_mag * (cos(theta)*v1 + sin(theta)*v2);
end

% --- 6. SETUP 3-D PLOT ---
fig = figure('Color', 'k', 'WindowState', 'maximized');
background('Milky Way');
hold on;

% Draw Earth
opts.Units    = 'm';
opts.RefPlane = 'equatorial';
planet3D('Earth', opts);

% --- 6a. Static orbit rings (coloured per orbit, faint alpha) ---
orbit_theta = linspace(0, 2*pi, 361);

for i = 1:num_sats
    n_hat = sat_normals(i, :);
    v_ref = [1, 0, 0];
    if abs(dot(v_ref, n_hat)) > 0.9, v_ref = [0, 1, 0]; end
    v1 = cross(n_hat, v_ref);  v1 = v1 / norm(v1);
    v2 = cross(n_hat, v1);

    ox = r_mag * (cos(orbit_theta)*v1(1) + sin(orbit_theta)*v2(1));
    oy = r_mag * (cos(orbit_theta)*v1(2) + sin(orbit_theta)*v2(2));
    oz = r_mag * (cos(orbit_theta)*v1(3) + sin(orbit_theta)*v2(3));

    % Colour matches the satellite dot for this orbit
    orb_idx = assign_idx(i);
    clr = orbit_colors(mod(orb_idx - 1, size(orbit_colors, 1)) + 1, :);

    plot3(ox, oy, oz, '-', ...
        'Color',    [clr, 0.22], ...   % same hue as dot, low alpha
        'LineWidth', 0.6, ...
        'Clipping',  'off');
end

% --- 6b. Satellite dot handles (coloured per orbit) ---
h_dot = gobjects(num_sats, 1);
for i = 1:num_sats
    orb_idx = assign_idx(i);
    clr     = orbit_colors(mod(orb_idx - 1, size(orbit_colors, 1)) + 1, :);
    clr_edge = min(clr * 1.35, 1);   % brightened edge for contrast

    h_dot(i) = plot3(NaN, NaN, NaN, 'o', ...
        'MarkerSize',      7, ...
        'Color',           clr_edge, ...
        'MarkerFaceColor', clr, ...
        'LineStyle',       'none', ...
        'Clipping',        'off');
end

% --- 6c. Ground station marker ---
plot3(GS_POS(1), GS_POS(2), GS_POS(3), '^', ...
    'MarkerSize',      10, ...
    'Color',           [1.0, 0.85, 0.0], ...
    'MarkerFaceColor', [1.0, 0.55, 0.0], ...
    'LineStyle',       'none', ...
    'Clipping',        'off', ...
    'DisplayName',     'Ground Station');

% Radiating ring around GS
gs_ring_r = R_EARTH * 0.08;
gs_ang    = linspace(0, 2*pi, 64);
plot3(gs_ring_r*cos(gs_ang), gs_ring_r*sin(gs_ang), ...
      repmat(GS_POS(3), 1, 64), '-', ...
      'Color', [1.0, 0.75, 0.0], 'LineWidth', 1.2, 'Clipping', 'off');

view(3); axis equal; grid off;
title('Satellite Constellation', 'Color', 'w');

% Freeze camera
ax3d = gca;
ax3d.CameraViewAngleMode = 'manual';
ax3d.CameraPositionMode  = 'manual';
ax3d.CameraTargetMode    = 'manual';
ax3d.CameraUpVectorMode  = 'manual';

% --- 7. INSET SIGNAL PLOT (bottom-right) ---
annotation(fig, 'rectangle', [0.655, 0.02, 0.335, 0.265], ...
    'Color', 'none', 'FaceColor', [0, 0, 0], 'FaceAlpha', 0.60);

ax_sig = axes('Parent', fig, 'Position', [0.665, 0.030, 0.320, 0.235]);
set(ax_sig, ...
    'Color',     [0.05, 0.06, 0.12], ...
    'XColor',    [0.70, 0.70, 0.70], ...
    'YColor',    [0.70, 0.70, 0.70], ...
    'GridColor', [0.20, 0.20, 0.20], ...
    'GridAlpha',  0.8, ...
    'FontSize',   8, ...
    'Box',       'on', ...
    'TickDir',   'in');
grid(ax_sig, 'on');
hold(ax_sig, 'on');

xlabel(ax_sig, 'Time Step',         'Color', [0.70, 0.70, 0.70], 'FontSize', 8);
ylabel(ax_sig, 'Max Signal  (dBm)', 'Color', [0.70, 0.70, 0.70], 'FontSize', 8);
title(ax_sig, 'Max received signal', 'Color', 'w', 'FontSize', 9, 'FontWeight', 'normal');
xlim(ax_sig, [1, total_steps]);

% Y-axis limits from Friis equation at closest / farthest plausible distance
d_close = alt_m;
d_far   = sqrt((R_EARTH + alt_m)^2 + R_EARTH^2);
lambda  = C / FREQ_HZ;
dbm_hi  = 10*log10(P_T * G_T * G_R * (lambda / (4*pi*d_close))^2 * 1000);
dbm_lo  = 10*log10(P_T * G_T * G_R * (lambda / (4*pi*d_far  ))^2 * 1000);
ylim(ax_sig, [dbm_lo - 4, dbm_hi + 4]);

% Parameter annotation inside the inset
freq_str   = sprintf('Frequency: %.3g Hz', FREQ_HZ);
gt_str     = sprintf('Transmitter Gain: %.2f', G_T);
gr_str     = sprintf('Receiver Gain: %.2f', G_R);
pt_str     = sprintf('Tx Power: %.3g W', P_T);
params_txt = sprintf('%s\n%s\n%s\n%s', freq_str, gt_str, gr_str, pt_str);

annotation('textbox', [0.75, 0.215, 0.14, 0.09], ...
    'String',          params_txt, ...
    'Interpreter',     'none', ...
    'EdgeColor',       'none', ...
    'Color',           [0.95, 0.95, 0.95], ...
    'FontSize',        8, ...
    'BackgroundColor', [0, 0, 0, 0.45], ...
    'FitBoxToText',    'off');

h_sig_line = plot(ax_sig, NaN, NaN, '-',  'Color', [0.10, 0.95, 0.45], 'LineWidth', 1.5);
h_sig_dot  = plot(ax_sig, NaN, NaN, 'o',  'Color', [1.00, 0.75, 0.10], ...
    'MarkerFaceColor', [1.00, 0.75, 0.10], 'MarkerSize', 6);

% History buffers for inset
rt_steps  = zeros(1, total_steps);
rt_signal = NaN(1, total_steps);

% --- 8. SIMULATION LOOP ---
t_ind = 0;
for t = 1:dt:total_steps
    t_ind       = t_ind + 1;
    best_signal = -inf;

    for i = 1:num_sats
        % --- Orbital mechanics (Euler integration) ---
        r_vec = sat_positions(i, :);
        n_hat = sat_normals(i, :);
        r     = norm(r_vec);

        v_mag = sqrt(MU_EARTH / r);
        v_dir = cross(n_hat, r_vec);
        v_dir = v_dir / norm(v_dir);
        v_vec = v_mag * v_dir;

        a_vec = -MU_EARTH * r_vec / r^3;
        v_new = v_vec + a_vec * dt;
        r_new = r_vec + v_new * dt;

        sat_positions(i, :) = r_new;

        % --- Communications link (Friis equation) ---
        is_visible = dot(r_new, GS_NORMAL) > 0;

        if is_visible
            dist      = norm(r_new - GS_POS);
            wavelength = C / FREQ_HZ;
            path_loss  = (wavelength / (4 * pi * dist))^2;
            p_r        = P_T * G_T * G_R * path_loss;
            history_signal(t_ind, i) = 10 * log10(p_r * 1000); % dBm

            if history_signal(t_ind, i) > best_signal
                best_signal = history_signal(t_ind, i);
            end
        end

        % Update dot position in 3-D plot
        set(h_dot(i), 'XData', r_new(1), 'YData', r_new(2), 'ZData', r_new(3));
    end

    % --- Update inset signal graph ---
    rt_steps(t_ind) = t;
    if best_signal > -inf
        rt_signal(t_ind) = best_signal;
    end
    set(h_sig_line, 'XData', rt_steps(1:t_ind), 'YData', rt_signal(1:t_ind));
    set(h_sig_dot,  'XData', t,                 'YData', rt_signal(t_ind));

    drawnow;
end