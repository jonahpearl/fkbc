function [inter_fly_dist, Flags, background] = flytrack(Arena, FPS, vid_num, arena_num, settings_file, quietmode, backgroundInput)


%%%%%%%%%%%%%%%% Flytrack %%%%%%%%%%%%%%%%%
%%%%%%%%%%%% Harvard University %%%%%%%%%%%
%%%%%%%%%%%%%%% Rogulja Lab %%%%%%%%%%%%%%%
%%%%%%%%%%% Crickmore Research %%%%%%%%%%%%
%%%%%%% Programmed by Stephen Zhang %%%%%%%
%%%%%%%%% Version 0.10 08/24/2013 %%%%%%%%%
%%%%%%%%% Version 0.20 08/25/2013 %%%%%%%%%
%%%%%%%%% Version 0.30 08/26/2013 %%%%%%%%%
%%%%%%%%% Version 0.31 09/10/2013 %%%%%%%%%
%%%%%%%%% Version 0.32 09/11/2013 %%%%%%%%%
%%%%%%%%% Version 0.40 09/14/2013 %%%%%%%%%
%%%%%%%%% Version 0.41 09/16/2013 %%%%%%%%%
%%%%%%%%% Version 0.42 09/20/2013 %%%%%%%%%
%%%%%%%%% Version 0.50 09/21/2013 %%%%%%%%%
%%%%%%%%% Version 0.60 09/22/2013 %%%%%%%%%
%%%%%%%%% Version 0.63 09/26/2013 %%%%%%%%%
%%%%%%%%% Version 0.70 10/16/2013 %%%%%%%%%
%%%%%%%%% Version 0.80 11/03/2013 %%%%%%%%%
%%%%%%%%% Version 0.90 11/03/2013 %%%%%%%%%
%%%%%%%%% Version 1.00 12/24/2014 %%%%%%%%%

%% Initiation
%
%tic

disp('===========================================')
disp('Initiation')


% Determine the estimated size of a fly
% flysize = settings_file{9};
% flysize = str2double(flysize(strfind(flysize, ',')+1:end));
flysize = settings_file.data(4);

% Determine the gamma for intensity thresholding
% gamma = settings_file{10};
% gamma = str2double(gamma(strfind(gamma, ',')+1:end));
gamma = settings_file.data(5); % 5 for lightpad, 2 for heatrig

% Determine the threshold of bw thresholding
% custom_bw_threshold_modifier = settings_file{13};
% custom_bw_threshold_modifier = str2double(custom_bw_threshold_modifier(strfind(custom_bw_threshold_modifier, ',')+1:end));
custom_bw_threshold_modifier = settings_file.data(8);

% Determine the area threshold for demooning
% demoon_cutoff = settings_file{14};
% demoon_cutoff = str2double(demoon_cutoff(strfind(demoon_cutoff, ',')+1:end));
demoon_cutoff = settings_file.data(9);

% Pixels per cm, from settings file
pixel_per_cm = settings_file.data(14); % 108 for lightpad, 96 for heatright


% Get the dimensions fo the arena
viddim = size(Arena);

% Get how many frames are in the arena
% COMMON ERROR: Video is too short. Stuck in try-catch to make it clear
try
    nframe = viddim(3);
catch err
    disp('ERROR: ONE OF THE VIDEO FILES IS TOO SHORT. Make sure the videos are all longer than 1 minute.')
end
% Get the x-y size of the arena
% arena_dim = viddim(1:2);

% 2 fly tracking
nfly = 2;

if arena_num == 1
    % Set up the flag matrix of what happens in each frame
    Flags = zeros( nframe, 1 ); 
    % 0-normal 1-reduction 2-watershed 3-anti-overwatershed 
    % 4-force(dot) 5-force(ext) 6-force(int) 7-creation
    % The tens digit refers to whether this frame is demooned
    % 1X - demooned, 0X - not demooned
    

end
%toc
%}

%% Color Adjustment and Background Calculation
%
%tic
disp('===========================================')
disp('Background Calculation')

% If first video, call flytrackbackground function to calculate the background
% If not first video, receives background from first video.

if backgroundInput == -1
    background = flytrackbackground( Arena, FPS, nframe, settings_file );
else
    background = backgroundInput;
end

%toc
%}

%% Background Correction and Tracking
%
%tic
disp('===========================================')
disp('Background Correction and Tracking');

