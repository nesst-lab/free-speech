function [h] = draw_emaPpText(h_fig,x,y,txt,varargin)

get_figinds_audapter;

% make stimulus window current and draw the text 
figure(h_fig(stim));
h = text(x,y,txt,varargin{:});
