classdef simulator < handle
    % simulator: A Discrete Event Simulation (DES) engine
    % It manages the global simulation clock and coordinates asynchronous 
    % agent activations based on a scheduled event list
    
    properties
        externalClock % global simulation clock
        horizon % simulation time limit (stopping condition)
        
        agentsList % cell array containing all network agents
        numAgents  % number of agents 
        eventsList % handle list managing the scheduled event times for each agent 
        displayFlag % toggle for real-time console logging 
    end
    
    methods
        function obj = simulator(horizon, agentsList, displayFlag)
            % constructor: initializes simulation parameters and event list
            obj.externalClock = 0; 
            obj.numAgents = length(agentsList);
            obj.agentsList = agentsList;
            
            % initialize event times to infinity
            startList = inf(obj.numAgents,1);  
            obj.eventsList = handleList(startList); 

            obj.horizon = horizon;   
            obj.displayFlag = displayFlag;
        end
        
        function agentSetUp(obj)
            % agentSetUp: assigns unique simulation IDs to each agent based on list order
            for i = 1:length(obj.agentsList)
                agent = obj.agentsList{i}; 
                agent.simulationId = i; 
            end 
        end 
  
        function executeSimulation(obj)
            % executeSimulation: runs the main simulation loop

            % INITIALIZATION: set starting state for every agent
            for i = 1: length(obj.agentsList)
                agent = obj.agentsList{i};
                agent.initialize(obj.eventsList, obj.displayFlag); 
            end
      
            % EVENT LOOP: Advance clock and execute scheduled events 
            while obj.externalClock < obj.horizon

                % identify the earliest event in the network 
                [nextEvent, nextId] = obj.eventsList.minList();

                if nextEvent == inf
                    if obj.displayFlag
                        fprintf('\n————————————————————————————————————————————————————————————\n');
                        fprintf('——— TERMINATION | No more events scheduled. Exiting... ———\n');
                        fprintf('————————————————————————————————————————————————————————————\n');
                    end
                    break; % exit the while loop
                end 
                % update global clock to event time
                obj.externalClock = nextEvent;
                eventAgent = obj.agentsList{nextId};

                if obj.displayFlag
                    fprintf('\n——— SIMULATION STEP | Time: %.2f ———\n', obj.externalClock);
                    fprintf('————————————————————————————————————————————————————————————\n');
                end

                % Execute the primary event
                eventAgent.execute(obj.externalClock, obj.eventsList, obj.displayFlag);
  
                % this ensures secondary effects (e.g., blocking/unblocking) are resolved
                canUpdate = true;
                while canUpdate
                    canUpdate = false; 
                    for i = 1:length(obj.agentsList) 
                        agent = obj.agentsList{i};
                        % If an agent changes state, trigger another pass to check dependencies
                        canUpdate = canUpdate || agent.update(obj.externalClock, obj.eventsList, obj.displayFlag);
                    end 
                end 
            end 

            if obj.displayFlag
                fprintf('\nSimulation reached horizon (T = %.2f).\n', obj.horizon);
            end
        end 

        function displayAgentStates(obj)
            % displayAgentStates: Triggers final reporting for all network agents
            fprintf('\n============================================================\n');
            fprintf('FINAL SIMULATION REPORT | Total Time: %.2f\n', obj.externalClock);
            fprintf('============================================================\n');
            for i = 1:obj.numAgents
                agent = obj.agentsList{i};
                agent.displayAgentState(obj.externalClock);
            end
        end

        function clear(obj)
            % clear: Resets all agents and global clock for a fresh simulation run
            obj.externalClock = 0;
            for i = 1:obj.numAgents
                agent = obj.agentsList{i}; 
                agent.clear();
            end 
            fprintf('Simulation environment and agent statistics cleared.\n');
        end
    end
end

