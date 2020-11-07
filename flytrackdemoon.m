function [ arena_rev_nbg_bw, Flag ] = flytrackdemoon( arena_rev_nbg_bw, demoon_cutoff)
%flytrackdemoon demoons a frame if necessary
%   Detailed explanation goes here

% Label the bw image to for demooning
[tobedemooned,n2testdemooned]=bwlabel(arena_rev_nbg_bw);

% Get the extrema of regions to determine whether they should be demooned
tobedemooned_struct = regionprops(tobedemooned,'Extrema');  

% default demoon flag is 0;
demoonflag = 0;

for shade_ind = 1 : n2testdemooned
    
    % Calculate the box size of each shade
	shade_size = range( tobedemooned_struct( shade_ind ).Extrema );
    
    % Determine whether a shade should be eliminated
    if shade_size(1) * shade_size(2) > demoon_cutoff
        % Flag it
        demoonflag = 1;
        
        % Eliminate the shade
        tobedemooned( tobedemooned == shade_ind ) = 0;
    end
end

Flag = demoonflag * 10;
    
arena_rev_nbg_bw=tobedemooned>0;

end

