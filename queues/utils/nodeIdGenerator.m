classdef nodeIdGenerator  
    % nodeIdGenerator: provides unique, sequential identifiers for network entities.
    methods (Static)
        function id = getId()
            persistent lastId;
             if isempty(lastId)
                lastId = 0; 
             end
            id = lastId + 1; 
            lastId = lastId + 1; 
        end
    end
end