% Prime the matrices of for frame processing. As of now, these matrices are
% not outputed
arena_rev_nbg_bw_erode = single(zeros(viddim)); % I am leaving the erode unchanged throughout the code
arena_rev_nbg_bw_erode_lb = zeros(viddim);

% Prime a vector to record how many flies were finally detected in each
% frame
nflydetected = zeros(nframe,1);

% Counters for processes
n_watershed = 0;
n_force_seg = 0;
n_reduce = 0;
n_created = 0;

clear props; % This step seems needed no matter what

% Prime the props structure to record the properties of flies
props(1:nfly,1:nframe) = struct('Centroid',zeros(1,2,'double'), 'Area', [], 'Eccentricity', []); %,'Area',[],'MajorAxisLength',[],'MinorAxisLength',[],'Eccentricity',[],'Orientation',[]);

% If quiet mode is off, let people know what is going on
if quietmode == 0
    dispbar = waitbar(0,['Tracking Video',num2str(vid_num),'- Arena',num2str(arena_num)]);
end

% Params
min_fly_size = 15; % 10 for ln138, 15 for test2
max_ecc = 0.99;
matingFly_minArea = 130; % 80 for ln138, 130 for test2
gamma = 2;
master_gamma = gamma;

% Store data
areasByFrame_cell = cell(1, nframe);
eccByFrame_cell = cell(1,nframe);
nFliesByFrame = zeros(1, nframe);
matingByFrame = zeros(1, nframe);

% debugging
singleRegion_gamma2_maxAreas = [];

