function SetProjection(window,varargin)
% Usage: SetProjection(window_struct [,param1, valpar1] [, param2,
% valpar2] ...)
%
% SetProjection set the projection type when using OpenGL with MATLAB
% Default is Orthogonal projection. Projection can also be set to
% 'Perspective'.
%
% Generally, typing SetProjection(window_struc) is sufficient.
% window_struct is returns by SetScreen().
%
% Parameters you may want to change:
% 'GazePosition' , default is [0 0 0]
% 'CameraPosition', default is [0 0 300]
% 'CameraOrientation', default is [0 1 0]
% 'Projection', default is 'Orthogonal' (can be set to 'Perspective')
% 'DepthCuttoff', default is max(1000,camerapos(3))*1.5 Any values larger
% than the cutoff will not be drawn by OpenGL
%
% JvB, Aug/Sept 2001
    if nargin < 1
        clear screen;
        error('SetPerspectiveProjection:InvalidParam','You need to provide the Screen information structure to use this function.');
    end
    if ~window.OpenGL
        clear screen;
        error('SetPerspectiveProjection:InvalidParam','You need to set OpenGL to 1 in the Screen information structure when you initialize the screen.');
    end

    global GL; % Make OpenGL code accessable

    gazepos         = [0 0 0];
    camerapos       = [0 0 300];
    cameraorient    = [0 1 0];
    perspective     = 0;
    cutoff = max(1000,camerapos(3))*1.5;

    if ~isempty(varargin)
        for index = 1:2:length(varargin)
            field = varargin{index};
            val = varargin{index+1};
            switch field
                case {'GazePosition' , 'gazeposition'}
                    if length(val)==3
                        gazepos = val;
                    else
                        warning('SetPerspectiveProjection:InvalidParam',['Invalid value for "GazePosition". GazePosition is 3 element array, and  will be set to', gazepos]);
                    end
                case {'CameraPosition' , 'cameraposition'}
                    if length(val)==3
                        camerapos = val;
                        cutoff = max(1000,camerapos(3))*1.5;
                    else
                        warning('SetPerspectiveProjection:InvalidParam',['Invalid value for "CameraPosition". CameraPosition is 3 element array, and  will be set to ',camerapos]);
                    end
                case {'CameraOrientation' , 'cameraorientation'}
                    if length(val)==3
                        cameraorient = val;
                    else
                        warning('SetPerspectiveProjection:InvalidParam',['Invalid value for "CameraOrientation". CameraOrientation is 3 element array, and  will be set to ',cameraorient]);
                    end
                case {'Projection' , 'projection'}
                    switch  val
                        case {'Perspective' , 'perspective'}
                            perspective = 1;
                        case {'Orthogonal' , 'orthogonal'}
                            perspective = 0;
                        otherwise
                            warning('SetPerspectiveProjection:InvalidParam','Invalid value for "Projection". Choose from "Perspective" and "Orthogonal". Projection is set to "Orthogonal".');
                            perspective = 0;
                    end
                case {'DepthCuttoff' , 'depthcuttoff'}
                    if val>0
                        cutoff = val;
                    else
                        warning('SetPerspectiveProjection:InvalidParam',['Invalid value for "DepthCuttoff". DepthCuttoff should be larger than 0. It will be set to', cutoff]);
                    end
            end
        end
    end



    Screen('BeginOpenGL', window.Number);     % Setup the OpenGL rendering context

    glViewport(0, 0, RectWidth(window.Rect), RectHeight(window.Rect));

    % Set projection matrix: perspective projection,
    glMatrixMode(GL.PROJECTION);
    glLoadIdentity;

    if perspective
        gluPerspective(25,1/window.AspectRatio,0.1,cutoff); % Field of view is 25 degrees from line of sight.
    else
        glOrtho(-window.Width/2,window.Width/2,-window.Height/2,window.Height/2,-cutoff,cutoff);
    end

    %Setup modelview matrix
    glMatrixMode(GL.MODELVIEW);
    glLoadIdentity;

    %Cam is located at 3D position (first 3 args), fixates at (next 3 args, points upright (0,1,0)
    gluLookAt(camerapos(1),camerapos(2),camerapos(3),gazepos(1),gazepos(2),gazepos(3),cameraorient(1),cameraorient(2),cameraorient(3));

    Screen('EndOpenGL', window.Number);
end