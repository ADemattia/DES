classdef player < handle 
    % player: core class for strategic agents in a game-theoretic simulation
    % handles strategy updates based on a decision policy and utility function, and activation logic 

    properties
        id % entity identifier 
        simulationId % identifier in simulator
        clock % local node clock 
        manager  % reference to gameManager
        managerId % identifier in simulation manager 
        actionsSpace % vector of available actions 
        action % currently selected action
        utilityFunction % function handle to calculate payoffs
        policy % decision-making logic (e.g., best response)

        activationDistribution % inter-activation times distribution  
     end

    methods
        function obj = player(actionsSpace, action, utilityFunction, activationDistribution, policy)
            % constructor: initializes parallel workers and their distributions
            obj.id = playerIdGenerator.getId();
            obj.clock = 0; 
            obj.actionsSpace = actionsSpace;
            obj.action = action; 
            obj.utilityFunction = utilityFunction;
            obj.activationDistribution = activationDistribution;
            obj.policy = policy; 
        end
        
        function managerAssignment(obj, managerId, manager)
            obj.managerId = managerId; % managerId hold the position of player in  game profile
            obj.manager = manager; 
        end

        function initialize(obj, eventsList, displayFlag)
            % initialize: prepares the player and schedules the first activation event
            if displayFlag
                fprintf('————————————————————————————————————————————————————————————\n');
                fprintf('[PLAYER %d] Initialized | Initial Action: %s\n', ...
                        obj.simulationId, num2str(obj.action));
            end

            interActivation = obj.activationDistribution(); 
            obj.clock = obj.clock + interActivation;
            eventsList.update(obj.simulationId, obj.clock);
        end 

        function execute(obj, externalClock, eventsList, displayFlag)
            % execute: performs the strategic update according to the policy, when the agent is activated     
            previousAction = obj.action;
            profile = obj.manager.profile; 
            nextAction = obj.policy.updateAction(obj.managerId, profile, obj.actionsSpace, obj.utilityFunction);
            obj.action = nextAction; 
  
            obj.manager.updateProfile(obj.managerId, obj.action, externalClock); 
            interActivation = obj.activationDistribution(); 
            obj.clock = obj.clock + interActivation;     
            eventsList.update(obj.simulationId, obj.clock);

            if displayFlag
                fprintf('————————————————————————————————————————————————————————————\n');
                fprintf('[PLAYER %-3d] Action Update\n', obj.simulationId);
                fprintf('            PREVIOUS ACTION: %s\n', num2str(previousAction));
                fprintf('            CURRENT ACTION:  %s\n', num2str(obj.action));
            end
        end

        function updateFlag = update(obj, ~, ~, ~)
            % update: placeholder for external event synchronization 
            updateFlag = false; 
        end 

        function displayAgentState(obj, ~)
            % displayAgentState: prints the final state of the player
            fprintf('————————————————————————————————————————————————————————————\n');
            fprintf('[PLAYER %-3d] FINAL STATE\n', obj.simulationId);
            fprintf('              ID:           %d\n', obj.id);
            fprintf('              FINAL ACTION: %s\n', num2str(obj.action));
            fprintf('————————————————————————————————————————————————————————————\n');
        end
    end
end