for i=1:nframe
%     tic
    % Subtract the background and threshold the frame
    
    % ln138_test
    %{
    JP: in heatrig, sometimes edge of arena is fairly bright, and is
    actually brighter than the flies, causing you to lose a fly. This is
    usually solved by MATLAB's imbinarize, but that often works too well
    -- mating pairs then appear as one big clump, instead of two. That's
    maybe ok in another program, but flyknight expects each fly to show up
    separately (hence SZ's really stringent thresholding, so that even
    mating flies will be separated into different regions).
    
    Hmm, what if we actually changed that? What if we use imbinarize,
    demoon, and just count the number of clumps of an appropriate size?
    It's stupid simple but it could work...
    
    Ground truth: mating frame 14-112
    
    Case studies
    
    Frame 3: one fly is good. The other fly is too dark and shows up as a
    tiny dot. There is a large dot on the edge of the arena. So fly size
    sanity check won't catch that, and reduction will end up discarding the
    real fly. This is solved by imbinarize.
    -- Smaller of two flies here is 29, larger is 68.
    
    Frame 52: there is a one-pixel spot left over after erosion that is
    detected as a fly in line 164. Manually fixing and going to watershedding fixes it.
    Solution: instead of just checking nflies, do a sanity check on the
    size of the flies. If there are some really tiny spots, eliminate them?
    --with imbinarize, noise is all <10, mating pair is 99.
    
    Frame 45: one-pixel spot along with one small spot for the flies. Would
    end up taking previous frame. Sanity check on fly size would solve
    this.
    --Now with imbinarize, the noise is too large and would appear as a
    second fly (sz of 30) even though they're mating (pair has sz of 77).
    
    
    
    Frame 68: flies are too dark. Even a gamma of 2 loses them. Gamma of 1
    finds them. It detects some noise as three very tiny "flies" instead,
    then uses reduction to reduce to two. Again, sanity check on fly size
    would solve this up front. Basically check the size of the initially
    detected flies (in line 176), and see, oh, they're unrealistically
    small. We must have lost track of them. Increase gamma and try again.
    -- with imbinarize and gamma of 1, mating pair is 139, noise is 1 and
    4. Good!
    
    Frame 65: detects one big blob (mating pair) and some noise. Fly size
    limit would solve this.
    
    Frames 9: imposing eccentricity limit (no more than 0.98?) will solve
    this.
    
    Frame 10: one fly is detected with gamma of 2, but two flies are
    detected with gamma of 1. Using gamma of 1 the whole time solves.
    
    Frame 132: issue is that the fly is connected to the perimeter of the
    well. Intermediate gamma of 1.5 solves this.
    
    Frame 134: Just really dark. Gamma of 0.75 finds both flies. Gamma of 1
    finds the first fly, then the algorithm moves on.
    
    ***
    
    -- Try with gamma = 2. 
        -- If you find two regions of the right area and the
        right eccentricity, etc, it's two flies and you're done.
        -- If you find one region, either they're mating, or the other fly
        is too dark to see. So decrement gamma and see what happens.
    -- Try with gamma decreased.
        -- If you find two regions now, there are two flies.
        -- Otherwise, they're mating.
    
    --With this set up, a final area of 80 or larger seems to be a
    reliable indicator of mating.
    
    Frame 2: fly is removed as part of the edge. Institute a min mating
    size?
    Frame 13: fly is removed as part of the edge.
    Frame 15: mating pair is seen as two separate regions due to a
    not-quite-low-enough gamma. Why isn't erosion followed by dilation?
        -- Because then you have too much noise, it seems.
        -- Maybe try a conditional dilation or something but it gets messy.
    
    
    Frame 6: too many "flies". Could be solved by taking two largest, which
    are under 80 at a gamma of 1. Or just check if any is large enough to
    be a mating pair.
    
    Frame 20: too many "flies." The mating pair isn't large enough to catch
    that way. The noise is too prominent to fully remove, so you end up
    with three "flies" when there's really just one mating pair.
        -- Increasing gamma solves this, and makes the mating pair large
        enough to be noticed as such.
    
    Frame 32: too many "flies". Mating pair is large enough with a gamma of
    2 that a size catch would catch this.
    

    ***
    Frame 141: classic issue. With gamma = 2, one fly is lost, and it sees
    one fly that isn't big enough to be a mating pair. With gamma = 1.5, it
    sees both flies, but now one is big enough to be a mating pair even
    though it's only one fly (bc gamma decr). So maybe need to have a
    moving threshold for mating pair size depending on gamma? Doesn't feel
    quite right though...
    
    %}
    
    % test2
    %{
    Ok, we definitely overfit to the last video's data lol.
    
    Ground truth: 16-81.
    
    -- Simply increasing the size of the mating fly min area helps a lot. But
    there are a good number of false positives.
    -- These are improved drastically by removing the program's ability to
    say that if there are 2+ flies, it might really be noise + mating.
        -- Ok, so I think this feature ^ was just a weird necessity due to
        weird lighting conditions of the first video. Hopefully if we
        create uniform lighting conditions, we won't need that catch.
    
    %}
    regionCriteriaFlag = 0;
    tries = 0;
    
    while ~regionCriteriaFlag && tries < 3
        arena_rev_nbg_bw = flytrackbw( Arena, i, background, gamma, custom_bw_threshold_modifier);

        % Remove the moon-shaped ring before erosion
        % JP notes: this sometimes creates an issue when fly is touching the
        % edge of the arena, so one or both flies are removed along with the
        % "moon" (the edge of the arena).
        [ arena_rev_nbg_bw, Flags(i) ] = flytrackdemoon( arena_rev_nbg_bw, demoon_cutoff);

        % Erode the images (get rid of small shades) and label them
        arena_rev_nbg_bw_erode(:,:,i) = imerode(arena_rev_nbg_bw,strel('disk', flysize));
%         arena_rev_nbg_bw_erode(:,:,i) = imopen(arena_rev_nbg_bw, strel('disk', flysize));
        [ arena_rev_nbg_bw_erode_lb(:,:,i) , nflydetected(i) ] = bwlabel( arena_rev_nbg_bw_erode(: , : , i ));
        
        thisFrameProps = regionprops(arena_rev_nbg_bw_erode_lb(:,:,i),'Area', 'Eccentricity');
        
        flySize_bool = [thisFrameProps.Area] > min_fly_size;
        flyEcc_bool = [thisFrameProps.Eccentricity] < max_ecc;
        
        nfly_JP = sum(flySize_bool & flyEcc_bool);
        if  nfly_JP == 0 
            % no flies detected
            gamma = gamma - 0.5;
            tries = tries + 1;
        elseif nfly_JP == 1
            % one fly detected; either mating or other is too dark.
            
            % debugging:
            singleRegion_gamma2_maxAreas = [singleRegion_gamma2_maxAreas thisFrameProps(flySize_bool & flyEcc_bool).Area];
            
            % implement choice based on the region size: mating pairs are
            % large.
            if thisFrameProps(flySize_bool & flyEcc_bool).Area > matingFly_minArea
                % mating pair
                regionCriteriaFlag = 1;
                matingByFrame(i) = 1;
            else
                % one fly too dark
                gamma = gamma - 0.5;
                tries = tries + 1;
            end
            
        elseif nfly_JP == 2
            
