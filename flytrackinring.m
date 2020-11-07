function [ inring_lb_final, nfly_final, Flag ] = flytrackinring( tobeinringed, nfly, Flag )
%flytrackinring removes the internal ring of the object
%   Detailed explanation goes here

% Removes the internal ring
tobeforcesegmented_dist = bwdist( ~tobeinringed );
tobeinringed( tobeforcesegmented_dist>=2 & tobeforcesegmented_dist<=3 ) = 0;

% Label to see if internal ring removal worked or not
[ inring_lb, nfly_final ] = bwlabel( tobeinringed );

if nfly_final == nfly
    % If worked, output the labeled file and new FLAG
    inring_lb_final = inring_lb;
    Flag = Flag + 6;
else
    % If not, leave everything untouched
    inring_lb_final = tobeinringed;
    Flag = Flag + 0;
end

end

