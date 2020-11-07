function [ CentroidsA, CentroidsB, FlyA, FlyB ] = flytrackdesignation( Centroids, nframe )
%flytrackdesignation determines which centroids belong to the same fly
%using a minimal inter-frame travel optimization protocol. This function
%currently only works with 2 flies
%   Detailed explanation goes here

% Calculate the x-y movements from the previous frame
potentialmove = [ Centroids( 2 : end , : , 1 ) - Centroids( 1 : end - 1 , : , 1 ) ,...
    Centroids( 2 : end , : , 1 ) - Centroids( 1 : end - 1 , : , 2 )]; % [fly1-fly1xmov fly1-fly1ymov fly1-fly2xmov fly1-fly2ymov]

% Calculate the distance moved from the previous frame
potentialdis = [ sqrt( potentialmove( : , 1 ) .^ 2 + potentialmove( : , 2 ) .^ 2 ) ,...
    sqrt( potentialmove( : , 3 ) .^ 2 + potentialmove( : , 4 ) .^ 2 ) ];

% Determine if the default assignments are optimal or not
shorter_or_not=potentialdis(:,1)<potentialdis(:,2);

% Prime a logical frame of designation
FlyA = zeros( nframe , 2 );
FlyB = zeros( nframe , 2 );

% Set the default
FlyA( 1 , : ) = [ 1 0 ];
FlyB( 1 , : ) = [ 0 1 ];

% Designation
FlyA( 2 : end , 1 ) = shorter_or_not;
FlyA( 2 : end , 2 ) = ~shorter_or_not;
FlyB( 2 : end , 1 ) = ~shorter_or_not;
FlyB( 2 : end , 2 ) = shorter_or_not;

% Deisgnate the centroids to output
CentroidsA = Centroids( : , : , 1 ) .* [ FlyA( : , 1 ) , FlyA( : , 1 ) ] + Centroids( : , : , 2 ) .* [ FlyA( : , 2 ) , FlyA( : , 2 )];
CentroidsB = Centroids( : , : , 1 ) .* [ FlyB( : , 1 ) , FlyB( : , 1 ) ] + Centroids( : , : , 2 ) .* [ FlyB( : , 2 ) , FlyB( : , 2 )];


end

