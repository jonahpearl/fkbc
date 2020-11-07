function [ areas2keep_final ] = flytrackreduction( tobereducedarena_lb , nfly )
%flytrackreduction reduces the number of flies detected on each frame
%   Detailed explanation goes here

% Get the areas of all regions
tobedeletedarea_struct = regionprops( tobereducedarena_lb, 'Area' );
tobedeletedarea = [ tobedeletedarea_struct.Area ];

% Sort the areas from large to small
[ ~, indices2keep ]=sort( tobedeletedarea , 2, 'descend' );

% Keep the largest ones
indices2keep = indices2keep( 1 : nfly );

% Prime an arena to keep (as a boolean matrix)
areas2keep = tobereducedarena_lb > 99999;

% Find the areas to keep and keep them
for j=1:nfly
    areas2keep = areas2keep + (tobereducedarena_lb > 0) .* ( tobereducedarena_lb == indices2keep( j ) );
end

% Output
areas2keep_final = bwlabel(areas2keep);

end

