%% Master Initiation
%
tic
%tic
disp('==================================')
disp('Initiation')

% Choose whether to favor speed or RAM.
% Speedy: loads entire video (with many frames skipped) in flymaster. 
%   Then for each arena, for each frame, pass to a cropping function.
% RAM: does not ever load entire video. For each arena, for each frame,
%   load the frame, crop it, store the image.
speed_type = 'speedy'; % speedy or RAM
video_type = 'heatrig'; % lightpad or heatrig

% Label batch processing and read the batch processing parameter file 
if strcmp(video_type, 'lightpad')
    settings_file = importdata('flytrack_settings.xlsx');
elseif strcmp(video_type, 'heatrig')
    settings_file = importdata('flytrack_settings_HEATRIG.xlsx');
end

% General path of videos
% genvidpath = settings_file.textdata{1};
% genvidpath = genvidpath(strfind(genvidpath, ',')+1:end);
genvidpath = settings_file.textdata{1,2};

% Export path of analysis
% export_path = settings_file.textdata{2};
% export_path = export_path(strfind(export_path, ',')+1:end);
export_path = settings_file.textdata{2,2};

% Determine whether a computer is a PC or not
% PC_or_not = settings_file.textdata{3};
% PC_or_not = PC_or_not(strfind(PC_or_not, ',')+1:end)=='Y';
PC_or_not = settings_file.textdata{3,2} == 'Y';

% Determine whether the analysis will be run in quiet mode or not
% quietmode = settings_file.textdata{4};
% quietmode = quietmode(strfind(quietmode, ',')+1:end)=='Y';
quietmode = settings_file.textdata{4,2} == 'Y';

% Determine whether the results will be printed or not
% printresult = settings_file.textdata{5};
% printresult = printresult(strfind(printresult, ',')+1:end)=='Y';
printresult = settings_file.textdata{5,2} == 'Y';

% Determine the target FPS
targetfps = settings_file.data(1);
% targetfps = str2double(targetfps(strfind(targetfps, ',')+1:end));

% Determine which RGB channel to choose when tracking the videos
channel2choose = settings_file.data(2);
% channel2choose = str2double(channel2choose(strfind(channel2choose, ',')+1:end));

% Determine which frame in each video (in the video's fps to load first)
firstframe2load = settings_file.data(3);
% firstframe2load = str2double(firstframe2load(strfind(firstframe2load, ',')+1:end));


% Determine whether knight mode is on
if exist('Knightmode','var')==0
    Knightmode=0;
    
    % Manually open a file
    [filename,vidpath] = uigetfile(genvidpath,'Select the video file');
    
    % Temporarily add path
    addpath(fullfile(vidpath,filename));
    
    % Ask the number of videos to load
    num_vids=inputdlg('Enter the number of videos','Number of Videos');   
end


%}

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
