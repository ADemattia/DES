classdef mistakeDynamic < policy
    % mistakeDynamic: implements an epsilon-greedy decision policy
    % the agent typically chooses the Best Response to the current profile, 
    % but with probability epsilon, it makes a "mistake" by selecting 
    % a random action from the available action space

    properties
        epsilon % probability of making a random choice (noise rate)
    end

    methods
        function obj = mistakeDynamic(epsilon)
            % constructor: initializes the policy with a specific noise level
            obj.epsilon = epsilon; 
        end

        function nextAction = updateAction(obj, managerId, profile, actionsSpace, utilityFunction)
            % updateAction: determines the next strategy using epsilon-greedy logic

            utilities = zeros(1, length(actionsSpace)); 
            
            for i=1:length(actionsSpace)
                newProfile = profile; 
                newProfile(managerId) = actionsSpace(i); 
                utilities(i) = utilityFunction(newProfile); 
            end 
            
            [~, id] = max(utilities);
            bestAction = actionsSpace(id);

            % mistake dynamic 
            u = rand; 
            if u > obj.epsilon
                nextAction = bestAction; 
            else
                nextAction = actionsSpace(randi(length(actionsSpace))); 
            end 
        end
    end
end
