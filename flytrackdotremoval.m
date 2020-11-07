function [ force_segmented_lb_final, nfly_final, Flag ] = flytrackdotremoval( tobeforcesegmented, nfly, Flag)
%flytrackdotremoval removes dots from the frame to segment out 2 flies
%   Detailed explanation goes here
% disp('Watershedding Unsuccessful')
% disp(['Frame ' , num2str(i) , ' Forced Segmenting'])
% fforce_seg=[fforce_seg;i];

% Create a list of dots to remove
tobeforcesegmented_dist=bwdist(~tobeforcesegmented);
force_zero_cand_index=find(tobeforcesegmented_dist==1);

% Default force segmentation unsuccessful
internalflag = 0;

for j=1 : length( force_zero_cand_index )
    % Prime a matrix to tryout the force segmentation
    force_segment_try = tobeforcesegmented;
    
    % Remove the dot
    force_segment_try( force_zero_cand_index(j) ) = 0;
    
    % See if this gives 2 flies
    [force_segmented_lb , force_segmented_nfly_det] = bwlabel(force_segment_try);
    
    % if yes, flag it and output the labeled frame
    if force_segmented_nfly_det == nfly;
        force_segmented_lb_final = force_segmented_lb;
        internalflag = 4;
        
        % Change the number of flies detected too.
        nfly_final = nfly;
        break
    end
end

% If dot removal is unsucessful, leave the labeled frame unchanged.
if internalflag == 0
    force_segmented_lb_final = tobeforcesegmented;
    nfly_final = 1;
end

% Output flag
Flag = Flag + internalflag;

end

