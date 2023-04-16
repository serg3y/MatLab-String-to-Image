function [I,A,H,W] = str2imq(T,varargin)
%Quickly convert text to image by making and using an image dictionary.
% str2imq([])      -clear the cache
% str2imq(L,P)       -cache text & properties
% D = str2imq()        -get dictionary
% I = str2imq(T,P)       -convert text to image using cache
% [I,A] = str2im(__)       -return alpha (see str2im)
% [I,A,H,W] = str2im(__)     -return height & width (see str2im)
%L: List of letters (char) or list string fragments (cellstr).
%P: Text padding & text properties (see str2im).
%D: Image dictionary of letters/string fragments (struct).
%T: Can also pointers at dictionary entries (integer vector).
%
%Remarks:
%-Dictionary images must have same height to concatenate horizontally.
%-Dictionary and text properties are cached as persistent variables.
%-Missing dictionary element will get appended on the fly (SLOW).
%-Text properties must be exactly same: property order, spelling, etc.
%
%Example:
% [I,A]=str2imq('Hello!','FontSize',80);   %fast repeat calls
% imagesc(I,'AlphaData',A), axis off equal
%
%Example: string fragments
% imagesc(str2imq({'\pi' '\int' 'xyz'},'Interpreter','tex')), axis equal tight 
%
%Example: clock
% str2imq('0123456789:.',[0 0 0 0],'FontName','FixedWidth')         %init
% while 1,imagesc(str2imq(datestr(now,'HH:MM:SS.FFF'))),drawnow,end %play
%
%Example: create a dictionary with mixed colours, save it to file
% str2imq([]) %clear dictionary
% str2imq('str ',[0 0 -5 -1],'Color','b','Background','y','FontName','FixedWidth','FontWeight','bold') %add blue text to dictionary 
% str2imq('2imq',[0 0 -5 -1],'Color','r','Background','y','FontName','FixedWidth','FontWeight','bold') %add red text to dictionary 
% D = str2imq                %get dictionary
% save('dictionary.mat','D') %save it to file
%
%Example: load a dictionary from file and use it
% load('dictionary.mat','D')             %load dictionary
% str2imq(D)                             %set dictionary
% imshow(str2imq([3 4 2 1;5 6 7 8]))
%
%See also: str2im listfonts uisetfont

%init
persistent D P %cache dictionary & text properties

%assign
if nargin>=2
    P = varargin; %change text properties
end
if nargin>=1 && (isnumeric(T) && isempty(T) || isstruct(T))
    D = T; return %change dictionary & exit
end
if nargin==0
    I = D; return %return dictionary & text properties and exit
end

%check
if isnumeric(D), D = struct('str',{}); end %init dictionary
if isnumeric(P), P = cell(0,0); end %init text properties
if ischar(T),    T = num2cell(T); end %split text into characters

if ~isnumeric(T)
    %dictionary elements with required text properties (same spelling & order!)
    i = arrayfun(@(x)isequal(P,x.props),D);
    
    %append missing elements to dictionary (if any)
    U = unique(T(:)'); %unique text elements
    for k = find(~ismember(U,{D(i).str})) %step through missing elements
        D(end+1).str = U{k}; %#ok<AGROW> append element to dictionary
        [D(end).image,D(end).alpha,D(end).height,D(end).width] = str2im(U{k},P{:}); %generate image for the element
        D(end).props = P; %save text properties
    end
    i = find([i true(1,numel(D)-numel(i))]); %include appended elements
end

%make image
if nargout>0
    if ~isnumeric(T)
        [~,j] = ismember(T,{D(i).str}); %find element in dictionary
        j = i(j);
    else
        j = T;
    end
    I = cell2mat(reshape({D(j).image},size(T))); %make text image
end
if nargout>1
    A = cell2mat(reshape({D(j).alpha},size(T))); %make alpha image
end
if nargout>2
    [H,W,~] = size(I); %image height and width
end