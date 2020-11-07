function lastImage = warmupcamera(camera, n)

for i = 1:n
    im = snapshot(camera);
end
lastImage = im;

end