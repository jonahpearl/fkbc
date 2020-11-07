function [ ranking2 ] = flyarenarank( arena_rank, n_arenas )
%flyarenarank ranks the arenas of the fly universe based on their position
%   Detailed explanation goes here

% Get the centroids of the arenas and reshape them into matrices
ranking_struct = regionprops( arena_rank );
ranking_mat = reshape( [ ranking_struct.Centroid ]' , 2 , [] )';

% Prime the ranking output
ranking2=zeros(n_arenas,1);

% Use sorting to rank the arenas
for i=1 : ceil( n_arenas / 4 )
    [ ~ , rankingtemp2 ] = sort( ranking_mat( ( i - 1 ) * 4 +...
        1 : min( ( i - 1 ) * 4 + 4 , n_arenas ) , 2 ) );
    ranking2( ( i - 1 ) * 4 + 1 : min( ( i - 1 ) * 4 + 4 , n_arenas ) ) = rankingtemp2 + ( i - 1 ) * 4;
end

end

