classdef worker < handle  
    % worker: represents an individual service unit within a server
    % manages its own state transitions (Idle, Busy, Waiting) and tracks
    % performance statistics over time

    properties
        id % entity identifier
        clock  % local clock
        previousClock % timestamp of the last state change (for stats)
        workerState  % current state: Idle, Busy, or Waiting
        workerDistribution % service time Distribution
        customer % buffer for the current customer
        timeInIdle % total cumulative time spent in Idle state
        timeInBusy % total cumulative time spent in Busy state
        timeInWaiting % total cumulative time spent in Waiting state
        acceptedTypes % list of customer types this worker accepts 
    end

    methods
        function obj = worker(id, workerDistribution)
            % constructor: initializes state
            if nargin == 0 
                % null worker initialization
                obj.id = 0;
            else 
                obj.id = id; 
                obj.clock = inf; 
                obj.previousClock = 0; 
                obj.workerState = workerState.Idle; 
                obj.workerDistribution = workerDistribution; 
                obj.acceptedTypes = [];

                % stats initialization 
                obj.timeInIdle = 0; 
                obj.timeInBusy = 0; 
                obj.timeInWaiting = 0;
            end 
        end
        
        function setTypes(obj, acceptedTypes)
            % setTypes: defines which customer types the worker can handle
            obj.acceptedTypes = acceptedTypes; 
        end 

        function canAccept = checkAcceptance(obj, type)
            % checkAcceptance: returns true if the type is in the accepted list or list is empty
            canAccept = isempty(obj.acceptedTypes) || any(obj.acceptedTypes == type);
        end

        function isIdle = isIdle(obj)
            isIdle = (obj.workerState == workerState.Idle);
        end

        function startService(obj, customer, externalClock)
            % startService: transition from Idle to Busy and schedule end of service
            obj.timeInIdle = obj.timeInIdle + (externalClock - obj.previousClock); 
            obj.previousClock = externalClock;
 
            obj.customer = customer;  
            obj.workerState = workerState.Busy;

            % sample service time from the distribution 
            serviceTime = obj.workerDistribution();
            obj.clock = externalClock + serviceTime; 
        end 

        function startWaiting(obj, externalClock)
            % startWaiting: service finished, but worker is blocked from releasing customer
            obj.timeInBusy = obj.timeInBusy + (externalClock - obj.previousClock); 
            obj.previousClock = externalClock; 

            obj.workerState = workerState.Waiting; 
            obj.clock = inf; % no scheduled event
        end 

        function customer = startExit(obj, externalClock)
            % startExit: customer released, transition back to Idle
            obj.timeInWaiting = obj.timeInWaiting + (externalClock - obj.previousClock); 
            obj.previousClock = externalClock;
 
            customer = obj.customer; 
            obj.customer = [];
            obj.workerState = workerState.Idle;
            obj.clock = inf; 
        end 
        
        function displayWorkerStats(obj)
            totalSimulationTime = obj.timeInBusy + obj.timeInWaiting + obj.timeInIdle; 
            % displayWorkerStats: prints detailed utilization percentages
            if totalSimulationTime > 0
                utilBusy    = (obj.timeInBusy / totalSimulationTime) * 100;
                utilWaiting = (obj.timeInWaiting / totalSimulationTime) * 100;
                utilIdle    = (obj.timeInIdle / totalSimulationTime) * 100;
                
                fprintf('              • Worker %-2d | Busy: %5.1f%% | Waiting: %5.1f%% | Idle: %5.1f%%\n', ...
                    obj.id, utilBusy, utilWaiting, utilIdle);
            else
                fprintf('              • Worker %-2d | No time recorded.\n', obj.id);
            end
        end

        function clear(obj)
            % reset all properties for a simulation restart
            obj.clock = inf;
            obj.previousClock = 0;
            obj.customer = []; 
            obj.timeInBusy = 0; 
            obj.timeInIdle = 0; 
            obj.timeInWaiting = 0; 
        end 
    end
end