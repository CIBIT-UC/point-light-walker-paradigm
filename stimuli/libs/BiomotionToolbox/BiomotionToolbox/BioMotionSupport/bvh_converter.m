function jointinfo = bvh_converter(filename,dotnum)
% This code reads in a bvh file and generates a .data3d.txt file. The
% .data3d.txt is the file that is the default input for the BioMotion
% class.
%
% Usage: bvhconverter(filename [,dotnum])
%
% filename: give the full filename, including extension
%
% dotnum, the indices of the joints you want to scan
%
% We tested it on several datasets. In some datesets the order of
% xyz is different, which will cause the action to be rotated when
% displayed with the default settings of the BioMotion class. This can be
% corrected with the .Rotation or .RotatePath() functionality in the
% BioMotion class, or with the dimchange argument in this function.
%
% HL: finalized version done on 8/20
% JvB: cleaned up, use dlmwrite(), and made such that dotnum is optional.

[hd,motion,jointspos]   = read_bvh(filename);

if nargin < 2 || isempty(dotnum)
    dotnum = 1:(size(motion,2)/3-1);
end

% Save the data
jointspos = jointspos(:,dotnum,:);
a = permute(jointspos,[2 3 1]);
jointinfo = reshape(a,size(jointspos,2),size(jointspos,1)*3);
end


