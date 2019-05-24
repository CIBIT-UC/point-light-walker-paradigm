function JointInfo = c3d_converter(fullfilename, takejoints)
% convert c3d files to data3d files
% based on c3d converter files provided on http://mocap.cs.cmu.edu/tools.php,
% written by Q Youn Hong, using code from Alan Morris and Jaap Harlaar.
%
% To get a 13-jointed walker from the Carnegie Mellon Mocap, enter
% takejoints as [24 23 12 8 35 9 17 1 25 36 2 22 32], at least for movie
% 02_01.c3d. It may be different for other actions... The head is really
% the shoulder, but it look reasonable good. Other actions only have 13
% joints to start with....
%
% JvB jan 2013

if nargin < 2
    takejoints = [];
end

Markers = readC3D(fullfilename);
     
m2 = permute(Markers,[2 3 1]);
mbu = m2;
m2(:,2,:) = mbu(:,3,:);
m2(:,3,:) = mbu(:,2,:);

if ~isempty(takejoints)
    m2 = m2(takejoints,:,:);
end

JointInfo=reshape(m2,size(m2,1),size(m2,2)*size(m2,3));
end