classdef learningDynamic < policy
    % learningDynamic: Implements a Logit-based stochastic choice policy
    % This policy uses a Softmax function to convert payoffs into probabilities
    % It allows for bounded rationality, where higher payoff actions are 
    % more likely to be chosen, but sub-optimal choices remain possible
  
    properties
        eta % inverse temperature
        decay  % rate at which eta changes over time
        applyDecay % toggle to enable/disable decay 
    end

    methods
        function obj = learningDynamic(eta, decay, applyDecay)
            % constructor: initializes learning parameters
            obj.eta = eta; 
            obj.decay = decay;
            obj.applyDecay = applyDecay; 
        end

        function nextAction = updateAction(obj, managerId, profile, actionsSpace, utilityFunction)
            % updateAction: selects an action based on Gibbs/Boltzmann distribution
            logits = zeros(1, length(actionsSpace)); 
            
            for i=1:length(actionsSpace)
                newProfile = profile; 
                newProfile(managerId) = actionsSpace(i); 
                utility = utilityFunction(newProfile); 
                logits(i) = exp(obj.eta * utility); 
            end

            % logits computation
            probabilities = logits / sum(logits);

            % sample an action according to the logits 
            ids = randsample(length(actionsSpace), 1, true, probabilities); 
            nextAction = actionsSpace(ids);

            % local decay for each player 
            if obj.applyDecay
                obj.eta = obj.eta * obj.decay; 
            end
        end
    end
end
