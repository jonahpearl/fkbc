function [ exring_lb_final, nfly_final, Flag ] = flytrackexring( tobeexringed, nfly, Flag )
%flytrackexring removes the external ring of the object 
%   Detailed explanation goes here

% Prepare the ring to remove
tobeforcesegmented_dist = bwdist( ~tobeexringed );
tobeexringed( tobeforcesegmented_dist>=1 & tobeforcesegmented_dist<2 ) = 0;

% Label it to see if it worked or not
[ post_exringed_lb , nfly_post_exringed ] = bwlabel( tobeexringed );

if nfly_post_exringed == nfly;
    % If exring worked, prepare to output
    exring_lb_final = post_exringed_lb;
    Flag = Flag + 5;
else
    % If not, leave everything untouched
    exring_lb_final = tobeexringed;
    Flag = Flag + 0;
end

% Output the number of flies detected
nfly_final = nfly_post_exringed;

end

