
%% Pseudo code

% Connect MATLAB to the raspi. Burn-in for camera settings.
% (Test: load in segmented videos for background, single fly, mating)


% Prompt user to begin.

% *** PRE TEST STUFF ***
% Prompt user for manual crop of the wells.
% Get arenas (fly universe). Show user outlines of detected arenas.
% Acquire images for background. Probably 50 is enough?
% Calculate background and store.

% *** BEGIN FEMALE LOADING ***
% Prompt user to start loading flies
% User says when done loading females

% Each second, acquire a snapshot. Program should detect one fly in each well. 
% (Test: have a try statement. If no raspi, look for a path to a test
% video.

% *** BEGIN MALE LOADING ***
% Prompt user to begin loading males
% User says when done loading males

% *** BEGIN EXPERIMENT ***
% Each second, acquire a snapshot.
% (Test: have a try statement. If no raspi, look for a path to a test
% video.)
% Crop into arenas, run blob counter on each arena.
% Put certain-colored border around each arena and display to user to show
% if pair is mating or not.
% (Test: print out times to prove it really works!)

%% To Do

% add camera settings to settings file

%% Master Initiation

disp('==================================')
disp('Initiation')
disp('==================================')

% Load in settings as a struct
Settings = table2struct(readtable('fkbc_settings.xlsx'));

% Define Raspi IP addresses
disp('Current heatrig IP addresses:')
ATTA = '10.32.64.135';
FLICK = '10.32.64.168';
DOT = '10.32.64.69';
HEIMLICH = '10.32.64.44';
IPs = {ATTA, FLICK, DOT, HEIMLICH};
rigNames = {'Atta', 'Flick', 'Dot', 'Heimlich'};

% Define Raspi UN and PW
rpiUN = 'pi';
rpiPW = 'raspberry';

%% Get user input for start up

disp('==================================')
disp('User menus')
disp('==================================')

% Ask user what raspi to use
for iRig = 1:length(rigNames)
    fprintf('%s: %s \n', rigNames{iRig}, IPs{iRig})
end

goodRig = 0;
while ~goodRig
    rig = input('\n Connect to which Raspi? Eg: Atta. Or enter TEST for test mode \n', 's');
    try
        if ismember(rig, rigNames) || strcmp(rig, 'TEST')
            goodRig = 1;
        end
    catch
        disp('Please enter one of the rig names')
    end
end
    
%% Connect to Raspberry Pi and camera

% Connect to desired Raspi, or load test video
if strcmp(rig, 'TEST')
    % load various videos for testing
else
    try
        rpi = raspi(rig);
    catch
        error('Could not connec to raspi')
    end
    camera = cameraboard(rpi, 'Resolution', '1980x1080');
    % set settings
    lastImage = warmupcamera(camera, numWarmUps);
end



%% Manual Cropping Measurement
%
%tic


% Load the video object
VidObj = VideoReader(filename);

% Load the first frame
Mov=read(VidObj,firstframe2load);


if Knightmode==0
    % Show what's going on
    disp('==================================')
    disp('Manual Cropping Measurement')
    
    % Manual cropping
    [ cropindex1_manual, cropindex2_manual, cropindex3_manual, cropindex4_manual ]...
    = flyunivmanual( Mov, channel2choose );
end


%toc
%}

%% Auto Cropping Measurement
%
%tic
disp('==================================')
disp('Auto Cropping Measurement')

[flyuniverse, flyuniverse_props, n_arenas] = autoflyuniv(Mov,...
    cropindex1_manual:cropindex2_manual,cropindex3_manual:cropindex4_manual,...
    channel2choose, 0.5, 10); % Change the 0.7 to other values of threshold; 
% 0.5 for some f-ed up videos

%toc
%}

%% Autocropping and Processing all Videos
%
disp('==================================')
disp('Autocropping and Processing')
%tic

% Set the margin of each arena
arena_margin=0;

% Prime a ranking vector for the arenas
arena_rank = zeros( size( flyuniverse ) );

% Prime a cell recording the inter-fly distances of all arenas in all
% videos
inter_fly_dist_allvid_cell = cell( str2double( num_vids{ 1 } ) , 1 );

% Prime a cell of flags recording what happened to each frame of analysis
Flags_allvid_cell = { str2double( num_vids{ 1 } ) , 1 };

% Prime a cell to record the frame numbers
nframe_allvid_cell={ str2double( num_vids{ 1 } ) };

