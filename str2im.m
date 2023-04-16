function [I,A,H,W] = str2im(str,pad,varargin)
%Convert text string to RGB image.
% str2im         %display example text
% str2im(str)      %text as char array or cellstr
% str2im(str,pad)    %margin: [N] or [H V] or [L R T B] as pixels or nan
% str2im(__,props)     %text property as value pairs, doc text
% I = str2im(__)         %return RGB image data as uint8
% [I,A] = str2im(__)       %return background alpha channel as uint8
% [I,A,H,W] = str2im(__)     %return image height and width
% 
%Remarks:
%-If a margin is nan then the background is cropped up to the text.
%-Slow because nothing is cached, a figure is generated for each call and
% print is used to generate the image (not getframe).
%-Maximum image size is limited by screen resolution.
% 
%Useful text properties:
% BackgroundColor     - {w} y m c r g b k [r g b]
% Color               - {k} y m c r g b w [r g b]
% FontSize            - {16} positive number
% FontUnits           - {points} pixels normalized inches centimeters
% FontWeight          - {normal} bold light demi
% FontAngle           - {normal} italic oblique
% FontName            - Helvetica FixedWidth (see listfonts)
% Interpreter         - {none} tex latex
% HorizontalAlignment - {left} center right
% 
%Example:
% clf,I=str2im({'str' '2im'},[10 8 -6 -5],'Color','b','Background','y','FontName','FixedWidth','FontWeight','bold')
% clf,str2im('\phi_k^\pi',nan,'FontSize',200,'interpreter','tex')
% clf,str2im('$$\int_0^2x^2\sin(x)dx$$',nan,'interpreter','latex')
% 
%Example: burn text into image
% [I,A,H,W]=str2im(datestr(now),[0 0 -6 -3],'FontName','FixedWidth','Color','y','Background','k');
% im=imread('peppers.png');x=size(im,2)-W;y=size(im,1)-H;im(y+(1:H),x+(1:W),:)=im(y+(1:H),x+(1:W),:)*0.6+I;imshow(im)
% 
%Example: find fixed-width fonts
% f=listfonts,f(cellfun(@(f)numel(str2im('A','fontn',f))==numel(str2im('.','fontn',f)),f))
%     {'Consolas'              }
%     {'Courier'               }
%     {'Courier New'           }
%     {'DialogInput'           }
%     {'Lucida Console'        }
%     {'Lucida Sans Typewriter'}
%     {'MingLiU-ExtB'          }
%     {'MingLiU_HKSCS-ExtB'    }
%     {'Monospaced'            }
%     {'MS Gothic'             }
%     {'NSimSun'               }
%     {'SimSun'                }
%     {'SimSun-ExtB'           }
% 
%Example: show font browser gui
% figure(6),clf,set(gcf,'tool','fig')
% s = uicontrol('Style','edit'     ,'Position',[  5 5 150 50],'String',char(reshape(32:127,[],6)'),'max',1000);
% n = uicontrol('Style','popupmenu','Position',[155 5 150 20],'String',['FixedWidth';sort(listfonts)]);
% w = uicontrol('Style','popupmenu','Position',[305 5  60 20],'String',{'normal' 'bold' 'light' 'demi'});
% a = uicontrol('Style','popupmenu','Position',[365 5  60 20],'String',{'normal' 'italic' 'oblique'});
% c = uicontrol('Style','popupmenu','Position',[425 5  40 20],'String',{'k' 'y' 'm' 'c' 'r' 'g' 'b' 'w'});
% b = uicontrol('Style','popupmenu','Position',[465 5  40 20],'String',{'w' 'y' 'm' 'c' 'r' 'g' 'b' 'k'});
% z = uicontrol('Style','popupmenu','Position',[505 5  40 20],'String',cellstr(num2str((1:200)')),'value',20);
% F = @(v,i)v{i}; F = @(h)F(get(h,'String'),get(h,'Value')); %function to get popup str
% set([n w a c b z],'CallBack',@(x,y)str2im(get(s,'String'),'FontName',F(n),'FontWeight',F(w),'FontAngle',F(a),'Color',F(c),'BackgroundColor',F(b),'FontSize',str2double(F(z))));
% 
%System defaults:
% get(0,{'defaultTextFontName' 'FixedWidthFontName'})
%
%See also: text, listfonts, uisetfont, rgb2gray, im2double

%Issues:
% There appears to be a bug in getframe in R2022a. The returned frame size
% is often not the requesed size.
% clc,close all
% figure(1),set(1,'Position',[0 108.2     560 420  ]),size(frame2im(getframe(1,[0 0 100 200])))
% figure(2),set(2,'Position',[0 108.20001 560 420  ]),size(frame2im(getframe(2,[0 0 100 200])))

%defaults
if nargin<1 || isempty(str), str = 'Abc'; end
if nargin<2 || isempty(pad), pad = 0; end %pad amount
slow_but_reliable = true;
 
%checks
if ischar(pad), varargin = [pad varargin]; pad = 0; end %can skip pad argument
if numel(pad)==1, pad = pad*[1 1 1 1]; end %same pad for all sides
if numel(pad)==2, pad = [pad;pad]; end %same pad for L&R and T&B
crop = ~isfinite(pad(:)); %auto crop
pad(crop) = 0;
if isnumeric(str), str = char(str); end
 
fig = figure;clf
set(fig,'Units','pixels','Color',[1 1 1],'MenuBar','none') %,'WindowStyle','modal'); %init figure, keep it on top 
axe = axes('Parent',fig,'Position',[0 0 1 1],'Visible','off'); %axis to span entire figure
try %text properties and pad size might be invalid
    txt = text('Parent',axe,'Interpreter','none','FontSize',16,'String',str,varargin{:},'Units','pixels'); %display text
    drawnow %has to be done betwbefore get extents, for some text sizes
    ext = ceil(get(txt,'Extent')); %get text bounding box location
    pos = get(txt,'Position'); %get c current possition
    set(txt,'Position',[1+pos(1)-ext(1)+pad(1) 1+pos(2)-ext(2)+pad(4)]); %move text to bottom left corner, +1pix !???
    W = ceil(ext(3))+pad(1)+pad(2)+1; %text width
    H = ceil(ext(4))+pad(3)+pad(4)+1; %text height
    set(fig,'Position',[0 0 W H]) %possition figure on screen, text must fit in figure & figure must fit in screen
    drawnow
    pos = get(fig,'Position');
    if any([W H]-pos(3:4)>1)
        warning('Image is %.1f%% too large to fit on screen.',(max([W H]./pos(3:4))-1)*100)
    end
catch ex
    close(fig) %close windows
    rethrow(ex) %display error
end
if any(pad(:)>0) && ~isequal(get(txt,'BackgroundColor'),'none') %figure is visible and background color is set
    set(fig,'Color',get(txt,'BackgroundColor')) %make figure same color as background
end
if slow_but_reliable
    set(fig,'InvertHardcopy','off')
    I = print(fig,'-RGBImage','-r96');
    I = I(:,1:min(W,end),:); %for small images print will capture too much
else
    I = frame2im(getframe(fig,[0 0 W H])); %#ok<UNRCH> %capture rgb image [left bottom width height]
end

if nargout>1 %generate alpha if needed
    set(txt,'Color','k','BackgroundColor','w')
    set(fig,'Color','w') %change to black on white
    if slow_but_reliable
        set(fig,'InvertHardcopy','off')
        A = print(fig,'-RGBImage','-r96');
        A = A(:,1:W,:);
    else
        A = frame2im(getframe(fig,[0 0 W H])); %#ok<UNRCH> %capture rgb image [left bottom width height]
    end
    A = rgb2gray(255-A); %background alpha channel
end
[H,W,~] = size(I); %get frame is bugged, does not caputre requested size!
if size(I,2)~=W || size(I,1)~=H
    warning('str2im:TextLargerThenScreen','Text image was cropped because it did not fit on screen.')
end
if any(crop) %crop image
    [H,W,~] = size(I);
    t = any(any(abs(diff(I,[],1)),3),1); %find solid color rows
    if crop(1) && any(t), L = max(find(diff([0 t]),1,'first')-1,1); else, L = 1; end
    if crop(2) && any(t), R = min(find(diff([t 0]),1,'last' )+1,W); else, R = W; end
    t = any(any(abs(diff(I,[],2)),3),2); %find solid color columns
    if crop(3) && any(t), T = max(find(diff([0;t]),1,'first')-1,1); else, T = 1; end
    if crop(4) && any(t), B = min(find(diff([t;0]),1,'last' )+1,H); else, B = H; end
    I = I(T:B,L:R,:); %crop image
    if nargout>1
        A = A(T:B,L:R,:); %crop alpha also
    end
    [H,W,~] = size(I);
end
close(fig) %close figure
if ~nargout %plot results instead of returning image
    imagesc(I)
    axis equal tight
    clear I
end