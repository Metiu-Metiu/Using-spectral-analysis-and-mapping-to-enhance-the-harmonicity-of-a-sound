function [processed_data_region, success_flag] = asymWarp(unprocessed_data_region, original_peak, destination_peak)

success_flag = 0;
length_region = length(unprocessed_data_region);

% ORIGINAL PEAK AND DESTINATION PEAK HAVE TO BE WITHIN THE BOUNDS OF THE
% DATA REGION TO PERFORM WARPING

% REVISE:

% original peak is on or exceeds region bounds/does not meet minimum
% interpolation requirements
if original_peak >= length_region - 2 || original_peak <= 3
    % skip warp
    processed_data_region = unprocessed_data_region;
    
    % destination peak is on or exceeds region bounds/does not meet minimum
    % interpolation requirements
elseif destination_peak >= length_region - 2 || destination_peak <= 3
    % skip warp
    processed_data_region = unprocessed_data_region;
    
    % execute as normal
else
    % left sampling points
    left_sample_points = 2:1:original_peak;
    
    % calculation of left scaling factor
    % -1 accounts for the unprocessed first element
    left_step_factor = original_peak / (destination_peak - 1);
    
    % left interpolation and scaling (ignoring first and last elements)
    left_query_points = 2:left_step_factor:original_peak;
    
    left = interp1(left_sample_points, unprocessed_data_region(left_sample_points), left_query_points, 'spline');
    length_left = numel(left);
    
    % right sampling points
    right_sample_points = original_peak + 1:1:length_region - 1;
    
    % calculation of right scaling factor
    target = (length_region - 2) - length_left;
    right_step_factor = ((length_region - 1) - (original_peak + 1)) / (target - 1);
    
    right_query_points = original_peak + 1:right_step_factor:length_region - 1;
    right = interp1(right_sample_points, unprocessed_data_region(right_sample_points), right_query_points, 'spline');
    
    processed_data_region = [unprocessed_data_region(1) left right unprocessed_data_region(end)];
    success_flag = 1;
    
%     figure;
%     axis tight;
%     hold on;
%     
%     plot(unprocessed_data_region, 'Color', 'r');
%     plot(original_peak, max(unprocessed_data_region), 'o', 'Color', 'r');
%     xline(original_peak, '--', 'Color', 'r');
%     
%     plot(processed_data_region, 'Color', 'b');
%     plot(destination_peak, max(unprocessed_data_region), 'o', 'Color', 'b');
%     xline(destination_peak, '--', 'Color', 'b');
%     
%     legend("Input region",...
%         "Original peak (index " + sprintf("%d", original_peak) + ")",...
%         "Left and right region split",...
%         "Output region",...
%         "Destination peak (index " + sprintf("%d", destination_peak) + ")",...
%         "Interpolated left and right region split");
end
end