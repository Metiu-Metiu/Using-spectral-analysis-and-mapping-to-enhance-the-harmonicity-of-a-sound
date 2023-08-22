function [data_region] = enhancePeaks(data_region, max_in_frame, max_in_region, multiplier, divergence_index)

% input error checking
if divergence_index < 1 || mod(divergence_index, 1) ~= 0
    error("Divergence index must be a positive integer greater than 0");
end

[max_local_value, max_local_index] = max(data_region);

if max_local_index - divergence_index < 1
    divergence_index = abs(max_local_index - 1);
    %     disp("Divergence index adjusted to fit minimum bound");
end

if max_local_index + divergence_index > numel(data_region)
    divergence_index = abs(max_local_index - numel(data_region));
    %     disp("Divergence index adjusted to fit maximum bound");
end

% limit peak values post-multiplication to highest amplitude component in
% the frame
if (max_local_value * multiplier) > max_in_frame
    multiplier = max_in_frame / max_local_value;
    
    if multiplier < 1
        multiplier = 1;
    end
end

% https://uk.mathworks.com/help/signal/ref/bartlett.html
%
% The Bartlett window is very similar to a triangular window as returned by
% the triang function. However, the Bartlett window always has zeros at the
% first and last samples, while the triangular window is nonzero at those
% points.

window = bartlett(2 * divergence_index);
window = rescale(window, 1, multiplier);
window = window(divergence_index + 1:end);

for i = 0:divergence_index - 1
    % bartlett window scaling
    % only process max index when i = 0
    if i == 0
        data_region(max_local_index) = data_region(max_local_index) * multiplier;
        
        % process max index and value of divergence_index indicies left and right
    else
        data_region(max_local_index - i) = data_region(max_local_index - i) * window(i + 1);
        data_region(max_local_index + i) = data_region(max_local_index + i) * window(i + 1);
    end
end
end