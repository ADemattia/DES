classdef (Abstract) policy < handle
    % policy: Abstract base class defining the interface for agent decision-making
    % This class ensures that all derived decision dynamics (e.g., Best Response, 
    % Logit, Mistake) implement a consistent update mechanism

    methods (Abstract)
        updateAction(obj, managerId, profile, actionsSpace, utilityFunction)
    end
end