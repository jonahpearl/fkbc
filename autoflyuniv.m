function [ flyuniverse, flyuniverse_props, n_arenas ] = ...
    autoflyuniv( Mov, cropindices12, cropindices34, channel2choose, ...
    flyuniverse_bw_threshold, flyuniverse_disk_size )
%autoflyuniv automatically determines the well locations in the OFER plate.
%It locks the max number of wells as 32.
%   Detailed explanation goes here

flyuniverse = Mov(cropindices12,cropindices34,channel2choose);

flyuniverse_bw = im2bw(flyuniverse,flyuniverse_bw_threshold);

flyuniverse_bw_opened = imopen(imfill(flyuniverse_bw,'holes'),strel('disk',flyuniverse_disk_size));

[flyuniverse_bw_opened_labeled,n_arenas] = bwlabel(flyuniverse_bw_opened);

flyuniverse_props = regionprops(flyuniverse_bw_opened_labeled,'Extrema','Area');

% if there are more than 32 arenas, keep only the largest 32 ones.
if n_arenas > 32
    
    areas = cell2mat({flyuniverse_props.Area});
    
    [ ~ , arena_rank] = sort( areas, 'descend' );
    
    % Throw away all areas that are ranked 33 or later
    arena2discard = arena_rank(33 : end);
    
    % Throw away extra arenas
    for i = 1 : length(arena2discard)
       
        flyuniverse_bw_opened_labeled(flyuniverse_bw_opened_labeled == arena2discard(i)) = 0;
        
    end
    
    flyuniverse_bw_opened = flyuniverse_bw_opened_labeled > 0;
    
    [flyuniverse_bw_opened_labeled,n_arenas] = bwlabel(flyuniverse_bw_opened);
    
    flyuniverse_props = regionprops(flyuniverse_bw_opened_labeled,'Extrema','Area');

end

end

