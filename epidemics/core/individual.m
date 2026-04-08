classdef individual < handle
    % individual: base class for epidemic agents in a network simulation
    % handles disease state transitions (SI, SIR, SIRS), interaction logic, and health statistics
    
    properties
        id % entity identifier  
        simulationId % identifier in simulator
        clock % local node clock  
        previousClock % reference timestamp for state duration tracking
 
        state % current infection state (Susceptible, Infected, Recovered) 
        initialState % initial state for simulation reset  
        recoveryDistribution % recovery time distribution 
        waningDistribution  % immunity time distribution 
        meetDistribution % inter-interaction time distribution  
        neighbors % cell array of connected individuals (network topology)
        numNeighbors % number neighbors
        network % network manager 
 
        nextTarget % individual selected for the next interaction 
        timeInSusceptible % cumulative time spent in Susceptible state
        timeInInfected % cumulative time spent in Infected state
        timeInRecovered % cumulative time spent in Recovered state
        infectionsProduced % total number of infections transmitted
    end
    
    methods
        function obj = individual(infectionState, meetDistribution, recoveryDistribution, waningDistribution)
            % constructor: initializes initial state, distributions and counters
            obj.clock = 0; 
            obj.id = individualIdGenerator.getId();
            obj.nextTarget = [];  
            obj.state = infectionState; 
            obj.initialState = infectionState; 
            obj.recoveryDistribution = recoveryDistribution;
            obj.waningDistribution = waningDistribution; 
            obj.meetDistribution = meetDistribution;
            obj.timeInSusceptible = 0; 
            obj.timeInInfected= 0;
            obj.timeInRecovered = 0; 
            obj.infectionsProduced = 0; 
        end

        % Network Topology
        function neighborsAssignment(obj, neighbors, network)
            obj.neighbors = neighbors; 
            obj.numNeighbors = length(obj.neighbors);
            obj.network = network; 
        end

        function handleInfection(obj)
            % handleInfection: schedules the next meeting with a neighbor (competing risks)
            meetTimes = inf(1, obj.numNeighbors); 
            for i = 1: obj.numNeighbors 
                nextMeeting = obj.meetDistribution(obj.neighbors{i}.id); 
                meetTimes(i) = nextMeeting; 
            end
            [interArrival, neighborId] = min(meetTimes);
            obj.previousClock = obj.clock; 
            obj.clock = obj.clock + interArrival; 
            obj.nextTarget = obj.neighbors{neighborId};
        end 

        function handleRecovery(obj)
            % handleRecovery: schedules the time of recovery from infection
            recoveryTime = obj.recoveryDistribution(); 
            obj.previousClock = obj.clock; 
            obj.clock = obj.clock + recoveryTime;
        end 

        function handleWaning(obj)
            % handleWaning: schedules the loss of immunity (return to Susceptible)
            susceptibleTime = obj.waningDistribution();
            obj.previousClock = obj.clock; 
            obj.clock = obj.clock + susceptibleTime; 
        end 

        function initialize(obj, eventsList, displayFlag)
            % initialize: prepares the individual for simulation and schedules the first event
            if displayFlag
                neighborIDs = cellfun(@(x) num2str(x.simulationId), obj.neighbors, 'UniformOutput', false);
                strNeighbors = strjoin(neighborIDs, ', ');
                if isempty(strNeighbors), strNeighbors = 'None'; end                
                fprintf('INDIVIDUAL %d | State: %-11s | Neighbors: [%s]\n', ...
                        obj.simulationId, char(obj.state), strNeighbors);
            end
 
            switch obj.state
                case individualState.Susceptible
                    obj.handleInfection();                         
                case individualState.Infected
                    obj.handleRecovery();
                case individualState.Recovered
                    obj.handleWaning();                                
            end 
            eventsList.update(obj.simulationId, obj.clock);
        end 

        function updateFlag = update(obj, ~, ~, ~)
            % update: placeholder for external event synchronization (not used in SIR)
            updateFlag = false; 
        end 

        function execute(obj, ~, eventsList, displayFlag)
            % execute: processes the scheduled event and updates agent state
            switch obj.state 
                case individualState.Susceptible
                    obj.updateStats(obj.clock - obj.previousClock)
                    if obj.nextTarget.state == individualState.Infected
                        % transmit infection and schedule recovery
                        obj.nextTarget.infectionsProduced = obj.nextTarget.infectionsProduced + 1;
                        obj.state = individualState.Infected; 
                        obj.handleRecovery(); 
                        eventDescription = sprintf('Met Ind. %d (INFECTED) -> Infection occurred', obj.nextTarget.simulationId);
                    else
                        % no transmission, schedule next meeting
                        obj.handleInfection(); 
                        eventDescription = sprintf('Met Ind. %d (%s) -> No infection', obj.nextTarget.simulationId, char( obj.nextTarget.state));
                    end 

                case individualState.Infected
                    % recover and schedule waning immunity
                    obj.updateStats(obj.clock - obj.previousClock)
                    obj.state = individualState.Recovered;
                    obj.handleWaning();

                    eventDescription = 'Recovery process completed';
               
                case individualState.Recovered
                    % lose immunity and schedule next interaction
                    obj.updateStats(obj.clock - obj.previousClock)
                    obj.state = individualState.Susceptible;
                    eventDescription = 'Immunity waned -> Back to Susceptible';
                    obj.handleInfection();
            end 

            if displayFlag
                fprintf('Ind. %-3d | Event: %-40s | New State: %s\n', ...
                        obj.simulationId, eventDescription, char(obj.state));
            end
            eventsList.update(obj.simulationId, obj.clock);
        end 
        
        function updateStats(obj, duration)
            % updateStats: accumulates time spent in the current health state
            switch obj.state
                case individualState.Susceptible, obj.timeInSusceptible = obj.timeInSusceptible + duration;
                case individualState.Infected,    obj.timeInInfected = obj.timeInInfected+ duration;
                case individualState.Recovered,   obj.timeInRecovered = obj.timeInRecovered + duration;
            end
        end

        function displayAgentState(obj, externalClock)
            % displayAgentState: prints final individual statistics
            fprintf('————————————————————————————————————————————————————————————\n');
            fprintf('[INDIV  %-3d] FINAL STATISTICS (Clock: %.2f)\n', obj.simulationId, externalClock);
            fprintf('              ID: %d\n', obj.id);
            fprintf('              CURRENT STATE:       %s\n', char(obj.state));
            fprintf('              INFECTIONS PRODUCED: %d\n', obj.infectionsProduced);
            fprintf('————————————————————————————————————————————————————————————\n');
        end

       function clear(obj)
            obj.clock = 0;
            obj.previousClock = 0; 
            obj.state = obj.initialState;
            obj.nextTarget = []; 
            obj.timeInSusceptible = 0; 
            obj.timeInInfected= 0;
            obj.timeInRecovered = 0; 
            obj.infectionsProduced = 0; 
       end
    end
end

