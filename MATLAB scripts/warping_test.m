clc, clear, close all

x = sin(0:pi/64:pi);
[~, max_index] = max(x);

% figure;
% subplot(2,1,1);
% plot(x);

% subplot(2,1,2);
[warp_x, ~] = asymWarp(x, max_index, 13);
% plot(warp_x);
