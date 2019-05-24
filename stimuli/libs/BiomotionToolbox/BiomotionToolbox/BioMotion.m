classdef BioMotion < handle
    % BioMotion
    %
    % GENERAL INFORMATION
    % The BioMotion class allows you to read, manipulate and display motion
    % capture data from different motion-capture databases. Currently
    % supported databases are:
    % - Pollick lab Body Movement Library (BML)
    % (http://paco.psy.gla.ac.uk/index.php?option=com_jdownloads&Itemid=62&view=viewcategory&catid=10)
    % - Leuven Action Database (LAD)
    % (http://ppw.kuleuven.be/english/lep/resources/action)
    % - By using the BioMotionToolbox's capacity to convert c3d and bvh files
    %   several other databases become available, such as:
    % 	- Carnegie Mellon Mocap database (CMM; http://mocap.cs.cmu.edu/)
    % 	- Human Motion Database (HMD; http://smile.uta.edu/hmd/hmd.htm)
    %
    % A more extensive list can be found on: http://www.jeroenvanboxtel.com/MocapDatabases.html
    %
    %
    % An explanation on how to use the BioMotionToolbox is provided in:
    %
    % "A Biological Motion Toolbox for Reading, Displaying and Manipulating
    % Motion Capture Data in Research Settings"
    % Jeroen J.A. van Boxtel & Hongjing Lu
    % Journal of Vision xx(xx):xxx (2013)
    %
    % Example codes are provided in ./BioMotionToolboxDemos/
    % namely:   BMT_demo_1_Basic.m
    %           BMT_demo_2_Scramble.m
    %           BMT_demo_3_Limitedlifetime.m
    %           BMT_demo_BigTest.m
    %
    %
    % Initial coding by:
    % Jeroen J.A. van Boxtel
    % JvB, July/Aug/Sept 2011
    % JvB, Jan-Mar 2013, Updated and restructured class (e.g. get and set
    %   access, some performance increases implemented, renaming of
    %   variables). Added option to contruct a Biomotion object from an
    %   array.
    % JvB May-June, Added limited lifetime option
    %
    
    % The following properties can be set and read only by class methods
    properties (SetAccess = 'private', GetAccess = 'private')
        ScrambleOLD         = 0;
        meanstartpos        = [0 0 0];
        firstframe
        lastshown
        %rotatereference
        sumphaseoffsets     = [];
        importjoints
        importframes
        invertarray
    end
    
    % The following properties can be set only by class methods, but can be
    % read by the user
    properties (SetAccess = 'private', GetAccess = 'public')
        nPointLights                % Number of markers (i.e. Pointlights) defined
        nFrames                     % Number of frames in the object
        Filename            = [];   % Name of the file from which the Biomotion object was loaded
        Filetype                    % The type of the file (bvh, txt, etc)
        JointsInfo                  % 'Raw' information on the position of the joints
        NormJointsInfo              % Processed information on the position of the joints
        AnchorJoints                % States the joints that are used to anchor the action to the center of the screen
        % Information about the variables concerning limited lifetime stimuli.
        % InfoLimitedLife is an object of the limitedlifetime class.
        % See also: LimitedLife, limitedlifetime
        InfoLimitedLife
    end
    
    % The following properties can be set and read by the user
    properties(GetAccess = 'public', SetAccess = 'public')
        Invert              = 0;    % Show the action upright (=0, default), or inverted (=1)
        % Show the action spatially scrambled (=1), or not  (=0, default)
        % The amount of scrambling is determined by ScrambleWidth,
        % ScrambleHeight, ScrambleDepth. The final offsets are saved in
        % ScrambleOffsets. The dimensions which need to be scrambled are
        % set with ScrambleDim.
        % See also: ScrambleWidth, ScrambleHeight, ScrambleDepth,
        % ScrambleOffsets, ScrambleDim
        Scramble            = 0;
        Rotation            = 0;    % Rotation angle of the action
        % Rotation axis. Used by Rotation and RotatePath
        % See Also: Rotation, RotatePath
        RotationAxis        = [0 1 0];
        ScrambleDim         = 'xyz';%Determines which axes are going to be scrambled.
        %Determines the amount of scrambling along the y axis.
        % See also: ScrambleHeight, ScrambleDepth
        ScrambleWidth
        %Determines the amount of scrambling along the y axis.
        % See also: ScrambleWidth, ScrambleDepth
        ScrambleHeight
        %Determines the amount of scrambling along the y axis.
        % See also: ScrambleWidth, ScrambleHeight
        ScrambleDepth
        ScrambleOffsets     = [];   %Offsets (in pix) of each dot relative to the center of the object
        Position3D          = [0 0 0]; %Three-dimensional offset added to the object
        Scale               = 5;    %Change the scaling of the object
        Loop                = 0;    %Determines whether the movie will be looped or not
        LimitedLife         = 0;    % Display the stimulus with limited lifetime markers (1) or not (0)
        %PhaseOffsets - in case of phase scrambling. Contains the offset in number of frames.
        PhaseOffsets        = [];
        % Defines skeleton along which the joint are drawn when LimitedLife is 1.
        % Define each limbsegment of the skeleton as a pair of markers on a
        % row. Different limbsegments are defined on different rows.
        % Defining an e.g. an arm that goes from marker 2 to 3 and then to
        % 4, you will define the skeleton as [2 3; 3 4; ...]. The elipses
        % (...) is where the other limbsegments will be defined.
        %
        % The drawing location of the sample can be restricted to the joint
        % itself (and not a limbsegment between two joints). In this case
        % the one asks for a limbsegment like this [1 1; ...]. In this case
        % the first marker is a 'limbsegment' by itself. When one wants to
        % draw the limited lifetime samples only from the joint locations,
        % the skeleton can be define as: [1 1; 2 2; 3 3; ...].
        Skeleton            = [];
    end
    
    properties(GetAccess = 'public', SetAccess = 'public', SetObservable = true)
        % Show the action phase-scrambled (=1), or not  (=0, default)
        % The amount of scrambling is saved in PhaseOffsets, in number of
        % frames.
        % See also: PhaseOffsets
        PhaseScramble       = 0;
    end
    
    methods
        
        function BM = BioMotion(filename,varargin)
            switch nargin
                case 0
                    % empty
                otherwise
                    if isempty(filename)
                        error('BioMotion:constructor', 'Please provide filename.');
                    else
                        BM.Filename = filename;
                        if isnumeric(filename)  % if user inputed NormJointsInfo
                            if size(filename,3) ~= 3
                                error('BioMotion:Constructor','Input was numeric, but not in correct format. Needs to be an array of [nPointLights x nFrames x 3] elements.');
                            end
                            BM.Filetype = 'array';
                        else                    % filename is a text string
                            if ~exist(BM.Filename,'file')
                                error('BioMotion:Constructor',['File ''' BM.Filename '''does not exist.']);
                            end
                            
                            dotpos = regexp(filename,'\.');
                            if ~isempty(dotpos)
                                BM.Filetype = filename(dotpos(end)+1:end);
                            else
                                BM.Filetype = 'txt';
                                BM.Filename = [BM.Filename '.' BM.Filetype];
                                warning('BioMotion:Constructor','No file extension provided. If Filetype is not specified, the extension will be assumed to be txt, and the Filetype to be ''data3d'' or ''vanrie''.');
                            end
                        end
                        if nargin > 1
                            if mod(length(varargin),2)
                                error('BioMotion:Constructor','In BioMotion, one of the input arguments is not defined');
                            end
                            for index = 1:2:length(varargin)
                                field   = lower(varargin{index});
                                val     = varargin{index+1};
                                switch field
                                    case 'anchor'
                                        if ~strcmpi(val,'none')
                                            BM.AnchorJoints = unique(val);
                                        else
                                            BM.AnchorJoints = val;
                                        end
                                    case 'filetype'
                                        BM.Filetype = lower(val);
                                    case 'selectjoints'
                                        BM.importjoints = val;
                                    case 'selectframes'
                                        sel2 = [(val-1)*3+1; (val-1)*3+2 ;(val-1)*3+3];
                                        BM.importframes = sel2(:);
                                    case 'normalize' % to make old code still work
                                        if ~strcmpi(val,'none')
                                            BM.AnchorJoints = unique(val);
                                        else
                                            BM.AnchorJoints = val;
                                        end
                                    otherwise
                                        warning('BioMotion:Constructor',['In BioMotion, unknown field: ' upper(field)]); %regexprep(field,'(\<[a-z])','${upper($1)}')]);
                                end
                            end
                            
                            %Redetermine the joint numbers to normalize, based on the selection from 'SelectJoints'
                            if ~isempty(BM.AnchorJoints) && ~isempty(BM.importjoints) && ~strcmpi(BM.AnchorJoints,'none')
                                AnchorJoints_interm=find(ismember(BM.importjoints,BM.AnchorJoints));
                                if length(AnchorJoints_interm) ~= length(BM.AnchorJoints)
                                    error('BioMotion:Constructor','The joints selected for normalization (with Anchor) were not selected for import (with SelectJoints). Please change your selection.');
                                else
                                    BM.AnchorJoints = AnchorJoints_interm;
                                    
                                end
                            end
                        end
                        BM.Create();
                    end
            end
        end
        
        function ji = GetFrame(obj,t,joints)
            % GetFrame  Obtain the joint positions at a requested frame
            %
            % For example. If a BioMotion object was created with the name
            % bm. Then calling bm.GetFrame(1), returns the first frame of
            % the action sequence for all joints.
            % You can make a selection of joints by adding them as a second
            % argument, e.g.: bm.GetFrame(1,[2 4 5 6 9])
            jj = [];
            if nargin == 3
                jj = joints;
            end
            ji = TakeFrameNew(obj,t,jj);
        end
        
        function RotatePath(obj,val)
            % RotatePath rotates the entire movie by the amount specified  in val (in radians).
            % The rotation axis is defined in
            % myMO.RotationAxis. This function achieves the same as calling
            % myMO.Rotation = val, but does it on all frames simultaneously
            % and changes NormJointsInfo. myMO.Rotation performs the
            % rotation on each frame as you call GetFrame. Thus RotatePath
            % may be faster in certain situations, it is also useful if it
            % turns out that your input file contains the joint information
            % upside-down. To put the action upright, set myMO.RotationAxis
            % = [1 0 0] (rotation around x-axis), and then
            % myMO.RotatePath(pi).
            for t = 1:size(obj.NormJointsInfo,2)
                jointinfo                       = squeeze(obj.NormJointsInfo(:,t,:));
                rot                             = jointinfo*RotationMatrix(val,obj.RotationAxis);
                obj.NormJointsInfo(:,t,1)       = rot(1:obj.nPointLights);
                obj.NormJointsInfo(:,t,2)       = rot(obj.nPointLights+(1:obj.nPointLights));
                obj.NormJointsInfo(:,t,3)       = rot((2*obj.nPointLights)+(1:obj.nPointLights));
            end
        end
        
        function set.Invert(obj,val)
            if (val~=0 && val~=1)
                error('BioMotion:Invert','The parameter "Invert" can only be 0 or 1 (false or true)');
            end
            obj.Invert = val;
            
            if val
                obj.invertarray(2,:) = -1;
            else
                obj.invertarray(2,:) = 1;
            end
        end
        
        function set.Scramble(obj,val)
            if (val~=0 && val~=1)
                error('BioMotion:Scramble','The parameter "Scramble" can only be 0 or 1 (false or true)');
            end
            obj.Scramble = val;
            
            if obj.ScrambleOLD ~= val
                obj.ScrambleOLD = val;
                if val
                    ScramblePositions(obj);
                end
            end
        end
        
        function set.Skeleton(obj,val)
            obj.Skeleton = val;
            if ~isempty(obj.InfoLimitedLife)
                obj.SetLimitedLifeParameters('skeleton',val);
            end
        end
        
        function set.LimitedLife(obj,val)
            obj.LimitedLife = val;
            if val == 1 && isempty(obj.InfoLimitedLife)
                obj.SetLimitedLifeParameters;
            end
        end
        
        function SetLimitedLifeParameters(obj,varargin)
            % Change the default parameters for the limited lifetime markers
            % By default the settings for limited lifetime stimuli will be:
            % maxlife = 1, ndots = nPointLights, and type = ?async?.
            % If no skeleton is provided, the individual joints will be
            % used (hence the default for ndots). Note, that this will not
            % lead to a limited lifetime stimulus on the screen, because
            % each joint has a lifetime of one, but will also be
            % immediately redrawn (because by default ndots equals the
            % number of limbsegments, which is the number of joints in this
            % case). To get a real limited lifetime stimulus one will have
            % to provide a skeleton (so joints can be drawn along the limb
            % segments), or decrease the number of displayed dots. To
            % change the settings for limited lifetime stimuli
            % myMO.SetLimitedLifeParameters can be used as follows. To
            % change e.g. the number of dots to 4 per frame, and the
            % lifetime to 6 frames:
            % myMO.SetLimitedLifeParameters(?ndots?,4,?maxlife?,6);
            if size(obj.InfoLimitedLife,1) == 0
                if isempty(obj.Skeleton)
                    obj.Skeleton = [1:obj.nPointLights ; 1:obj.nPointLights]';
                end
                obj.InfoLimitedLife = limitedlifetime(obj.Skeleton);
                %obj.LimitedLife = 1;
            end
            
            if nargin == 2
                field = lower(varargin{1});
                switch field
                    case 'on'
                        obj.LimitedLife = 1;
                    case 'off'
                        obj.LimitedLife = 0;
                    otherwise
                        message = 'Only ''on'' and ''off'' can be used as singular arguments. ';
                        message = [message 'Other arguments need to be a pair of PropertyName and PropertyValue.'];
                        error('BioMotion:SetLimitedLifeParameters',message);
                end
            else
                llbu.skeleton = [];
                llbu.type = [];
                llbu.maxlife = obj.InfoLimitedLife.maxlife;
                llbu.ndots = obj.InfoLimitedLife.ndots;
                for index = 1:2:length(varargin)
                    field = lower(varargin{index});
                    val = varargin{index+1};
                    switch field
                        case 'skeleton'
                            if size(val,2) == 2
                                llbu.skeleton = val;
                            elseif strcmpi(val,'none')
                                llbu.skeleton = [1:obj.nPointLights ; 1:obj.nPointLights]';
                            else
                                error(['BioMotion:SetLimitedLifeParameters','Invalid skeleton. Needs to be a N x 2 matrix']);
                            end
                        case 'type'
                            if ~strcmpi(val,obj.InfoLimitedLife.type)
                                llbu.type = val;
                            end
                        case 'maxlife'
                            llbu.maxlife = val;
                        case 'ndots'
                            llbu.ndots = val;
                    end
                end
                if ~isempty(llbu.skeleton)
                    if ~isempty(llbu.type)
                        obj.InfoLimitedLife = limitedlifetime(llbu.skeleton,llbu.type);
                    else
                        obj.InfoLimitedLife = limitedlifetime(llbu.skeleton);
                    end
                else
                    if ~isempty(llbu.type)
                        obj.InfoLimitedLife = limitedlifetime(obj.Skeleton,llbu.type);
                    end
                end
                obj.InfoLimitedLife.maxlife = llbu.maxlife;
                obj.InfoLimitedLife.ndots   = llbu.ndots;
            end
        end
        
        %% Calculate the Scramble locations
        function ScramblePositions(obj)
            % Will rescramble the marker locations
            % Is based on the values of
            % ScrambleWidth, ScrambleHeight, and ScrambleDepth. These
            % values need to be set before this function is called in order
            % to use custom values for the bounding box for scrambling. If
            % you do not set these values first, then these values are set
            % automatically, meaning the call will be superfluous, because
            % it would otherwise also have been called with the default
            % parameters when scrambling was enabled.
            % See also: ScrambleWidth, ScrambleHeight, ScrambleDepth
            lobj = length(obj);
            for j=1:lobj
                npoints = obj(j).nPointLights;
                dim_defined = [0 0 0];
                %if isempty(obj(j).ScrambleWidth) || isempty(obj(j).ScrambleHeight) || isempty(obj(j).ScrambleDepth) % Determine Scramble width and height in case they are empty
                if length([obj(j).ScrambleWidth obj(j).ScrambleHeight obj(j).ScrambleDepth])<3
                    DetermineScrambleWidthandHeight(obj(j));
                end
                randcolx = zeros(1,npoints);
                randcoly = randcolx; randcolz = randcolx;
                
                for i= 1:size(obj(j).ScrambleDim,2)
                    val = obj(j).ScrambleDim(i);
                    switch val
                        case 'x'
                            randcolx=obj(j).ScrambleWidth*(rand(1,npoints)-0.5);
                            dim_defined(1) = 1;
                        case 'y'
                            randcoly=obj(j).ScrambleHeight*(rand(1,npoints)-0.5);
                            dim_defined(2) = 1;
                        case 'z'
                            randcolz=obj(j).ScrambleDepth*(rand(1,npoints)-0.5);
                            dim_defined(3) = 1;
                    end
                end
                obj(j).ScrambleOffsets=[randcolx ; randcoly; randcolz];
                
                dim_undefined = find(dim_defined==0);
                if ~isempty(dim_undefined)
                    obj(j).ScrambleOffsets(dim_undefined,:) = obj(j).firstframe(dim_undefined,:);
                end
            end
        end
        
        function set.Scale(obj,val)
            if (val<=0)
                error('BioMotion:Scale','The parameter "Scale" should be larger than 0');
            end
            obj.Scale = val;
            SetReferences(obj);
        end
        
        function set.PhaseOffsets(obj,array)
            if isempty(array)
            elseif (min(array)<0 || max(array)>obj.nFrames)
                error('BioMotion:set_PhaseOffsets',['Some requested PhaseOffsets are out of bounds. They need to be larger than 0 and smaller than nFrames.' num2str(array)]);
            end
            obj.PhaseOffsets = array;
        end
        
        function set.RotationAxis(obj,val)
            if numel(val)~=3
                error('BioMotion:RotationAxis','RotationAxis should be a 3-element array.');
            end
            normvect = val/norm(val);
            obj.RotationAxis = normvect;
        end
        
        function obj = SetRotation(obj,val)
            % With SetRotation one can (re)set the rotation to a specific angle.
            % The difference between myMO.SetRotation(val) and
            % myMO.Rotation = val is that the former sets the rotation to
            % val, while the latter increases the current rotation angle by
            % the value specified in val.
            obj.Rotation = -obj.Rotation+val;
        end
        
        function set.Rotation(obj,val)
            obj.Rotation = obj.Rotation + val;
%             if strcmp(obj.AnchorJoints,'none')
%                 obj.rotatereference = obj.lastshown;
%             end
        end
        
        function SmoothLoop(obj)
            % Smoothloop may help in smoothing the transition when looping an action.
            % Sometimes the looping of the movie is not perfect
            % (the transition from the last frame back to the first is not
            % smooth). Smoothloop will calculate the linear distance
            % between the position of each joint in the first and last
            % frame, and then add an increasingly bigger offset to
            % successive frames to completely cancel out the spatial
            % differences by the last frame.
            for joint = 1:obj.nPointLights
                for dim = 1:3 %dimensions
                    vect = obj.NormJointsInfo(joint,:,dim);
                    nonan = find(~isnan(vect));
                    vectstep =(vect(nonan(end))-vect(nonan(1)))/(nonan(end)-nonan(1));
                    stepping = (1:(nonan(end)-nonan(1)+1))*vectstep;
                    obj.NormJointsInfo(joint,nonan(1):nonan(end),dim) = obj.NormJointsInfo(joint,nonan(1):nonan(end),dim)-stepping;
                end
            end
        end
        
        function obj = SetAll(obj,prop,val,spec)
            % Set one property for all objects in an array.
            % When you have initialized several Biomotions in one array,
            % you can use this command to set an option to a certain value
            % for all (or a selection of) Biomotions in that array. There
            % are three ways to use this function.
            % 1) myMOs.SetAll('Scramble',1), will set Scramble to 1 for all
            %    Biomotions in myMOs.
            % 2) You can also specify an array of the same length as myMOs,
            %    but with different values for each Biomotion object. E.g.
            %    if you have four Biomotion objects in myMOs, then
            %    myMOs.SetAll('Scramble',[0 1 1 0]) will set the 1st and
            %    4th to Scramble = 0, then the 2nd and 3rd to Scramble = 1.
            % 3) You can also set specific items (specified in spec) to a
            %    specific value (specified in val). For example, to obtain
            %    the same results as in the second example you could call
            %    myMOs.SetAll('Scramble',1,[2 3]).
            if ischar(val)
                error('BioMotion:SetAll','SetAll does not work with strings. If you want to set the filename use SetFileNames');
            end
            switch nargin
                case 0
                    error('BioMotion:SetAll','SetAll needs at least 2 arguments');
                case 1
                    error('BioMotion:SetAll','SetAll needs at least 2 arguments');
                case 2
                    error('BioMotion:SetAll','SetAll needs at least 2 arguments');
                case 3
                    nvals = size(val,2);
                    if nvals>size(obj,2) && ~ischar(class(val))
                        error('BioMotion:SetAll','SetAll received more input values than there are objects');
                    elseif nvals==1
                        %    [obj(:).(prop)] = deal( val );%this works in release R2008a and up
                        for i=1:size(obj,2)
                            [obj(i).(prop)] = val;
                        end
                    else
                        for i=1:nvals
                            [obj(i).(prop)] = val(i);
                        end
                    end
                case 4
                    nvals = size(val,2);
                    nspec = size(spec,2);
                    if (nvals>size(obj,2) || nspec>size(obj,2) ) && (~ischar(class(val)) && ~ischar(class(spec)))
                        error('BioMotion:SetAll','SetAll received more input values than there are objects');
                    elseif nvals>1
                        if nvals~=nspec
                            error('BioMotion:SetAll','2nd and 3rd argument need to be of equal length, or 2nd argument is of length 1');
                        end
                        for i=1:nspec
                            [obj(spec(i)).(prop)] = val(i);
                        end
                    else
                        %[obj(spec).(prop)] =   deal(val) ;
                        %Does not work in 2007a, so replaced with for loop
                        for i=1:nspec
                            [obj(spec(i)).(prop)] = val;
                        end
                    end
                otherwise
                    error('BioMotion:SetAll','SetAll takes 2 or 3 arguments');
            end
        end
        
        function obj = SetAllVect(obj,prop,val,spec)
            % Works as SetAll, but val is a vector. Therefore, to use
            % option 2 and 3 as explained for SetAll, make a 2D array with
            % the rows containing the different vectors for the different
            % actions.
            if ischar(val)
                error('BioMotion:SetAllVect','SetAllVect does not work with strings. If you want to set the filename use SetFileNames');
            end
            switch nargin
                case 0
                    error('BioMotion:SetAllVect','SetAllVect needs at least 2 arguments');
                case 1
                    error('BioMotion:SetAllVect','SetAllVect needs at least 2 arguments');
                case 2
                    error('BioMotion:SetAllVect','SetAllVect needs at least 2 arguments');
                case 3
                    nvals = size(val,1);
                    if nvals>size(obj,1) && ~ischar(class(val))
                        error('BioMotion:SetAllVect','SetAllVect received more input values than there are objects');
                    elseif nvals==1
                        %    [obj(:).(prop)] = deal( val );%this works in release R2008a and up
                        for i=1:size(obj,2)
                            [obj(i).(prop)] = val;
                        end
                    else
                        for i=1:nvals
                            [obj(i).(prop)] = val(i,:);
                        end
                    end
                case 4
                    nvals = size(val,1);
                    nspec = size(spec,2);
                    if (nvals>size(obj,1) || nspec>size(obj,2) ) && (~ischar(class(val)) && ~ischar(class(spec)))
                        error('BioMotion:SetAllVect','SetAllVect received more input values than there are objects');
                    elseif nvals>1
                        if nvals~=nspec
                            error('BioMotion:SetAllVect','2nd and 3rd argument need to be of equal length, or 2nd argument is of length 1');
                        end
                        for i=1:nspec
                            [obj(spec(i)).(prop)] = val(i,:);
                        end
                    else
                        %[obj(spec).(prop)] =   deal(val) ;
                        %Does not work in 2007a, so replaced with for loop
                        for i=1:nspec
                            [obj(spec(i)).(prop)] = val;
                        end
                        
                    end
                otherwise
                    error('BioMotion:SetAllVect','SetAllVect takes 2 or 3 arguments');
            end
        end
        
        function SaveData3D(obj,name)
            % Saves the JointsInfo data in the Biomotion class in the format 'data3d'.
            % It is the default data accepted by the
            % Biomotion class. You can therefore make a new Biomotion with
            % this data: newBM = BioMotion('outputname'). This save option
            % may be useful when you have created a new action (e.g. by
            % morphing two actions, or otherwise).
            s = obj.JointsInfo'; %#ok<NASGU>
            save(name, 's', '-ASCII');
        end
        
        function bm = Copy(obj)
            % Create an exact copy of another BioMotion object.
            % The to-be-copied object is provided as an argument.
            % B = A.Copy or B = Copy(A) both make B a copy of A.
            bm = BioMotion();
            bminfo = ?BioMotion;
            bmprops = bminfo.Properties;
            
            for pr = 1:size(bmprops,1)
                bm.(bmprops{pr}.Name) = obj.(bmprops{pr}.Name);
            end
            if ~isempty(bm.InfoLimitedLife)
                bm.InfoLimitedLife = Copy(obj.InfoLimitedLife);
            end
            bm.Scale = 1/(obj.Scale^2);
            bm.Scale = obj.Scale;
            addlistener(bm,'PhaseScramble','PostSet',@(src,evnt)handlePropertyEvents(bm,src,bm.PhaseScramble));
        end
        
        function disp(obj)
            % Overloaded default disp function in Matlab.
            % This function is executed whenever disp is called explicitly,
            % or when a BioMotion object is not terminated by a semicolon.
            % The output of the overloaded disp closely resembles the
            % default disp function in later versions of Matlab. However,
            % Matlab 2007a does not provide useful information when disp is
            % called, and this function provides users of 2007a (and later
            % versions with that information.
            if numel(obj)>1
                fieldn = fieldnames(obj(1));
                
                message = sprintf('%d',size(obj,1));
                for i=2:length(size(obj))
                    message = sprintf([message 'x%d'],size(obj,i));
                end
                fprintf(['   ' message ' <a href="matlab:helpPopup %s" style="font-weight:bold">%s</a> array with properties:\n\n'],class(obj),class(obj));
                for f = 1:length(fieldn)
                    fprintf('     %s\n',fieldn{f});
                end
            else
                fieldn = fieldnames(obj);
                nprops = size(fieldn,1);
                namelength = zeros(1,nprops);
                for pr = 1:nprops
                    namelength(pr) = length(fieldn{pr});
                end
                maxlength = max(namelength);
                spacing_arg = ['% ', num2str(maxlength+5),'s'];
                
                fprintf('   <a href="matlab:helpPopup %s" style="font-weight:bold">%s</a> with properties:\n\n',class(obj),class(obj));
                
                for pr = 1:nprops
                    val = obj.(fieldn{pr});
                    if isempty(val)
                        fprintf([spacing_arg ': []\n'], fieldn{pr});
                    elseif ischar(val)
                        fprintf([spacing_arg ': ''%s''\n'], fieldn{pr},val);
                    elseif isnumeric(val) || isa(val,'logical')
                        if size(val,1)==1
                            if size(val,2) == 1
                                fprintf([spacing_arg ': %s\n'], fieldn{pr},num2str(val));
                            else
                                fprintf([spacing_arg ': [%s]\n'], fieldn{pr},num2str(val));
                            end
                        else
                            message = sprintf('%d',size(val,1));
                            for i=2:length(size(val))
                                message = sprintf([message 'x%d'],size(val,i));
                            end
                            fprintf([spacing_arg ': [' message ' %s]\n'], fieldn{pr},class(obj.(fieldn{pr})));
                        end
                    else
                        message = sprintf('%d',size(val,1));
                        for i=2:length(size(val))
                            message = sprintf([message 'x%d'],size(val,i));
                        end
                        fprintf([spacing_arg ': [' message ' %s]\n'], fieldn{pr},class(obj.(fieldn{pr})));
                    end
                end
            end
            fprintf('\n   <a href="matlab:run methods(BioMotion)">methods</a> for class %s \n\n',class(obj));
        end
        
    end % end of public methods
    
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%_Private methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = 'private')
        
        function Create(obj)
            nobj=size(obj,2);
            for i = 1: nobj
                switch obj(i).Filetype
                    case {'ptd', 'pollick'}
                        f       = fopen(obj(i).Filename);
                        tline   = str2double(fgetl(f));             % number of frames according to the ptd file
                        pos     = ftell(f);                         % character position after reading 'tline'
                        line2   = fgetl(f);                         % read second line
                        tline2  = length(regexp(line2,'\ '));       % How many space (=number of joints) are defined on each line
                        if ~(line2(end) == ' ')                     % If the line does not end with a space, need to add one more joint
                            tline2 = tline2+1;
                        end
                        fseek(f,pos,'bof');                         % Go back to the position after reading the very first line
                        intermd = fscanf(f,'%f',[tline2 tline]);    % Read all values in the file
                        fclose(f);                                  % close the input file
                        obj(i).nPointLights = size(intermd,1)/3;    % determine the number of joints
                        for tt = 1:tline                            % input the values into JointsInfo
                            dd = reshape(intermd(:,tt),3,obj(i).nPointLights);
                            dd = dd([1 3 2],:);
                            obj(i).JointsInfo = [obj(i).JointsInfo ; dd];
                        end
                        if isempty(obj(i).AnchorJoints)
                            obj(i).AnchorJoints = [10 13];
                        end
                        obj(i).JointsInfo = obj(i).JointsInfo';
                        if ~isempty(obj(i).importjoints)
                            obj(i).JointsInfo = obj(i).JointsInfo(obj(i).importjoints,:);
                            obj(i).nPointLights = size(obj(i).JointsInfo,1);
                            if any(obj(i).AnchorJoints>obj(i).nPointLights) && ~strcmpi(obj(i).AnchorJoints,'none')
                                warning('BioMotion:constructor', 'AnchorJoints contains values that are larger than the number of available markers. AnchorJoints will be set to 1:nPointLights.');
                                obj(i).AnchorJoints = 1:obj(i).nPointLights;
                            end
                        end
                        if ~isempty(obj(i).importframes)
                            obj(i).JointsInfo = obj(i).JointsInfo(:,obj(i).importframes);
                        end
                        obj(i).NormJointsInfo  = NormJoints(obj(i));
                    case 'c3d'
                        obj(i).JointsInfo = c3d_converter(obj(i).Filename,obj(i).importjoints);
                        obj(i).nPointLights = size(obj(i).JointsInfo,1);
                        if isempty(obj(i).AnchorJoints)
                            obj(i).AnchorJoints = 1:obj(i).nPointLights;
                        end
                        if ~isempty(obj(i).importframes)
                            obj(i).JointsInfo = obj(i).JointsInfo(:,obj(i).importframes);
                        end
                        obj(i).NormJointsInfo  = NormJoints(obj(i));
                    case 'bvh'
                        obj(i).JointsInfo = bvh_converter(obj(i).Filename,obj(i).importjoints);
                        obj(i).nPointLights = size(obj(i).JointsInfo,1);
                        if isempty(obj(i).AnchorJoints)
                            obj(i).AnchorJoints = 1:obj(i).nPointLights;
                        end
                        if ~isempty(obj(i).importframes)
                            obj(i).JointsInfo = obj(i).JointsInfo(:,obj(i).importframes);
                        end
                        obj(i).NormJointsInfo  = NormJoints(obj(i));
                    case 'vanrie'
                        obj(i).loadvanrie();
                    case 'data3d'
                        obj(i).JointsInfo = load(obj(i).Filename)';
                        obj(i).nPointLights = size(obj(i).JointsInfo,1);
                        if isempty(obj(i).AnchorJoints)
                            obj(i).AnchorJoints = [8 11];
                        end
                        if ~isempty(obj(i).importjoints)
                            obj(i).JointsInfo = obj(i).JointsInfo(obj(i).importjoints,:);
                            obj(i).nPointLights = size(obj(i).JointsInfo,1);
                            if any(obj(i).AnchorJoints>obj(i).nPointLights) && ~strcmpi(obj(i).AnchorJoints,'none')
                                warning('BioMotion:constructor', 'AnchorJoints contains values that are larger than the number of available markers. AnchorJoints will be set to 1:nPointLights.');
                                obj(i).AnchorJoints = 1:obj(i).nPointLights;
                            end
                        end
                        if ~isempty(obj(i).importframes)
                            obj(i).JointsInfo = obj(i).JointsInfo(:,obj(i).importframes);
                        end
                        obj(i).NormJointsInfo  = NormJoints(obj(i));
                    case 'array'
                        obj(i).CreateFromNormJoints(obj(i).Filename);
                        obj(i).Filename = [];
                        if ~isempty(obj(i).importjoints)
                            obj(i).JointsInfo = obj(i).JointsInfo(obj(i).importjoints,:);
                            obj(i).nPointLights = size(obj(i).JointsInfo,1);
                            if any(obj(i).AnchorJoints>obj(i).nPointLights) && ~strcmpi(obj(i).AnchorJoints,'none')
                                warning('BioMotion:constructor', 'AnchorJoints contains values that are larger than the number of available markers. AnchorJoints will be set to 1:nPointLights.');
                                obj(i).AnchorJoints = 1:obj(i).nPointLights;
                            end
                        end
                        if ~isempty(obj(i).importframes)
                            obj(i).JointsInfo = obj(i).JointsInfo(:,obj(i).importframes);
                        end
                        obj(i).NormJointsInfo  = NormJoints(obj(i));
                    otherwise                                       %could also be a case 'txt'
                        % warning('BioMotion:Create','Filetype is unspecified or unknown. Will try to guess filetype');
                        obj(i).JointsInfo = load(obj(i).Filename)';
                        if ~isempty(obj(i).JointsInfo)               %% assumption is that data is in data3d format
                            obj(i).nPointLights = size(obj(i).JointsInfo,1);
                            if isempty(obj(i).AnchorJoints)
                                obj(i).AnchorJoints = [8 11];
                            end
                            if ~isempty(obj(i).importjoints)
                                obj(i).JointsInfo = obj(i).JointsInfo(obj(i).importjoints,:);
                                obj(i).nPointLights = size(obj(i).JointsInfo,1);
                                if any(obj(i).AnchorJoints>obj(i).nPointLights) && ~strcmpi(obj(i).AnchorJoints,'none')
                                    warning('BioMotion:constructor', 'AnchorJoints contains values that are larger than the number of available markers. AnchorJoints will be set to 1:nPointLights.');
                                    obj(i).AnchorJoints = 1:obj(i).nPointLights;
                                end
                            end
                            if ~isempty(obj(i).importframes)
                                obj(i).JointsInfo = obj(i).JointsInfo(:,obj(i).importframes);
                            end
                            obj(i).NormJointsInfo  = NormJoints(obj(i));
                        else                                        %% assumption is that data is in Vanrie et al format
                            obj(i).loadvanrie();
                        end
                end % end of switch
                if ~strcmp(obj(i).AnchorJoints,'none') && ~isempty(setdiff(obj(i).AnchorJoints,1:obj(i).nPointLights))
                    error('BioMotion:constructor', 'Requested reference joints do not fall in range of available joints.');
                end
                SetReferences(obj);
                addlistener(obj,'PhaseScramble','PostSet',@(src,evnt)handlePropertyEvents(obj,src,obj.PhaseScramble));
            end %loop over objects
        end %create
        
        function loadvanrie(obj)
            obj.nPointLights = 13;
            f       = fopen(obj.Filename);
            tline   = fgetl(f);                     %read first line
            tliner  = tline(1:2:length(tline));     %skip every 2nd character (because they are spaces)
            eqsign  = regexp(tliner,'=');           %find '=' sign
            letm    = regexp(tliner,'m');           %find letter 'm'
            nfr     = str2double(tliner(eqsign(1)+2:letm(2)-2)); %take the characters that mention the number of frames, and convert to double
            s   = zeros(nfr*obj.nPointLights,3);    %allocate memory
            for rlin = 1:nfr*obj.nPointLights;
                fgetl(f);                           %empty read, Vanrie files have empty lines when Matlab reads them...
                tline = fgetl(f);                   %get line of data points
                s(rlin,:) = sscanf(tline(2:2:length(tline)),'%d %d %d')'; %parse character string into three numbers
            end
            fclose(f);
            
            s = [s(:,1) s(:,3) s(:,2)];             % rearrage from [x, z, y] to [x, y, z]
            r = reshape(s,obj.nPointLights,size(s,1)/obj.nPointLights,3);
            a = permute(r,[1 3 2]);
            if isempty(obj.AnchorJoints)
                obj.AnchorJoints = [8 9];
            end
            obj.JointsInfo = reshape(a,obj.nPointLights,size(s,1)/obj.nPointLights*3);
            if ~isempty(obj.importjoints)
                obj.JointsInfo = obj.JointsInfo(obj.importjoints,:);
                obj.nPointLights = size(obj.JointsInfo,1);
                if any(obj.AnchorJoints>obj.nPointLights) && ~strcmpi(obj.AnchorJoints,'none')
                    warning('BioMotion:constructor', 'AnchorJoints contains values that are larger than the number of available markers. AnchorJoints will be set to 1:nPointLights.');
                    obj.AnchorJoints = 1:obj.nPointLights;
                end
            end
            if ~isempty(obj.importframes)
                obj.JointsInfo = obj.JointsInfo(:,obj.importframes);
            end
            obj.NormJointsInfo  = NormJoints(obj);
            obj.Scale = 1;
        end
        
        function CreateFromNormJoints(obj,normj)
            nobj=size(obj,2);
            for i = 1: nobj
                obj(i).NormJointsInfo=normj;
                obj(i).nPointLights = size(obj(i).NormJointsInfo,1);
                ConstructJointsInfoFromNormJointsInfo(obj(i));
                
                if isempty(obj(i).AnchorJoints)
                    obj(i).AnchorJoints = [8 11];
                end
            end
        end
        
        function SetReferences(obj)
            obj.NormJointsInfo  = obj.NormJointsInfo * obj.Scale;
            normstart1          = obj.NormJointsInfo(:,1,:);
            obj.meanstartpos    = squeeze(meanwithnans(normstart1))';
            obj.nFrames         = size(obj.NormJointsInfo,2);
            obj.firstframe      = squeeze(obj.NormJointsInfo(:,1,:))';
            obj.lastshown       = obj.firstframe;
            %obj.rotatereference = obj.firstframe;
            if isempty(obj.invertarray)
                obj.invertarray     = ones(3,obj.nPointLights);
            end
            if isempty(obj.ScrambleOffsets)
                obj.ScrambleOffsets  = zeros(3,obj.nPointLights);
            end
        end
        
        %% Normalize to a provided set of reference joints
        function [NormJointsInfo] = NormJoints(obj)
            z = obj.JointsInfo;
            
            takerow             = 1:3:size(z,2);
            intermXYZ           = zeros(obj.nPointLights,length(takerow),3);
            intermXYZ(:,:,1)    = z(:,takerow);
            intermXYZ(:,:,2)    = z(:,takerow+1);
            intermXYZ(:,:,3)    = z(:,takerow+2);
            
            if ~strcmp(obj.AnchorJoints,'none')
                intersumx = mean(intermXYZ(obj.AnchorJoints,:,:),1);
                reference       = repmat(intersumx , obj.nPointLights,1);
                NormJointsInfo  = intermXYZ-reference;
            else
                NormJointsInfo  = intermXYZ;
            end
        end
        
        function  ConstructJointsInfoFromNormJointsInfo(obj)
            a = permute(obj.NormJointsInfo,[1 3 2]);
            obj.JointsInfo=reshape(a,obj.nPointLights,size(obj.NormJointsInfo,2)*3)./obj.Scale;
        end
        
        
        %% TakeFrameNew replaced TakeFrame and TakeFrameMod
        function jointinfo = TakeFrameNew(obj,t,joints)
            lobj = length(obj);
            if lobj>1 && length(t) == 1
                t = t * ones(1,lobj);
            end
            nframes = zeros(1,lobj);
            for i = 1:lobj      % nframes = [obj.nFrames]; % does not work in 2007a, replaced with for-loop
                nframes(i)     = obj(i).nFrames;
            end
            ji = cell(1,lobj);  % containts jointinfo in cellformat;
            for i=1:lobj
                npoints = obj(i).nPointLights;
                if obj(i).Loop
                    tt = mod(t(i)-1,nframes(i))+1;
                else
                    tt = t(i);
                end
                if tt < 1 || tt > nframes(i)
                    error('BioMotion:TakeFrameNew','Requested frame out of bounds. Request other frame, or set Loop to 1');
                end
                
                obj(i).lastshown = reshape(obj(i).NormJointsInfo(:,tt,:),npoints,3)';
                
                % Scramble
                if obj(i).Scramble
                    obj(i).lastshown = obj(i).lastshown-obj(i).firstframe+(obj(i).meanstartpos(ones(1,npoints),:)'+obj(i).ScrambleOffsets);
                end
                
                % Rotate
                if obj(i).Rotation
                    RotatePLA(obj(i));
                end
                
                % Invert
                obj(i).lastshown = obj(i).lastshown.*obj(i).invertarray;
                
                % Reposition
                obj(i).lastshown = obj(i).lastshown + obj(i).Position3D(ones(1,npoints),:)';
                
                if isempty(joints) %~exist('joints','var')  || isempty(joints)
                    ji{i} = obj(i).lastshown;
                else
                    if size(joints,1)>1
                        jj=joints(i,:);
                    else
                        jj=joints;
                    end
                    if ~(any(jj<1) || any(jj>npoints)) %isempty(setdiff(jj,1:npoints))
                        ji{i} = obj(i).lastshown(:,jj);
                    else
                        error('BioMotion:TakeFrame', 'Requested reference joints do not fall in range of available joints.');
                    end
                end
                if size(obj(i).InfoLimitedLife)
                    if obj(i).LimitedLife
                        ji{i} = obj(i).InfoLimitedLife.Update(obj(i).lastshown);
                    end
                end
            end
            jointinfo = cat(2,ji{1,:});
        end
        
        
        
        %% Determine Scramble and Height
        function DetermineScrambleWidthandHeight(obj)
            for i=1:size(obj,2)
                if isempty(obj(i).ScrambleWidth)
                    obj(i).ScrambleWidth  = max(max(obj(i).NormJointsInfo(:,:,1)))-min(min(obj(i).NormJointsInfo(:,:,1)));
                end
                if isempty(obj(i).ScrambleHeight)
                    obj(i).ScrambleHeight = max(max(obj(i).NormJointsInfo(:,:,2)))-min(min(obj(i).NormJointsInfo(:,:,2)));
                end
                if isempty(obj(i).ScrambleDepth)
                    obj(i).ScrambleDepth  = max(max(obj(i).NormJointsInfo(:,:,3)))-min(min(obj(i).NormJointsInfo(:,:,3)));
                end
            end
        end
        
        function PhaseScramblePLA(obj)
            if ~isempty(obj.PhaseOffsets)
                dotXYZ = obj.NormJointsInfo;
                for randomstarts = 1:obj.nPointLights
                    dotXYZ(randomstarts,:,:)=circshift(dotXYZ(randomstarts,:,:),[0,obj.PhaseOffsets(randomstarts)]);
                end
                if isempty(obj.sumphaseoffsets)
                    obj.sumphaseoffsets = obj.PhaseOffsets;
                else
                    obj.sumphaseoffsets = obj.sumphaseoffsets + obj.PhaseOffsets;
                end
                obj.NormJointsInfo = dotXYZ;
            end
        end
        
        function SetScramblePhase(obj)
            if isempty(obj.PhaseOffsets)
                obj.PhaseOffsets = ceil(rand(1,obj.nPointLights)*size(obj.NormJointsInfo,2));
            end
        end
        
        function ReSetPhaseScramblePLA(obj)
            if ~isempty(obj.PhaseOffsets)
                obj.PhaseOffsets=mod(obj.nFrames-obj.sumphaseoffsets,obj.nFrames);
                PhaseScramblePLA(obj);
                obj.PhaseOffsets = [];
                obj.sumphaseoffsets = [];
            end
        end
        
        function RotatePLA(obj)
            % for optimization call obj.rotationreference only once.
            % calculate mean (m) inline, not call function. Call repmat
            % incline to produce rotr. The next 3 lines are equivalent
            % to (but > 3 times faster):
            % rotr = repmat(mean(obj.rotatereference,2),1,obj.nPointLights);
            rf = obj.lastshown; %obj.rotatereference;
            m = sum(rf,2)/size(rf,2);
            rotr = m(:,ones(1,size(rf,2)));
            obj.lastshown = (RotationMatrix(obj.Rotation,obj.RotationAxis)*(obj.lastshown-rotr)) + rotr;
            
        end
        
        function handlePropertyEvents(obj,src,evnt)
            switch src.Name % switch on the property name
                case 'PhaseScramble'
                    if evnt ==1
                        SetScramblePhase(obj);
                        PhaseScramblePLA(obj);
                    elseif evnt == 0
                        ReSetPhaseScramblePLA(obj);
                    elseif strcmpi(evnt,'rescramble') || evnt == 2
                        ReSetPhaseScramblePLA(obj);
                        SetScramblePhase(obj);
                        PhaseScramblePLA(obj);
                    elseif evnt == 3
                        bu = obj.PhaseOffsets;
                        ReSetPhaseScramblePLA(obj);
                        obj.PhaseOffsets = bu;
                        PhaseScramblePLA(obj);
                    end
            end
        end
    end % end of private methods
end % classdef


