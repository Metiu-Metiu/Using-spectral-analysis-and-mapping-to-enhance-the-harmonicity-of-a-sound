%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Signal Analysis with MATLAB Implementation      %
%                                                      %
% Author: Matteo Fabbri        12/20/16 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Xamp, Xph, f] = sgn_analysis(x, samplingFrequency)
% function: [Xamp, Xph, f] = sgn_analysis(x, samplingFrequency)

% INPUTS
% x - signal in the time domain
% samplingFrequency - sampling frequency, Hz
% OUTPUTS
% Xamp - amplitude spectrum, dB
% Xph - phase spectrum, rad
% f - frequency vector, Hz

% length of the signal (number of samples)
N = length(x);
% FFT
fftx = fft(x);
% calculate the number of unique fft points (only the ones related to positive frequencies)
NumUniquePts = ceil((N+1)/2);
% fft is symmetric, throw away the second half, which is relative to
% negative frequencies (Audio Programming Book -> p. 526)
fftx = fftx(:, 1:NumUniquePts);
% amplitude spectrum
Xamp = abs(fftx)/N;
% correction of the amplitude spectrum
if rem(N, 2)                            % odd N, hence the spectrum excludes the Nyquist point
    Xamp(2:end) = Xamp(2:end)*2;
else                                    % even N, hence the spectrum includes the Nyquist point
    Xamp(2:end-1) = Xamp(2:end-1)*2;
end
% phase spectrum
Xph = angle(fftx);
% frequency vector
% the fundamental frequency of analysis of a DFT, in Hz, depends on the
% sample rate, and it is samplingFrequency/N, where N is the number of
% samples in the input sound. All the other frequencies are its integer
% multiples. (Audio Programming Book -> p. 526)
f = (0:NumUniquePts-1)*samplingFrequency/N;
% represent the output as row-vectors
% Xamp = transpose(Xamp);
% Xph  = transpose(Xph);
% f    = transpose(f);
end