clc, clear, close all

% *** DEBUG ***************************************************************
% first processed frame
frame = 1;

% first processed peak
peak = 1;

% disable or enable plots
PLOT_WINDOWS = false;
PLOT_SPECTRA = true;

% disable or enable main spectral analysis and mapping process
PROCESS = false;
% *************************************************************************

% === USER INPUTS =========================================================
file = 'MP_Perc_16.wav';

% controls
frame_length_ms = 100;
frame_overlap_percentage = 80;
target_number_of_peaks = 16;
multiplier = 5;
divergence_index = 1;

user_inputs = {
    'frame_length_ms',...
    'frame_overlap_percentage',....
    'target_number_of_peaks',...
    'multiplier',...
    'divergence_index';
    
    frame_length_ms,...
    frame_overlap_percentage,....
    target_number_of_peaks,...
    multiplier,...
    divergence_index
    };

% check inputs for errors
validateUserInputs(user_inputs);
% =========================================================================

% initialise program timer
total_elapsed_time = 0;

% --- Data extraction -----------------------------------------------------
[input_samples, sample_rate] = audioread(file);
input_samples = input_samples';

[number_of_channels, number_of_samples] = size(input_samples);
duration_ms = floor((number_of_samples / sample_rate) * 1000);

% limit maximum frame length to length of file
if frame_length_ms > duration_ms
    warning("Frame length limited to the file duration: %.1f ms -> %.1f ms", frame_length_ms, duration_ms);
    frame_length_ms = duration_ms;
end

% pad the array of input samples with 0s at the end, so that the few very
% lasts frames, whose final parts fall beyond the input waveform's last
% sample, have a value to be accessed (rather than a null, non-existing
% value) when we build framed_samples_matrix (see slightly below)
input_samples(:, (number_of_samples + 1):(number_of_samples * 2)) = 0;
output_samples = zeros(size(input_samples));

% --- Framing -------------------------------------------------------------
% calculate frame length (samples) from frame length (ms)
frame_length_samples = floor(sample_rate / 1000 * frame_length_ms);

% calculate frame overlap (samples) from frame overlap (percentage)
frame_overlap_samples = floor(frame_length_samples / 100 * frame_overlap_percentage);

% frame step is the time between the start time of each frame calculate
% frame step (samples)
frame_step_samples = frame_length_samples - frame_overlap_samples;
number_of_frames = floor(number_of_samples / frame_step_samples);

% --- Window pre-processing -----------------------------------------------
% build windows for application in main toop
% hamming
hamming_window = hamming(frame_length_samples, 'periodic')' + eps;
hamming_window_start = hamming_window;
hamming_window_start(1:frame_step_samples) = 1;
hamming_window_end = hamming_window;
hamming_window_end(end - (frame_step_samples -1):end) = 1;

% hanning
half_hanning_window = ones(1, frame_length_samples);

if frame_overlap_percentage > 50
    half_hanning_window = rescale(hann(frame_length_samples), 0, 1 - (1 / 50 * (frame_overlap_percentage - 50)));
    half_hanning_window = half_hanning_window';
    
else
    edges = hann(2 * frame_overlap_samples);
    half_hanning_window(1:frame_overlap_samples) = edges(1:frame_overlap_samples);
    half_hanning_window(end - (frame_overlap_samples - 1):end) = edges(end - (frame_overlap_samples - 1):end);
end

% synthesis
synthesis_window = half_hanning_window ./ hamming_window;

if PLOT_WINDOWS
    figure;
    hold on
    title(sprintf("System Windows, %d%% overlap", frame_overlap_percentage));
    
    plot(hamming_window, 'Color', 'r');
    plot(half_hanning_window, 'Color', 'm');
    plot(synthesis_window, 'Color', 'b');
    
    legend("Hamming", "Half-hanning", "Synthesis");
end

% vector initialising
frame_samples = zeros(number_of_channels, frame_length_samples);
amplitude_spectrum = zeros(number_of_channels, floor(frame_length_samples / 2) + 1);
phase_spectrum = zeros(number_of_channels, floor(frame_length_samples / 2) + 1);
spectral_mappings_per_frame = zeros(1, number_of_frames);

