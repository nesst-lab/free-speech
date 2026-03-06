function [h] = draw_emaCtrlText(h_fig,x,y,txt,varargin)

get_figinds_audapter;

% make controller window current and draw the text 
figure(h_fig(dup));
h = text(x,y,txt,varargin{:});
