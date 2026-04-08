classdef bestResponse < policy
    % bestResponse: Implements a purely rational decision-making policy
    % The agent evaluates all possible actions in the current context 
    % and selects the one that yields the highest utility
    
    methods
        function bestAction = updateAction(~, managerId, profile, actionsSpace, utilityFunction)
            % updateAction: finds the utility-maximizing action for the agent
            utilities = zeros(1, length(actionsSpace)); 
            
            for i=1:length(actionsSpace)
                newProfile = profile; 
                newProfile(managerId) = actionsSpace(i); 
                utilities(i) = utilityFunction(newProfile); 
            end 
            
            [~, id] = max(utilities);
            bestAction = actionsSpace(id);
        end
    end
end