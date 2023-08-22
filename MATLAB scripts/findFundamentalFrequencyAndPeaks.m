function [number_of_peaks, peak_values, peak_locations, peak_closest_harmonics, minima_locations] = findFundamentalFrequencyAndPeaks(current_amplitude_spectrum, target_number_of_peaks)

% --- Spectrum smoothing --------------------------------------------------
% SMOOTH THE SPECTRUM until only the desired number of peaks
% (number_of_peaks) is present in the spectrum

% REVISE: consider replacing with single or fewer smooths to significantly
% speed up program (could revoke need for target peaks user input)

% initial smooth
number_of_peaks = numel(findpeaks(current_amplitude_spectrum));
smoothed_amplitude_spectrum = current_amplitude_spectrum;

window_size = floor(length(current_amplitude_spectrum) / 64);

if mod(window_size, 2) == 0
    window_size = window_size - 1;
end

% continue smoothing until target number of peaks is met
while number_of_peaks > target_number_of_peaks
    smoothed_amplitude_spectrum = sgolayfilt(smoothed_amplitude_spectrum, 1, window_size);
    number_of_peaks = numel(findpeaks(smoothed_amplitude_spectrum));
end

% --- Find peaks ----------------------------------------------------------
% extract number of peaks and their locations in the current frame
[peak_values, peak_locations] = findpeaks(smoothed_amplitude_spectrum(:));

% --- Fundamental frequency extraction ------------------------------------
% framed_true_fundamental is an array which contains the fundamental
% frequency (AS PEAK WITH THE LOWEST FREQUENCY, EXTRACTED FROM THE SMOOTHED
% SPECTRUM)

if number_of_peaks > 0  % if at least 1 peak is present
    fundamental_value = peak_values(1); % find value of first peak
    fundamental_location = peak_locations(1);   % find location of first peak
    
    % remove fundamental value and location from respective peak vectors
    peak_values(1) = [];
    peak_locations(1) = [];
    number_of_peaks = number_of_peaks - 1;
end

% --- Find minima ---------------------------------------------------------
[minima_values, minima_locations] = findpeaks(-smoothed_amplitude_spectrum(:));
minima_values = abs(minima_values);
number_of_minima = numel(minima_locations);

% remove first minima if it exists before the fundamental index
while minima_locations(1) < fundamental_location
    minima_values(1) = [];
    minima_locations(1) = [];
    number_of_minima = number_of_minima - 1;
end

% append if minima and peak number are equal - each peak should have two
% defining points minima
if number_of_minima == number_of_peaks
    % find lowest index from the current last minima to end;
    current_end_minima_location = minima_locations(end);
    
    [new_end_minima_value, new_end_minima_location] = min(current_amplitude_spectrum(current_end_minima_location + 1:end));
    new_end_minima_location = new_end_minima_location + current_end_minima_location;
    
    minima_values = [minima_values; new_end_minima_value];
    minima_locations = [minima_locations; new_end_minima_location];
    number_of_minima = number_of_minima + 1;
end

if number_of_minima ~= number_of_peaks + 1
    fprintf("Mismatch: minima = %d, peaks = %d\n", number_of_minima, number_of_peaks);
end


% 
% if number_of_minima == number_of_peaks + 2
%     figure;
%     plot(peak_locations,1, 'x','color','r')
%     hold on
%     plot(minima_locations,1, 'o','color','b')
%     hold off
% end

% --- Harmonic template calculation ---------------------------------------
% exclude fundamental frequency, hence - 1
number_of_template_harmonics = floor(numel(current_amplitude_spectrum) / fundamental_location) - 1;
harmonic_template = zeros(number_of_template_harmonics, 1);

for i = 1:number_of_template_harmonics
    harmonic_template(i) = fundamental_location * (i + 1);
end

% --- Finding closest harmonic for each peak ------------------------------
peak_closest_harmonics = zeros(number_of_peaks, 1);

for i = 1:number_of_peaks
    % set closest harmonic of each peak initially as first harmonic
    peak_closest_harmonics(i) = harmonic_template(1);
    % calculate absolute distance between each peak and initial harmonic
    distance = abs(peak_locations(i) - harmonic_template(1));
    
    % (start at 2 because harmonic_template(1) has been evaluated
    % previously)
    for j = 2:number_of_template_harmonics
        % if the distance between the next harmonic template value is less
        % than the previous, make that the new distance value
        if abs(peak_locations(i) - harmonic_template(j)) < distance
            % overwrite distance value to evalutate next harmonic against
            distance = abs(peak_locations(i) - harmonic_template(j));
            % set as new closest harmonic
            peak_closest_harmonics(i) = harmonic_template(j);
            
            % if distance is greater, break as harmonic template is in size order
            % and will only get larger; closest harmonic has been found
        else
            break
        end
    end
    
    % set peak closest harmonic to 0 if the closest harmonic falls outside
    % the minima
    %     if harmonic_template(j) < minima_locations(i) ||
    %     harmonic_template(j) > minima_locations(i + 1)
    %         peak_closest_harmonics(i) = 0;
    %     end
end

% figure('units','normalized','outerposition',[0 0 1 1]);
% 
% plot(smoothed_amplitude_spectrum); 
% hold on; 
% a = plot(current_amplitude_spectrum); 
% a.Color(4) = 0.25;
% plot(fundamental_location, fundamental_value, 'x', 'Color', 'r');
% plot(peak_locations, peak_values, 'x', 'Color', 'g');
% plot(minima_locations, minima_values, 'x', 'Color', 'b');
% plot(peak_closest_harmonics, peak_values, 'x', 'Color', 'm'); 
% axis xy;
% axis tight; 
% xlabel('Frequency Bin'); 
% ylabel('Amplitude'); 
% title('Smoothed Amplitude Spectrum');

end