classdef limitedlifetime < handle
    % Draw limited lifetime samples along a skeleton.
    %
    % limitedlifetime is a class that needs to be constructed before using it.
    % Construction can be done like this:
    %
    % limlife = limitedlifetime(skel,type);
    %
    % limlife   is the class that will be used in the remainder of the
    %           program.
    % skel      is the definition of the skeleton along which the limited
    %           lifetime samples will be drawn. The skeleton defines the
    %           links between joints in the biological motion object, that
    %           will be inputed in the Update function. The skeleton needs
    %           to be defined as a n-by-2 array, with the n limbsegments
    %           delimited by two joint indices. If skel is defined as
    %           [1 2; 2 3; 3 4; 10 13], there will be 4 samples drawn, one
    %           between joint 1 and 2, one between joint 2 and 3, etc. The
    %           skeleton needs to be defined, otherwise an error is
    %           returned.
    %
    % type      is an optional property. It can be 'async' (default), or
    %           'sync'. This determines if the samples will be initialized
    %           with the same age ('sync'), and thus resampled at the same
    %           time when they reach the maximum lifetime; or if they are
    %           initialized with random ages ('async') and thus resampled
    %           asynchronously.
    %
    %
    % In the stimulus presentation loop, one needs to call the function
    % Update, as follows:
    %
    % limlifesample = limlife.Update(bmdots)
    %
    % bmdots is an array of joint locations, which in the setting of the
    % BiomotionToolbox is normally obtained with the GetFrame function.
    % e.g. bmdots = bm.GetFrame(currentframe).
    % Each time the Update function is called, the samples will 'age' by 1
    % frame, and samples that are too old will be resampled. Update
    % returns the limitedlifetime samples that can be drawn with e.g.
    % moglDrawDots3D.
    %
    % Two properties can be set:
    % maxlife       the maximum lifetime of each sample (in number of
    %               Updates)
    % ndots         the number of samples that will be returned at each
    %               Update (is a subsample of the number of limbsegments)
    %
    % May/June 2013. Initial coding. Jeroen van Boxtel
    %
    % See also: BioMotion.GetFrame, BioMotion, Update
    
    % Private properties. Cannot be set or accessed.
    properties (SetAccess = 'private', GetAccess = 'private')
        lifetime            % current lifetime of each marker
        skeleton            % skeleton along which to draw the random positions
        sample              % sample of the the randomly drawn locations
        segmentdist         % location of markers along limb segment (from 0 to 1). Note that not all segments may be used. Those that are used are '1' in takedots        
    end
    
    % These are public, can be set and accessed.
    properties(GetAccess = 'public', SetAccess = 'public')
        maxlife     = 1;    % maximum lifetime of the markers
        ndots               % number of markers shown on each Update
        type                % replace the limited lifetime markers asynchronously ('async' (default)), or synchronously ('sync')
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = 'private', GetAccess = 'public')
        takedots            % logic array, indicating which markers are displayed and which ones are not
    end
    
    
    methods
        function LL = limitedlifetime(skel,type)
            switch nargin
                case 0
                    error('limitedlifetime:constructor', 'Insufficient number of input arguments.');
                case 1
                    LL.skeleton     = skel;
                    LL.takedots     = ones(1,size(skel,1));
                    LL.lifetime     = ones(1,size(skel,1));
                    LL.ndots    = size(skel,1);
                    LL.type         = 'async';
                case 2
                    LL.skeleton     = skel;
                    LL.takedots     = ones(1,size(skel,1));
                    LL.lifetime     = ones(1,size(skel,1));
                    LL.ndots    = size(skel,1);
                    if any(strcmpi(type,{'sync','async'}))
                        LL.type     = lower(type);
                    else
                        error('limitedlifetime:constructor', 'Type of Snychonization is unknow (use ''sync'' or ''async'').');
                    end
            end
            LL.segmentdist = rand(1,size(LL.skeleton,1));
        end
        
        function sample = Update(obj,matin)
            obj.lifetime(logical(obj.takedots)) = obj.lifetime(logical(obj.takedots)) + 1;
            too_old = obj.lifetime > obj.maxlife;
            obj.GetNewSample(too_old,matin);
            sample = obj.sample;
        end
        
        function set.ndots(obj,val)
            skelsize = size(obj.skeleton,1);
            if val >  skelsize
                warning('limitedlifetime:ndots', 'Requested more dots then skeleton-edges. Reduced ndots to the number of skeleton segments. This may not be a problem. For example, this may happen when you change the skeleton to another size, or when you set the skeleton after you set LimitedLife to 1.');
                val = skelsize;
            end
            obj.ndots = val;
            temp = randperm(skelsize);
            obj.takedots = zeros(1,skelsize);
            obj.takedots(temp(1:val)) = 1;
            if val ~= skelsize
                obj.lifetime(temp(val+1:skelsize)) = 1;
            end
        end
        
        function set.maxlife(obj,val)
            if val<1
                error('limitedlifetime:maxlife', 'maxlife needs to be larger than 0.');
            else
                obj.maxlife = val;
                if strcmp(obj.type,'async')
                    obj.lifetime = randi(val,[1 size(obj.lifetime,2)]);
                end
            end
        end
        
        function limlife = Copy(obj)
            % Create an exact copy of another LimitedLifetime object.
            % The to-be-copied object is provided as an argument.
            % B = A.Copy or B = Copy(A) both make B a copy of A.
            limlife = limitedlifetime(obj.skeleton);
            llinfo = ?limitedlifetime;
            llprops = llinfo.Properties;
            
            for pr = 1:size(llprops,1)
                limlife.(llprops{pr}.Name) = obj.(llprops{pr}.Name);
            end
        end
    end % end of public methods
    
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%_Private methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = 'private')
        function GetNewSample(obj,arr_too_old,matin)
            if any(arr_too_old)
                rndist = rand(1,size(obj.skeleton,1));
                obj.lifetime(arr_too_old) = 1;
                toreplace = obj.SelReplacements(arr_too_old);
                for vertex_i = toreplace  % for all limbs that need to be replaced
                    obj.segmentdist(vertex_i) = rndist(vertex_i);
                end
            end
            alldiff=diff(matin(:,obj.skeleton',:)');
            takepos=2*((1:size(obj.skeleton,1))-1)+1;
            samp = matin(:,obj.skeleton(:,1),:)+([obj.segmentdist ;obj.segmentdist;obj.segmentdist].*alldiff(takepos,:)');
            obj.sample = samp(:,logical(obj.takedots));
        end
        
        function toreplace = SelReplacements(obj,arr_too_old)
            keepfornow  = logical(obj.takedots)&~arr_too_old;
            nreplace    = obj.ndots-sum(keepfornow);
            obj.takedots = keepfornow;
            
            replpos     = find(~keepfornow);   % open positions
            temp        = randperm(length(replpos)); %put indices in random order)
            obj.takedots(replpos(temp(1:nreplace))) = 1; %take the first N (=nreplace) indices) and put them to 1, takedots now contains 1's where the keepfornow dots are, and the new dots
            toreplace   = find(logical(obj.takedots)&~keepfornow);
        end
    end % end of private methods
end % classdef
