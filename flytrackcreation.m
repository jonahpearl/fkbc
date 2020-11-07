function [ post_create_lb] = flytrackcreation( tocreatefly, nfly)
%flytrackcreation creates a fly in the frame to overcome an extreme
%situation. This function pretty much solves the problem, in a very blunt
%way.
%   Detailed explanation goes here

%disp('Internal Ring Removal Unsuccessful') % In this very extreme case, the two flies are essentially on top of each other
%disp('Fly Created')

npixels = length(tocreatefly(:));

if max(tocreatefly(:)) == 0
    % If the frame is completely empty, well, it's time to randomly create.
    pixel2create = round( rand * ( npixels - nfly + 1 ) );
    tocreatefly( pixel2create ) = 1;
    tocreatefly( pixel2create + (1 : (nfly - 1) ) ) = 2 : nfly;
else
    % If there is an object in the frame, find its last pixel
    pixel2create = find( tocreatefly > 0, 1, 'last' );
    
    if pixel2create > ( npixels - nfly + 1 )
        % If there is not enough space to create after this pixel, create
        % before it
        tocreatefly( pixel2create - (1 : (nfly - 1) ) ) = 2 : nfly;
    else
        % If there is enough space to create after this pixel, create after
        % it
        tocreatefly( pixel2create + (1 : (nfly - 1) ) ) = 2 : nfly;
    end
end

% Output the creation result
post_create_lb = tocreatefly;

end

