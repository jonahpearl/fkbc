function [ Mov, cropindex1_manual, cropindex2_manual, cropindex3_manual, cropindex4_manual ]...
    = flyunivmanual( Mov, channel2choose )
%flyunivmanual manually define the boundaries of the fly universe
%   Detailed explanation goes here

    figure(99)
    
    imshow(Mov(:,:,channel2choose))
    
    croptangle=imrect;
    
    position_manual=wait(croptangle);
    
    close 99
    
    cropindex1_manual=round(position_manual(2));
    
    cropindex2_manual=round(position_manual(4))+round(position_manual(2));
    
    cropindex3_manual=round(position_manual(1));
    
    cropindex4_manual=round(position_manual(3))+round(position_manual(1));
end