%             % Check if one of them is large enough to be a mating pair
%             if max([thisFrameProps(flySize_bool & flyEcc_bool).Area]) > matingFly_minArea
%                 % mating pair
%                 nfly_JP = 1;
%                 matingByFrame(i) = 1;
%             end
            
            regionCriteriaFlag = 1;
        else
            % oops, too many flies!
            
%             % Check if one of them is large enough to be a mating pair
%             if max([thisFrameProps(flySize_bool & flyEcc_bool).Area]) > matingFly_minArea
%                 % mating pair
%                 nfly_JP = 1;
%                 matingByFrame(i) = 1;
%                 regionCriteriaFlag = 1;
%             else
%                 % Sometimes you get mating pairs that are split because
%                 % it's too dark. 
%                 gamma = gamma - 0.5;
%                 tries = tries + 1;
%             end
            
            gamma = gamma - 0.5;
            tries = tries + 1;
        end
    end
    
    
    % After this progression, if still only one "fly", it's a mating pair
    nFliesByFrame(i) = nfly_JP;
    if nfly_JP == 0
        fprintf('Frame %d, no flies found, gamma %d \n', i, gamma)
        areasByFrame_cell{i} = NaN;
        eccByFrame_cell{i} = NaN;
    elseif nfly_JP == 1 && matingByFrame(i) == 0
        fprintf('Frame %d, one non-mating fly found, gamma %d \n', i, gamma)
        areasByFrame_cell{i} = thisFrameProps(flySize_bool & flyEcc_bool).Area;
        eccByFrame_cell{i} = thisFrameProps(flySize_bool & flyEcc_bool).Eccentricity;
    elseif nfly_JP == 1 && matingByFrame(i) == 1
        fprintf('Frame %d, one mating pair found, gamma %d \n', i, gamma)
        areasByFrame_cell{i} = [thisFrameProps(flySize_bool & flyEcc_bool).Area];
        eccByFrame_cell{i} = [thisFrameProps(flySize_bool & flyEcc_bool).Eccentricity];
    elseif nfly_JP == 2
        fprintf('Frame %d, two flies found, gamma %d \n', i, gamma)
        areasByFrame_cell{i} = [thisFrameProps(flySize_bool & flyEcc_bool).Area];
        eccByFrame_cell{i} = [thisFrameProps(flySize_bool & flyEcc_bool).Eccentricity];
    else
        warning('More than two flies detected for frame %d', i)
    end
    
    % Reset gamma
    gamma = master_gamma;
    
    
    % If num of flies detected is too low, it's going to be because a)
    % nothing is there (in which case take previous frame); or b) because only
    % one spot is there after image processing. If it's a big spot, we can
    % use some tricks to separate it into two flies.
    if nflydetected(i) < nfly % Need watershed
        %disp(['Frame ' , num2str(i) , ' Watershedding'])
        n_watershed = n_watershed + 1;
        [ arena_rev_nbg_bw_erode_lb(:,:,i), nflydetected(i), Flags(i) ] = flytrackwatershed( arena_rev_nbg_bw_erode(:,:,i), nfly, Flags(i) );
        
        if nflydetected(i) < nfly % Need force segmentation (dot removal)
            %disp('Watershedding Unsuccessful')
            n_force_seg = n_force_seg + 1;
            [ arena_rev_nbg_bw_erode_lb(:,:,i), nflydetected(i), Flags(i) ] = flytrackdotremoval( arena_rev_nbg_bw_erode(:,:,i), nfly, Flags(i) );
            
            if nflydetected(i) < nfly % Need force segmentation (external ring removal)
                %disp('Dot removal Unsuccessful')
                [ arena_rev_nbg_bw_erode_lb(:,:,i), nflydetected(i), Flags(i) ] = flytrackexring( arena_rev_nbg_bw_erode(:,:,i), nfly, Flags(i) );
                
                if nflydetected(i) < nfly % Need force segmentation (internal ring removal)
                    %disp('External Ring Removal Unsuccessful') % Initiate internal ring removal
                    [ arena_rev_nbg_bw_erode_lb(:,:,i), nflydetected(i), Flags(i) ] = flytrackinring( arena_rev_nbg_bw_erode(:,:,i), nfly, Flags(i) );
                    
                    if nflydetected(i) < nfly % Need to create a fly
                        % Flag creation
                        Flags(i) = Flags(i) + 7;
                        
                        if i == 1
                            % If this is the first frame, start creating
                            arena_rev_nbg_bw_erode_lb(:,:,i) = flytrackcreation( arena_rev_nbg_bw_erode(:,:,i),2);
                            nflydetected(i) = nfly;
                        else
                            % If this is not the first frame, use
                            % everything from the last frame (temporary solution)
                            arena_rev_nbg_bw_erode_lb(:,:,i) = arena_rev_nbg_bw_erode_lb(:,:,i-1);
                            nflydetected(i) = nflydetected(i-1);
                        end
                    end
                end
            end
        end
                       
    elseif nflydetected(i) > nfly % Reduce arena if too many flies
        n_reduce = n_reduce + 1;
        % The flag and nflydetected here are predictable since the function
        % never fails
        Flags(i) =Flags(i) + 1;
        nflydetected(i) = nfly;
        arena_rev_nbg_bw_erode_lb(:,:,i) = flytrackreduction(arena_rev_nbg_bw_erode_lb(:,:,i) , nfly );
    end
    
    props(:,i) = regionprops(arena_rev_nbg_bw_erode_lb(:,:,i),'Centroid', 'Area', 'Eccentricity'); %,'Orientation','Area','Eccentricity','MajorAxisLength','MinorAxisLength');
    
    
    if quietmode==0
        waitbar(i/nframe,dispbar)
    end
    
