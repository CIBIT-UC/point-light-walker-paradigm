function [hd,motion,jointspos] = read_bvh(fn)
%% FOR LINE DRAWING
fid = fopen(fn,'r');
Data = textscan(fid, '%s', 'delimiter', '\n', 'whitespace', '');
dd=Data{1};
%if isempty(jointsnum)
totpoints = length(str2num(cell2mat(dd(end))));%#ok<ST2NM>
jointsnum = totpoints/3-1;
%end
motioninfostart = find(strcmp(dd,'MOTION'))+3;
numframes = length(dd)-motioninfostart+1;
fclose(fid);
fid = fopen(fn,'r');

hd.str = [];  ch_id = 1; hir_lev = []; hir_name = []; hir_ch_id=[];ori = 0;

count = 0;
conds = zeros(jointsnum,3);                 %3: (offset)  Xrotation, Zrotation, Yrotation
offsetval = zeros(jointsnum,3);             %% offset  %% get rid of 5 end points
condsout = zeros(jointsnum*3+3);
offsetout = zeros(jointsnum*3+3);
hirparid = zeros(jointsnum,jointsnum)-1;    %% all parent nodes for each joint including the joint itself
countoffset = 0;
countlevel = 0;
while ~feof(fid),
    l = fgetl(fid);
    
    [tok,R] = strtok(l);
    %tag=-1;
    if strcmp(tok,'ROOT') || strcmp(tok,'JOINT') || strcmp(tok,'End'),
        name = [strtok(R),'.'];
        hir_lev = [hir_lev,length(name)];
        hir_name = [hir_name,name];
        hir_ch_id = [hir_ch_id, ch_id];
        
        if strcmp(tok,'End')==0
            countlevel = countlevel+1;
            hirparid(countlevel,1:size(hir_ch_id,2)) = floor((hir_ch_id+1)/3);
            %hirparname{countlevel}=name;
        else
            %tag = 1;
            
        end;
        
    elseif strcmp(tok,'{'),
    elseif strcmp(tok,'}');
        hir_lev = hir_lev(1:end-1);
        hir_name = hir_name(1:sum(hir_lev));
        hir_ch_id = hir_ch_id(1:end-1);
        
    elseif strcmp(tok,'OFFSET'),
        ori = ori + 1;
        ori_name = hir_name(sum(hir_lev)-hir_lev(end)+1:sum(hir_lev));
        ori_name(end) = [];
        if strcmp(ori_name,'Site')~=0
            ori = ori-1;
        else
            hd.ori_name{ori} = ori_name;
            hd.ori(ori,:) = cell2mat(textscan(R,'%f%f%f'));
            countoffset = countoffset+1;
            offsetval(countoffset,:)=hd.ori(ori,:);
        end;
        
    elseif strcmp(tok,'CHANNELS'),
        [tok0,R0] = strtok(R);
        num_ch = str2double(tok0);
        count = count+1;
        count1 = 0;
        
        for n = ch_id:ch_id+num_ch-1
            [tok0,R0] = strtok(R0);
            %if tok0=='Xrotation'|tok0=='Yrotation'|tok0=='Zrotation'
            if strcmp(tok0,'Xrotation')||strcmp(tok0,'Yrotation')||strcmp(tok0,'Zrotation')
                
                count1=count1+1;
            end;
            
            if strcmp(tok0,'Xrotation')  %1
                conds(count,count1)=1;
            elseif strcmp(tok0,'Yrotation')  %2
                conds(count,count1)=2;
            elseif strcmp(tok0,'Zrotation')   %3
                conds(count,count1)=3;
            end;
            %% get name without tok0
            
            hd.channel{n} = [hir_name,tok0];
        end;
        ch_id = ch_id+num_ch;
    end;
    
    hd.str = [hd.str,'\n',l];
    if strncmp(l,'MOTION',6), break; end;
end;
hd.motl1 = fgetl(fid);
hd.motl2 = fgetl(fid);

