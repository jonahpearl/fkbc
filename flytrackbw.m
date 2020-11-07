function [ arena_rev_nbg_bw ] = flytrackbw( Arena, ij, background, gamma, custom_bw_threshold_modifier)
%flytrackbw subtracts background from and threshold each frame for the program
%   Detailed explanation goes here

% Subtract background
arena_rev_nbg = Arena(:,:,ij) - background;

% Apply gamma
arena_rev_nbg = imadjust(arena_rev_nbg, [0 0.5],[0 1],gamma); % Re-adjust gamma. Numbers can be optimized.

% Use X times stdev above the mean to threshold
% arena_rev_nbg_bw = im2bw(arena_rev_nbg ,...
% custom_bw_threshold_modifier * std( reshape( mat2gray( arena_rev_nbg ) , 1 , [] ))...
% + mean( reshape( mat2gray( arena_rev_nbg ) , 1 , [] )));
arena_rev_nbg_bw = imbinarize(arena_rev_nbg); % trust MATLAB's imbinarize

end