%     toc
end
% arena_rev_nbg_bw_erode_lb=uint8(arena_rev_nbg_bw_erode_lb); % If this
% matrix is outputed, then uint8 is suggested to reduce memory usage
% arena_rev_nbg_bw_erode=uint8(arena_rev_nbg_bw_erode); % If this matrix is
% outputed, then uint8 is suggested to reduce memory usage
if quietmode==0
    close(dispbar)
end
disp(['Video',num2str(vid_num),'- Arena',num2str(arena_num)])
disp(['Watershedding done: ' , num2str(n_watershed)])
disp(['Forced Segmentation done: ' , num2str(n_force_seg)])
disp(['Reduction done: ' , num2str(n_reduce)])
disp(['Creation done: ' , num2str(n_created)])
%toc
%}

%% 1st Order Data
%
%tic
disp('===========================================')
disp('1st Order Data')
Centroids=ones(nframe,2,nfly).*NaN; 
% Area=ones(nframe,nfly).*NaN;
% MajorAxisLength=ones(nframe,nfly).*NaN;
% MinorAxisLength=ones(nframe,nfly).*NaN;
% Eccentricity=ones(nframe,nfly).*NaN;
% Orientation=ones(nframe,nfly).*NaN;

for i=1:nfly
    Centroids(:,:,i) = round( reshape( [ props(i,:).Centroid ]' , [ 2 , nframe ] )' );
%     Area(:,i)=reshape([props(i,:).Area]',[1,nframe])';
%     MajorAxisLength(:,i)=reshape([props(i,:).MajorAxisLength]',[1,nframe])';
%     MinorAxisLength(:,i)=reshape([props(i,:).MinorAxisLength]',[1,nframe])';
%     Eccentricity(:,i)=reshape([props(i,:).Eccentricity]',[1,nframe])';
%     Orientation(:,i)=reshape([props(i,:).Orientation]',[1,nframe])';
end

% Add a designation step here

%toc

%}

%% Designation
%
disp('===========================================')
disp('Designation')

%tic
[ CentroidsA, CentroidsB, ~, ~ ] = flytrackdesignation( Centroids, nframe );
% AreaA=sum(Area.*FlyA,2);
% AreaB=sum(Area.*FlyB,2);
% MajorAxisLengthA=sum(MajorAxisLength.*FlyA,2);
% MajorAxisLengthB=sum(MajorAxisLength.*FlyB,2);
% MinorAxisLengthA=sum(MinorAxisLength.*FlyA,2);
% MinorAxisLengthB=sum(MinorAxisLength.*FlyB,2);
% EccentricityA=sum(Eccentricity.*FlyA,2);
% EccentricityB=sum(Eccentricity.*FlyB,2);
% OrientationA=sum(Orientation.*FlyA,2);
% OrientationB=sum(Orientation.*FlyB,2);

%toc
%}

%% Visualization
% The positions have not been re mapped after designation.

%tic
disp('===========================================')
disp('Visualization')

% 
marker_layer=zeros(viddim);
for i=1:nfly
    for j=1:nframe
        marker_layer(Centroids(j,2,i),Centroids(j,1,i),j)=1; % (y,x) because on a image, down means y increases (counterintuitive from matrix)
    end
end

combined_layer=mat2gray(Arena)+marker_layer;
implay(combined_layer,FPS*50)
%toc


%% 2nd Order Data
%
%tic
disp('===========================================')
disp('2nd Order Data')
% Unit Conversion
%{
figure(99)
imshow(Arena(:,:,1))
h = imline;
position = wait(h);
delta_position=diff(position);
calibration_pixels=sqrt(delta_position(1).^2+delta_position(2).^2);
pixel_per_cm=calibration_pixels/calibration_line_length;
close 99
%}


%cm_per_pixel= ; % Direct Input is fine too

% Calculate Distances
%speedcap=80;
centroid_delta_spatial = CentroidsA - CentroidsB;

% Calculate the final distance to output
inter_fly_dist = sqrt( centroid_delta_spatial( : , 1 ).^2 +...
    centroid_delta_spatial( : , 2 ) .^ 2 ) ./ pixel_per_cm;
%outlierindex=find(abs(diff(inter_fly_dist))>0.3);
%duplicated_outlier=find(diff(outlierindex)==1);
%outlierindex(duplicated_outlier)=[];
%inter_fly_dist_filtered=[(1:nframe)'/FPS,inter_fly_dist];
%inter_fly_dist_filtered(outlierindex,:)=[];

% Plot Distances

%
%     figure(arena_num+80)
%     plot((1:nframe)/FPS/60,inter_fly_dist,'-');
%     find(Flags==1)/FPS/60,0.7,'r.',...
%     find(Flags==2)/FPS/60,0.71,'r.')
%     find(Flags==3)/FPS/60,0.72,'r.',...
%     find(Flags==4)/FPS/60,0.73,'r.',...
%     find(Flags==5)/FPS/60,0.74,'r.',...
%     find(Flags==6)/FPS/60,0.75,'r.',...
%     find(Flags==7)/FPS/60,0.76,'r.')

% xlabel('Time/min')
% ylabel('Inter Fly Distances/cm')
% title('Distance')
%}

%{
figure
plot(inter_fly_dist_filtered(:,1),inter_fly_dist_filtered(:,2))
xlabel('Time/sec')
ylabel('Inter Fly Distances/cm')
title('Filtered distance')
%}



% Calculate Speeds (need fly designation)
%{
centroid_delta_temporal_A=diff(CentroidsA);
centroid_delta_temporal_B=diff(CentroidsB);
speeds=ones(nframe-1,nfly).*NaN;
speeds(:,1)=sqrt(centroid_delta_temporal_A(:,1).^2+centroid_delta_temporal_B(:,1).^2)/pixel_per_cm*FPS;
speeds(:,2)=sqrt(centroid_delta_temporal_B(:,1).^2+centroid_delta_temporal_B(:,2).^2)/pixel_per_cm*FPS;
%

% Plot Speeds
%
figure
plot((1:nframe-1)/FPS/60,speeds(:,1),(1:nframe-1)/FPS/60,speeds(:,2))
xlabel('Time/min')
ylabel('speeds/cm*s^-^1')
title('speed')
legend('FlyA','FlyB')

%}

%toc
%}



% keep Arena CentroidsA CentroidsB EccentricityA EccentricityB FPS MajorAxisLengthA MajorAxisLengthB MinorAxisLengthA MinorAxisLengthB...
%     OrientationA OrientationB arena_rev_nbg_bw_erode arena_rev_nbg_bw_erode_lb backcalcskip_endframe background background_calc_end_time...
%     backgroundcalcstack flysize gamma inter_fly_dist inter_fly_dist_filtered n_anti_overshed n_created n_force_seg n_reduce n_watershed nfly...
%     nflydetected nframe pixel_per_cm arena_dim fwatershed fforce_seg fanti_overshed freduce fcreate FlyA FlyB AreaA AreaB Flags filename arena_num

%% 2nd Order Data
%{
%tic
disp('===========================================')
disp('2nd Order Data')
%toc
%}

%% 2nd Order Data
%{
%tic
disp('===========================================')
disp('2nd Order Data')
%toc
%}

%% 2nd Order Data
%{
%tic
disp('===========================================')
disp('2nd Order Data')
%toc
%}
end