%tic
motion = [];
prev_a = []; offset = 0;
while ~feof(fid),
    l = fgetl(fid);
    a = sscanf(l,'%f')+offset;
    
    %% hj delete this part.
    if ~isempty(prev_a),
        offset = offset + 360*((a-prev_a) < -180) - 360*((a-prev_a) > 180);
        %if(sum((a-prev_a)<-180)), dbstack; keyboard; end;
        a = a+offset;
    end;
    prev_a = a;
    motion = [motion;a'];
end;
%toc

%% alternative data read
% alldat=dlmread(fn,' ',[motioninfostart-1 0 numframes+motioninfostart-2 totpoints]);
% alldatdiff = alldat(2:end,:)-alldat(1:end-1,:);
% cdiff=cumsum(360*((alldatdiff) < -180) - 360*((alldatdiff) > 180));
% cdiffw=[zeros(1,totpoints+1) ; cdiff];
% motion=alldat+cdiffw;
%
fclose(fid);

% output
for i = 2:jointsnum
    for j=1:3
        num = i*3+j;
        condsout(num) = conds(i,j);
        offsetout(num) = offsetval(i,j);
    end;
end;

% postprocessing
for i=1:jointsnum
    for j=1:jointsnum
        if hirparid(i,j)==0
            hirparid(i,j)=1;
        end;
    end;
end;
% for i=1:jointsnum
%     for j=1:jointsnum
%         if hirparid(i,j)==-1
%             fprintf(fp,'%s ', '-1');
%         else
%             fprintf(fp,'%s ', hirparname{hirparid(i,j)});
%         end;
%     end;
%     fprintf(fp,'\n');
% end;

% fix the redundant names in hd.ori_name
for k = 2:length(hd.ori_name)
    if strcmp(hd.ori_name{k},hd.ori_name{k-1})
        hd.ori_name{k} = [hd.ori_name{k},'End'];
    end
end

% fprintf(fp,'** offsetval: **\n');
% for jointi = 1:jointsnum
%     for i=1:3
%         fprintf(fp,'%f ',offsetval(jointi,i));
%     end;
%     fprintf(fp,'\n');
% end;

%%Save Channels
% fid = fopen('channel.names','w');
%
%   for n = 1:length(hd.channel),
%     fprintf(fid,'%3d: %s  %d %f\n',n,hd.channel{n},condsout(n),offsetout(n));
%   end;
% fclose(fid);

%offset  %% get rid of 5 end points
%% calculate the 3D coordinates of each joint  (21 joint, the first joint has x,y,z poition and xyz rot., the rest only have xyz rot.
framenum = size(motion,1);
%coordnum = size(motion,2);
jointspos = zeros(framenum,jointsnum,3);
%Mtemp = zeros(jointsnum,3);
tempq = zeros(4,4,jointsnum); %% matrix for rotation & translation
temptr= zeros(4,4,jointsnum); %% matrix for rotation & translation
tempqtemp = zeros(4,4);  % rotation
%temptrtemp = zeros(4,4);  % translation

temprot = zeros(1,3);
%parttype = [0 0 0 0 0 0 0 1 1 1 1 2 2 2 2 1 1 1 2 2 2];  %: center points; 1: left parts; 2:right parts

for framei = 1:framenum
    %fprintf(fp,'\n ');
    tempq= tempq.*0;
    tempqtemp = tempqtemp.*0;
    % new version, transformation matrix; following .bvh sequence
    
    for jointi = 1:jointsnum
        flagpar = jointi;%hirparid(jointi,flag);  %
        temprot = temprot.*0;
        for i=1:3
            temprot(i) = motion(framei,i+flagpar*3)*pi/180;
            %fprintf(fp,'%10.3f ',temprot(i)*180/pi);
        end;
        
        tempqtemp= eye(4);
        %offset
        for i=1:3
            tempqtemp(i,4) = offsetval(jointi,i);
        end;
        temptr(:,:,jointi) = tempqtemp;
        
        %% rotation
        tempqtemp= eye(4);
        
        for i =3:-1:1
            if conds(flagpar,i)==1 %1  %x rot
                tempqtemp=rotx(temprot(i))*tempqtemp;  %-
            elseif conds(flagpar,i)==2  %y rot
                tempqtemp=roty(temprot(i))*tempqtemp;  %-
            elseif conds(flagpar,i)==3  %z rot
                tempqtemp=rotz(temprot(i))*tempqtemp;%% devided by 2  Note: not know why? but the display is much better
            end;
        end;
        tempq(:,:,jointi) = tempqtemp;
    end;
    % calculate the global coordinates
    for jointi = 1:jointsnum
        flag = find(hirparid(jointi,:)==jointi);  % parent flag
        %flagpar = flag;
        v = [0 0 0 1]';
        
        %% add offset to get global coordinates
        for j=flag:-1:1
            flagpar=hirparid(jointi,j);
            temptrtemp=temptr(:,:,flagpar);
            tempqtemp=tempq(:,:,flagpar);
            
            v = temptrtemp*tempqtemp*v;
        end;
        
        % modified by HL
        % no global motion, similar as walking on a treadmill
        %             jointspos(framei,jointi,:)=v(1:3)'  ;
        %             % include global motion as in the raw data
        jointspos(framei,jointi,:)=v(1:3)'+[motion(framei,1) motion(framei,2) motion(framei,3)]  ;
        % include global motion as in the raw data, but start from (0,0,0) locations
        %jointspos(framei,jointi,:)=v(1:3)'+[motion(framei,1)-motion(1,1) motion(framei,2)-motion(1,2) motion(framei,3)-motion(1,3)]  ;
        
        % include global motion as in the raw data, but put frameN start at (0,0,0)
        %frameN = 140;
        %jointspos(framei,jointi,:)=v(1:3)'+[motion(framei,1)-motion(frameN,1) motion(framei,2)-motion(frameN,2) motion(framei,3)-motion(frameN,3)]  ;
    end;
end;



%fprintf(fp,'** coordinates in the first frame : **\n');
%for jointi = 1:jointsnum
%    for i=1:3
%        fprintf(fp,'%f ',jointspos(1,jointi,i));
%    end;
%    fprintf(fp,'\n');
%end;
%fclose(fp);