% Pre allocate first vid backgrounds
firstVid_backgrounds = cell(1, n_arenas);
    
% For each video
for vid_num = 1 : str2double( num_vids{ 1 } )
    % For non-first videos, determine their names and load the videos
    
    % Load the video if it's not the first
    if vid_num > 1
        % Determine the name
%         filename = [ filename( 1 : end - 5 ) , num2str( vid_num ) , filename( end - 3 : end )];
        filename = [ filename( 1 : end - 5 ) , num2str( vid_num ) , filename( end - 3 : end )];

        % Read the video
        VidObj = VideoReader(filename); %#ok<TNMLP>
    end

    % Get all video properties
    nVidFrame = VidObj.NumberOfFrames;
    vidHeight = VidObj.Height;
    vidWidth = VidObj.Width;
    vidfps = VidObj.FrameRate;
    vidDuration = VidObj.Duration;

    % Figure out how many frames to skip in each iteration
    frames2skip = round(vidfps/targetfps);

    % Get the frames to load
    nframe_flyload = length(firstframe2load : frames2skip : nVidFrame);
    
    % Prime the interfly distance and flag matrices
    inter_fly_dist = zeros( nframe_flyload , n_arenas );
    Flags = zeros( nframe_flyload , n_arenas );    

    % === Begin differences between speed_types speedy and RAM ===
    
    % If speedy mode, load entire video.
    % FullMov is nrow x ncol x num frames.
    if strcmp(speed_type, 'speedy')
        [FullMov, FPS] = flyloadspeedyvid(VidObj, channel2choose,...
            nframe_flyload, firstframe2load, frames2skip, nVidFrame, vidDuration);
    end
    
    % Start processing each individual arena
    for arena_num = 1 : n_arenas
        % For each arena, figure out how to crop it out of the fly universe
        cropindex1 = max( ceil( min( ...
            flyuniverse_props( arena_num ).Extrema(: , 1)) - arena_margin) , 1);
        cropindex2 = max( floor( max( ...
            flyuniverse_props( arena_num ).Extrema(: , 1)) + arena_margin) , 1);
        cropindex3 = max( ceil( min( ...
            flyuniverse_props( arena_num ).Extrema(: , 2)) - arena_margin) , 1);
        cropindex4 = max( floor( max( ...
            flyuniverse_props( arena_num ).Extrema(: , 2)) + arena_margin) , 1);

        % If RAM saver mode, use fly load to load the frames into RAM
        if strcmp(speed_type, 'RAM')
            [Arena, FPS] = ...
            flyload(VidObj, channel2choose,...
            nframe_flyload, firstframe2load, frames2skip, nVidFrame, vidDuration,...
            quietmode,cropindex1, cropindex2, cropindex3, cropindex4, cropindex1_manual, cropindex3_manual);
        
        % If speedy mode, the entire video is already loaded and inverted in the
        % variable FullMov. Just need to crop each frame.
        elseif strcmp(speed_type, 'speedy')
            
            % Determine the arena height and width
            arena_height = cropindex4 - cropindex3;
            arena_width = cropindex2 - cropindex1;
            
            % Pre-allocate Arena matrix
            Arena = uint8(zeros(arena_height, arena_width, nframe_flyload));
            
            % Crop each frame
            for iFrame = 1:size(FullMov, 3)    
                Arena(:,:,iFrame) = ...
                    FullMov(cropindex3 + cropindex1_manual : cropindex4 + cropindex1_manual - 1 ,...
                    cropindex1 + cropindex3_manual : cropindex2 + cropindex3_manual - 1,...
                    iFrame);
            end
        end

        % === End of differences between speed_types speedy and RAM ===
        
        
        % Use flytrack to process the loaded file.
        % On first vid, get background.
        % On subsequent vids, take background from first vid.
        if vid_num == 1
            [inter_fly_dist( : , arena_num), Flags( : , arena_num), background] = flytrack(Arena, FPS, vid_num, arena_num, settings_file, quietmode, -1);
        else
            [inter_fly_dist( : , arena_num), Flags( : , arena_num), background] = flytrack(Arena, FPS, vid_num, arena_num, settings_file, quietmode, firstVid_backgrounds{arena_num});
        end
        
        
        if vid_num ==1
            arena_rank( cropindex3 : cropindex4 , cropindex1 : cropindex2 ) = arena_num; % Construct the arena_rank matrix only in the first video
            firstVid_backgrounds{arena_num} = background; % store for use on subsequent videos
        end

    end
    
    % Put the outputs of each video in cell
    inter_fly_dist_allvid_cell{ vid_num } = inter_fly_dist;
    Flags_allvid_cell{ vid_num } = Flags;
    nframe_allvid_cell{ vid_num } = nframe_flyload;
