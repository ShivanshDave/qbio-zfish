function [x_axis_handle, y_axis_handle] = TufteStyleC(font_size, figure_handle)
% TufteStyle  Changes axes into a clean style described by Edward Tufte
%   [x_axis_handle, y_axis_handle] =  TufteStyle(axes_handle_original)
%   takes in a axes handle, removes box, background and adds new x and y
%   axes with an offset of 0.01 times the figure size.
%
%   Example:
%     plot(rand(10,1));
%     original_axes_handle = gca;
%     [x_axis_handle, y_axis_handle] = TufteStyle(original_axes_handle);
%     xlabel(x_axis_handle, 'custom x label');
%     ylabel(y_axis_handle, 'custom y label');
%

%   Author: Umesh Mohan
%   email: umesh at heterorrhina dot in
%   Date: 2016/07/21 20:00:00
%   Last Update: 2016/08/22
%   Revision: 0.1.3

%   Revision history:
%   0.1.1: First complete working version
%   0.1.3: Added options to preserve original axis labels and tick labels (Contributed by Dinesh (https://github.com/AbstractGeek))

if ~exist('figure_handle','var')
    figure_handle = gcf;
end
if ~exist('font_size','var')
    font_size = 8;
end

current_axes = figure_handle.Children;

for i=1:length(current_axes)
    axes_handle_original = current_axes(i);
    set(axes_handle_original, 'ActivePositionProperty', 'Position');   % Prevents rescaling
    set(axes_handle_original, 'Units', 'Normalized'); 
end


for i=1:length(current_axes)
    
    axes_handle_original = current_axes(i);
    original_axes_position = get(axes_handle_original,'Position');
    
    % Copy and set x_axis
    x_axis_handle = copyobj(axes_handle_original,figure_handle);
    delete(get(x_axis_handle,'Children')); % To prevent data duplication
    delete(get(x_axis_handle,'Title')); % To prevent data duplication
    x_axis_position = original_axes_position - [0 0.02 0 0];
    set(x_axis_handle,...
        'Position', x_axis_position,...
        'Color', 'none',...
        'FontName'   , 'Arial', ...
        'FontSize'   , font_size  , ...
        'Box'         , 'off'     , ...
        'YTick', [], 'YTickLabel', {},...
        'Tickdir', 'out',...
        'Ticklength', [0.025 0.01],...
        'YColor','none');    
    
    % Copy and set y_axis. Adjust position based on yaxis location
    y_axis_handle = copyobj(axes_handle_original,figure_handle);
    delete(get(y_axis_handle,'Children'));   % To prevent data duplication
    delete(get(y_axis_handle,'Title')); % To prevent data duplication
    if strcmp(axes_handle_original.YAxisLocation,'right')
        y_axis_position = original_axes_position + [0.015 0 0 0];
    else
        y_axis_position = original_axes_position - [0.015 0 0 0];
    end    
    set(y_axis_handle,...
        'Position', y_axis_position,...
        'Color', 'none',...
        'Color', 'none',...
        'FontName'   , 'Arial', ...
        'FontSize'   , font_size  , ...
        'Box'         , 'off'     , ...
        'XTick', [], 'XTickLabel', {},...
        'tickdir', 'out',...
        'Ticklength', [0.025 0.01],...
        'XColor','none');

    % Link axes
    linkaxes([axes_handle_original x_axis_handle y_axis_handle], 'xy');
    set(axes_handle_original,'Visible','off');
    
    % Handle title
    plt_title = get(axes_handle_original, 'Title');
    set(plt_title,...
        'Visible', 'on',...
        'FontName'   , 'Arial', ...
        'FontSize'   , font_size);
    
    % Fix x label position
    x_axis_label = get(x_axis_handle, 'XLabel');
    set(x_axis_label, 'Units', 'Normalized');
    set(x_axis_label, 'Position',...
        get(x_axis_label, 'Position') - [0 0.02 0]);
    
    % Fix y label position
    y_axis_label = get(y_axis_handle, 'YLabel');
    set(y_axis_label, 'Units', 'Normalized');
    ylabelPosition = get(y_axis_label, 'Position');
    ylabelExtent = get(y_axis_label, 'Extent');
    if strcmp(axes_handle_original.YAxisLocation,'right')        
        set(y_axis_label, 'Position',...
            [ylabelPosition(1)+ylabelExtent(3)/3 0.5 ylabelPosition(3)]);
% %     else
% % %         set(y_axis_label, 'Position',...
% % %             get(y_axis_label, 'Position') - [0.01 0 0]);
% %         set(y_axis_label, 'Position',...
% %             [ylabelPosition(1)-ylabelExtent(3)/4 0.5 ylabelPosition(3)]);
    end
    

   
end

end