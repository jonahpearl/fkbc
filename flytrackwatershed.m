function [ postwatershed_final, nflydetected_final, Flag ] = flytrackwatershed( tobewatershed, nfly, Flag )
%flytrackwatershed watershed a frame if needed. It also prevents
%overwatershedding
%   Detailed explanation goes here
%fwatershed=[fwatershed;i];

% Determine bounds between areas
shedbound = watershed(-bwdist(~tobewatershed));

% Clean the bounds
tobewatershed(shedbound==0) = 0;

% See if watershedding is successful
[postwatershed,nflydetected] = bwlabel(tobewatershed);

if nflydetected > nfly % Anti-overwatershed

    %fanti_overshed=[fanti_overshed;i];
    tobeantiovershed = postwatershed; % Automatic anti-overshedding sounds pretty difficult, so for now, I will choose the two deepest sinks as fly approximations.
    tobewatershed( tobeantiovershed > 2 ) = 0;  
    [postwatershed_final,nflydetected]=bwlabel(tobewatershed);
    Flag = Flag + 3;
elseif nflydetected == nfly % Overshedding successful
    Flag = Flag + 2;
    postwatershed_final = postwatershed;
else
    Flag = Flag + 0; % Overshedding unsuccessful
    postwatershed_final = tobewatershed;
end

nflydetected_final = nflydetected;

end