end
%toc

%% Combining and Rearranging Data
disp('==================================')
disp('Combining and Rearranging Data')
%tic

% Calculate the cumulative number of frames
nframe_allvid = cumsum( cell2mat( nframe_allvid_cell ) );

% Prime a matrix to store the video distance info of all videos
inter_fly_dist_allvid = zeros( nframe_allvid( end ) , n_arenas );
Flags_allvid = zeros( nframe_allvid( end ) , n_arenas );

for vid_num = 1 : str2double( num_vids{ 1 } )
    % For the first video the index is calculated differently from the rest
    if vid_num == 1
        % Load the first video's data into the total data
        inter_fly_dist_allvid( 1 : nframe_allvid( vid_num ), : ) = inter_fly_dist_allvid_cell{vid_num};
        Flags_allvid( 1 : nframe_allvid( vid_num ), : ) = Flags_allvid_cell{ vid_num };
    else
        % Load the subsequent video's data into the total data
        inter_fly_dist_allvid( nframe_allvid( vid_num - 1 ) + 1 : nframe_allvid( vid_num ), : ) = inter_fly_dist_allvid_cell{ vid_num };
        Flags_allvid( nframe_allvid( vid_num - 1 ) + 1 : nframe_allvid( vid_num ), : ) = Flags_allvid_cell{ vid_num };
    end
end

% Rank the arenas
ranking2 = flyarenarank( arena_rank, n_arenas );

% Apply the ranking
inter_fly_dist_allvid_sorted=inter_fly_dist_allvid( : , ranking2 );
Flags_allvid_sorted=Flags_allvid( : , ranking2 );

%trace_data_mat_sorted=zeros(size(trace_data_mat));
% for i=2:2:size(trace_data_mat,2)
%     trace_data_mat_sorted(:,i-1:i)=trace_data_mat(:,ranking2(i/2)*2-1:ranking2(i/2)*2);
% end
% for i=1:n_arenas
%     saveas(i+80,['E:\Dropbox\Crickmore_research\Tracking_Data\',filename(1:end-4),'-',num2str(ranking2(i)),'.png'])
% end

%csvwrite(['E:\Dropbox\Crickmore_research\Tracking_Data\',filename(1:end-4),'.csv'],[(1:nframe)'/FPS/60,trace_data_mat_sorted]);
%toc
%}

%% Calculating Copulation Duration
disp('==================================')
disp('Calculating Copulation Duration')
%tic

chains = flymatingchain( inter_fly_dist_allvid_sorted, n_arenas, FPS, settings_file );

%toc

toc
%% Plotting and Saving Data

%tic
% Print figure
flyprint( inter_fly_dist_allvid_sorted, chains, nframe_allvid(end), num_vids, n_arenas, FPS, nframe_allvid_cell, printresult, filename, export_path, settings_file, PC_or_not)

% Save workspace
clear VidObj
save( fullfile( export_path, [ filename( 1 : end - 6 ) , '.mat' ] ) )
%toc

%% Fancy Flags and Saving Data
%{
disp('==================================')
disp('Fancy Flags and Saving Data')
%tic

Flags_c=zeros([size(Flags_allvid_sorted),3]);
Flags_r=zeros(size(Flags_allvid_sorted));
Flags_g=zeros(size(Flags_allvid_sorted));
Flags_b=zeros(size(Flags_allvid_sorted));

Flags_r(Flags_allvid_sorted==7)=1;
Flags_r(Flags_allvid_sorted==6)=1;
Flags_g(Flags_allvid_sorted==6)=1;
Flags_g(Flags_allvid_sorted==4)=1;
Flags_g(Flags_allvid_sorted==3)=1;
Flags_b(Flags_allvid_sorted==3)=2;
Flags_b(Flags_allvid_sorted==1)=1;

Flags_c(:,:,1)=Flags_r;
Flags_c(:,:,2)=Flags_g;
Flags_c(:,:,3)=Flags_b;

imtool(Flags_c)
imtool(Flags_demooned_allvid_sorted)
%toc


toc
%}
