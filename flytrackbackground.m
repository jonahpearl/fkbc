function [ background ] = flytrackbackground( Arena, FPS, nframe, settings_file )
%flytrackbackground calculate the background for flytrack
%   Detailed explanation goes here

% Determine the secs used for background calculation for intensity thresholding
% background_calc_end_time = settings_file{11};
% background_calc_end_time = str2double(background_calc_end_time(strfind(background_calc_end_time, ',')+1:end));
background_calc_end_time = settings_file.data(6);

% Determine the frames used for background calculation for intensity
% thresholding (actual number fluctuates +/-1)
% nframe2calcback = settings_file{12};
% nframe2calcback = str2double(nframe2calcback(strfind(nframe2calcback, ',')+1:end));
nframe2calcback = settings_file.data(7);

% Calculate the last frame used to calculate background
backcalcskip_endframe = min(nframe - 1 , round( background_calc_end_time * FPS + 1 ));

% Calculate how many frames to skip to sample background frames
nbackcalcskip = round(backcalcskip_endframe / nframe2calcback);

% Form the background calculation stack
backgroundcalcstack=Arena(:,:,1:nbackcalcskip:backcalcskip_endframe);

% Use median to calculate the background
background=uint8(median(single(backgroundcalcstack),3));

end

