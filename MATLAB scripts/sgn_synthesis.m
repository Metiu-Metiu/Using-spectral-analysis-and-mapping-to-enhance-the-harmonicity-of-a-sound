%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Signal Synthesis with MATLAB Implementation      %
%                                                      %
% Author: Matteo Fabbri        12/20/16 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [x, t] = sgn_synthesis(Xamp, Xph, samplingFrequency)
% function: [x, t] = sgn_synthesis(Xamp, Xph, samplingFrequency)

% INPUTS
% Xamp - amplitude spectrum, dB
% Xph - phase spectrum, rad
% samplingFrequency - sampling frequency, Hz

% OUTPUTS
% x - signal in the time domain
% t - time vector, s
% represent the input as row-vectors
% Xamp = Xamp(:)';
% Xph = Xph(:)';
% calculate the last points of the spectrum
Xend(:, :) = Xamp(:, end).*exp(1i*Xph(:, end));
% reconstruct the whole spectrum
if abs(imag(Xend)) <= eps               % the spectrum includes the Nyquist point
    
    Xamp(2:end-1) = Xamp(2:end-1)/2;    % correction of the amplitude spectrum
    X = Xamp.*exp(1i*Xph);              % represent the spectrum in a polar form
    X = [X conj(X(:, end-1:-1:2))];        % spectrum reconstruction
    
else                                    % the spectrum excludes the Nyquist point
    
    Xamp(2:end) = Xamp(2:end)/2;        % correction of the amplitude spectrum
    X = Xamp.*exp(1i*Xph);              % represent the spectrum in a polar form
    X = [X conj(X(end:-1:2))];          % spectrum reconstruction
    
end
% IFFT
x = real(ifft(X*length(X)));
% time vector
t = (0:length(x)-1)/samplingFrequency;
end