% work with only the left channel if audio file is stereo REFACTOR: this
% should be run for both channels in final build
for channel = 1:number_of_channels
    samples_in_channel = input_samples(channel, :);
    
    % === MAIN LOOP =======================================================
    for current_frame = frame:number_of_frames
        % start timer
        tic;
        
        % populate sample value and index matrices
        frame_start = frame_step_samples * (current_frame - 1) + 1;
        frame_end = frame_step_samples * (current_frame - 1) + frame_length_samples;
        frame_samples = samples_in_channel(frame_start:frame_end);
        
        % --- Windowing ---------------------------------------------------      
        frame_samples = frame_samples .* hamming_window;
        
        % --- Time -> frequency domain ------------------------------------
        [amplitude_spectrum, phase_spectrum, frequency_bins] = sgn_analysis(...
            frame_samples,...
            sample_rate);
        
        % get bin resolution
        bin_resolution = frequency_bins(2);
        
        % if there are peaks present, perform analysis spectral mapping
        if PROCESS
            if PLOT_SPECTRA
                figure;
                axis tight
                sgtitle({sprintf("Channel %d of %d, frame %d of %d",...
                    channel, number_of_channels, current_frame, number_of_frames);...
                    
                    "";...
                    
                    join([sprintf("Length: %dms (%d samples)   ", frame_length_ms, frame_length_samples),...
                    sprintf("Overlap: %d%% (%d samples)", frame_overlap_percentage, frame_overlap_samples)]);...
                    
                    join([sprintf("Target peaks: %d   ", target_number_of_peaks),...
                    sprintf("Multiplier: x%d   ", multiplier),...
                    sprintf("Divergence: %d bins", divergence_index)])});
                
                subplot(2, 1, 1);
                hold on;
                plot(amplitude_spectrum, 'Color', 'r');
                title("Amplitude spectrum");
                xlabel("Frequency bin")
                ylabel("Amplitude");
                
                subplot(2, 1, 2);
                hold on;
                plot(phase_spectrum, 'Color', 'r');
                title("Phase spectrum");
                xlabel("Frequency bin")
                ylabel("Phase angle (radians)");
            end
            
            if findpeaks(amplitude_spectrum) ~= 0
                % --- Fundamental frequency and peak detection ------------
                [number_of_peaks, peak_values, peak_locations, peak_closest_harmonics, minima_locations] = findFundamentalFrequencyAndPeaks(...
                    amplitude_spectrum,...
                    target_number_of_peaks);
                
                max_in_frame = max(amplitude_spectrum);
                % find largest value over each spectral mapping region
                % max value from first region
                max_in_region = max(amplitude_spectrum(minima_locations(1):minima_locations(2)));
                
                for j = 2:numel(minima_locations) - 1
                    if max_in_region < max(amplitude_spectrum(minima_locations(j):minima_locations(j + 1)))
                        max_in_region = max(amplitude_spectrum(minima_locations(j):minima_locations(j + 1)));
                    end
                end
                
                % --- Spectral mapping ------------------------------------
                for i = peak:number_of_peaks
                    % select peak region by low and high minima
                    current_peak_region = minima_locations(i):minima_locations(i + 1);
                    
                    % define amplitude and phase data regions by peak
                    % region
                    unprocessed_amplitude_region = amplitude_spectrum(current_peak_region);
                    unprocessed_phase_region = phase_spectrum(current_peak_region);
                    
                    % translate the peak and closest harmonic location
                    % relative to the explicit peak region
                    relative_peak_location = peak_locations(i) - (minima_locations(i) - 1);
                    relative_closest_harmonic = peak_closest_harmonics(i) - (minima_locations(i) - 1);
                    
                    % warp the amplitude spectrum to the closest harmonic
                    % index via interpolation; mirror with phase component
                    [processed_amplitude_region, success_flag] = asymWarp(...
                        unprocessed_amplitude_region,...
                        relative_peak_location,...
                        relative_closest_harmonic);
                    
                    [processed_phase_region, ~] = asymWarp(...
                        unprocessed_phase_region,...
                        relative_peak_location,...
                        relative_closest_harmonic);
                    
                    % keep count of the number of spectral mappings
                    % performed in each frame
                    spectral_mappings_per_frame(current_frame) = spectral_mappings_per_frame(current_frame) + success_flag;
                    
                    % rectify negative amplitude components
                    processed_amplitude_region(processed_amplitude_region < 0) = 0;
                    
                    % limit phase components to +- pi, in line with
                    % sgn_analysis and sgn_resynthesis
                    processed_phase_region(processed_phase_region > pi) = pi;
                    processed_phase_region(processed_phase_region < -pi) = -pi;
                    
                    % overwrite the unprocessed peak regions with their
                    % processed counterparts
                    amplitude_spectrum(current_peak_region) = processed_amplitude_region;
                    phase_spectrum(current_peak_region) = processed_phase_region;
                    
                    % enhance the spectrum where spectral mapping is
                    % present
                    amplitude_spectrum(current_peak_region) = enhancePeaks(...
                        amplitude_spectrum(current_peak_region),...
                        max_in_frame,...
                        max_in_region,...
                        multiplier,...
                        divergence_index);
                end
            end
            if PLOT_SPECTRA
                subplot(2, 1, 1);
                plot(amplitude_spectrum, 'Color', 'b');
                legend("Unprocessed", "Processed");
                
                subplot(2, 1, 2);
                plot(phase_spectrum, 'Color','b');
                legend("Unprocessed", "Processed");
            end
        end
        
        % --- Frequency -> time domain ------------------------------------
        frame_samples = sgn_synthesis(...
            amplitude_spectrum,...
            phase_spectrum,...
            sample_rate);
        
        % --- De-windowing ------------------------------------------------
        % application of synthesis window from hanning and hamming
        % windows
        frame_samples = frame_samples .* synthesis_window;
        
        % --- Waveform reconstruction -------------------------------------
        frame_start = ((current_frame - 1) * frame_step_samples) + 1;
        frame_end = frame_start + (frame_length_samples - 1);
        
        output_samples(channel, frame_start:frame_end) = output_samples(channel, frame_start:frame_end) + frame_samples;
        
        % end timer
        elapsed_time = toc;
        total_elapsed_time = total_elapsed_time + elapsed_time;
        
        fprintf("Channel %d, frame %d processed in %.2fs (%.2fs total) ", channel, current_frame, elapsed_time, total_elapsed_time);
        fprintf("- %.1f%% done ", ((current_frame + number_of_frames * (channel - 1)) / (number_of_channels * number_of_frames)) * 100);
        fprintf("(%d spectral mappings completed)\n", spectral_mappings_per_frame(current_frame));
    end
end

% normalise output
output_samples(:) = output_samples(:) / max(abs(output_samples(:)));

% disp("Press any key to continue..."); pause;

% --- Output audio --------------------------------------------------------
input = audioplayer(input_samples(:, 1:number_of_samples)', sample_rate);
output = audioplayer(output_samples(:, 1:number_of_samples)', sample_rate);

% write to an output file
% audiowrite("output.wav", output_samples', sample_rate);

% compare input and output
play(input);
pause(number_of_samples / sample_rate + 1);
play(output);