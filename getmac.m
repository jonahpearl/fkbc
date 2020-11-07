function [ mac ] = getmac(  )
%getmac obtain the mac address of the computer
%   Detailed explanation goes here
[a,b]=dos('ipconfig/all');
n=findstr([a,b],'Physical');

mac=b(n+35:n+51);

end

