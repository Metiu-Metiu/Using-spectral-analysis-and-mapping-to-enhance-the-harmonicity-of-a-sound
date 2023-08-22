function [] = validateUserInputs(user_inputs)

values = cell2mat(user_inputs(2, :));

% check for negative or floating point values
for i = 1:length(user_inputs)
    if i == 2
        continue
        
    elseif values(i) < 1 || floor(values(i)) ~= values(i)
        error("User input '%s' must be a positive non-zero integer", char(user_inputs(1, i)));
    end
end

% check overlap is not less than than 0
% check overlap is not greater than 99, to prevent infinite loop
if values(2) < 0 || values(2) > 99
    error("User input 'frame_overlap_percentage' must not fall outside the range 0-99");
end

