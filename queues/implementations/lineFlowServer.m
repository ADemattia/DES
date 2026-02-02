classdef lineFlowServer < server
    % lineFlowServer: Models a service node with physical layout constraints
    % Simulates servers arranged in a row (e.g., gas pumps) where a customer 
    % cannot reach or leave a worker if another worker is physically blocking the path

    properties
        constraints % adjacency matrix [nxn]: A(i,j)=1 means worker i blocks worker j's exit path
        numTypes % total number of customer types in the simulation
        typesPerWorker % cell array: defines specific customer types accepted by each worker
        exitId  % id of the worker selected to leave the waitingList
    end

    methods
        function obj = lineFlowServer(numWorkers, serverDistribution, contraints, numTypes, typesPerWorker)
            % constructor: configures physical exit constraints and worker specializations
            obj@server(numWorkers, serverDistribution);
            obj.exitId = NaN; 

            obj.constraints = contraints;
            obj.numTypes = numTypes; 
            obj.typesPerWorker = typesPerWorker;
           
            for i = 1:obj.numWorkers, obj.workersArray{i}.setTypes(obj.typesPerWorker{i}); end 
        end
        
        function initialize(obj, ~, displayFlag) 
            % prints its configuration setup
            if displayFlag
                fprintf('————————————————————————————————————————————————————————————\n');
                fprintf('[SERVER %-3d] TYPE: Gas Server (Physical Constraints)\n', obj.simulationId);
                fprintf('              ID: %d\n', obj.id);
                fprintf('              WORKERS: %d\n', obj.numWorkers);
                fprintf('              TOTAL CUSTOMER TYPES: %d\n', obj.numTypes);
                
                [row, col] = find(obj.constraints);
                if ~isempty(row)
                    fprintf('              PHYSICAL CONSTRAINTS (i before j):\n');
                    for k = 1:length(row)
                        fprintf('                • Worker %d blocks Worker %d\n', row(k), col(k));
                    end
                else
                    fprintf('              PHYSICAL CONSTRAINTS: None (Parallel)\n');
                end

                fprintf('              WORKER SPECIALIZATION:\n');
                for i = 1:obj.numWorkers
                    types = obj.typesPerWorker{i};
                    fprintf('                • Worker %d: Types [%s]\n', i, num2str(types));
                end
                
                if obj.numSourceQueues > 0
                    sIds = cellfun(@(q) q.id, obj.sourceQueues);
                    fprintf('              SOURCE QUEUES: [%s]\n', num2str(sIds));
                end
                if ~isempty(obj.destinationQueue)
                    fprintf('              DESTINATION QUEUE: %d\n', obj.destinationQueue.id);
                end
                fprintf('————————————————————————————————————————————————————————————\n');
            end 
        end

        function [canServe, selectedCustomer, selectedWorker, selectedQueue] = checkArrival(obj)
            % checkArrival: Identifies if an idle and accessible worker can serve a customer

            % filter workers by availability and physical access constraints
            elegibleWorkers = obj.availableWorkers;
            occupiedWorkers = ~obj.availableWorkers; 

            for l = 1 : obj.numWorkers
                % worker is unreachable if any blocking worker is occupied
                if any(obj.constraints(l,:) & occupiedWorkers) 
                    elegibleWorkers(l) = 0;  
                end
            end 

            elegibleWorkersArray = obj.workersArray(logical(elegibleWorkers)); 

            if any(elegibleWorkers)
                for i = 1 : obj.numSourceQueues  
                    selectedQueue = obj.sourceQueues{i};
                    numToCheck = 1;  
                    % check if overtaking is allowed, otherwise only the first
                    if selectedQueue.overtakingFlag == true
                        numToCheck = selectedQueue.lengthQueue; 
                    end 

                    if selectedQueue.lengthQueue > 0
                        for j = 1:numToCheck
                            % find eligible workers compatible with customer type
                            selectedCustomer = selectedQueue.customersList(j); % FIFO 
                            validPos = find(cellfun(@(w) w.checkAcceptance(selectedCustomer.type), elegibleWorkersArray)); 

                            
                            if ~isempty(validPos)
                                pos = validPos(randi(length(validPos))); % random choice of worker 
                                canServe = true; 
                                selectedWorker = elegibleWorkersArray{pos}; 
                                return
                            end 
                        end                        
                    end
                end
            end

            canServe = false;
            selectedCustomer = []; selectedWorker = []; selectedQueue = [];
        end

        function handleArrival(obj, selectedCustomer, selectedWorker, selectedQueue, externalClock, eventsList, displayFlag)
            % starts service and updates worker to BUSY
            selectedCustomer.path(end + 1) = obj.id; 
            selectedCustomer.startTime(obj.id) = externalClock; 

            selectedWorker.startService(selectedCustomer, externalClock); 
            obj.availableWorkers(selectedWorker.id) = 0;  

            selectedQueue.handleExit(selectedCustomer, externalClock, displayFlag); 

            if displayFlag        
                fprintf('[SERVER %d] Worker %d set to BUSY with Customer %d (Clock: %.2f)\n', ...
                obj.simulationId, selectedWorker.id, selectedWorker.customer.id, externalClock);
            end
            obj.updateClock(eventsList); 
        end

        function handleWaiting(obj, externalClock, eventsList, displayFlag) 
            % move to WaitingList until the exit is possible
            obj.workerEvent.startWaiting(externalClock); 
            obj.waitingList{end+1} = obj.workerEvent;
           
            if  displayFlag        
                fprintf('[SERVER %d] Worker %d set to WAITING with Customer %d (Clock: %.2f)\n', ...
                    obj.simulationId, obj.workerEvent.id, obj.workerEvent.customer.id, externalClock);
            end

            obj.updateClock(eventsList);
        end 

        function canExit = checkExit(obj)
            % check if a worker in the waiting list can physically leave the station
            if ~isempty(obj.waitingList) && obj.destinationQueue.checkArrival()
                occupiedWorkers = ~obj.availableWorkers;

                for i = 1:length(obj.waitingList)
                    selectedWorker = obj.waitingList{i}; 
                    % check if any busy worker is blocking the exit path of selectedWorker
                    % constraints(:, selectedWorker.id) looks for anyone who blocks our exit
                    if ~any(occupiedWorkers & obj.constraints(:, selectedWorker.id)')
                        canExit = true; 
                        obj.exitId = i; 
                        return 
                    end 
                end 
            end
            canExit = false; 
        end 

        function handleExit(obj, externalClock, eventsList, displayFlag)
            % releases the customer to the next queue and frees the worker
            selectedWorker = obj.waitingList{obj.exitId};
            obj.waitingList(obj.exitId) = [];
            obj.exitId = NaN; 
            obj.availableWorkers(selectedWorker.id) = 1; 

            customer = selectedWorker.startExit(externalClock); 
            customer.endTime(obj.id) = externalClock;  
           
            if displayFlag        
                fprintf('[SERVER %d] Worker %d set to IDLE released Customer %d (Clock: %.2f)\n', ...
                    obj.simulationId, selectedWorker.id, customer.id, externalClock);
            end
            obj.destinationQueue.handleArrival(customer, externalClock, displayFlag); 

            obj.count = obj.count + 1; 
            obj.updateClock(eventsList); 
        end
        
        function displayAgentState(obj, externalClock)
            % displayAgentState: Prints performance metrics and individual worker status
            fprintf('————————————————————————————————————————————————————————————\n');
            fprintf('[SERVER %-3d] FINAL STATISTICS (Clock: %.2f)\n', obj.simulationId, externalClock);
            fprintf('              ID: %d | TYPE: Line Flow Server\n', obj.id);
            fprintf('              TOTAL THROUGHPUT: %d customers\n', obj.count);
            
            fprintf('              ——————————————————————————————————————\n');
            fprintf('              DETAILED WORKER UTILIZATION:\n');
            totalBusyTime = 0;
            for i = 1:obj.numWorkers
                obj.workersArray{i}.displayWorkerStats();
                totalBusyTime = totalBusyTime + obj.workersArray{i}.timeInBusy;
            end
            
            avgUtil = (totalBusyTime / (obj.numWorkers * externalClock)) * 100;
            fprintf('              ——————————————————————————————————————\n');
            fprintf('              OVERALL SERVER EFFICIENCY: %.2f%%\n', avgUtil);
            fprintf('————————————————————————————————————————————————————————————\n');
        end

        function clear(obj)
            % reset all properties for a simulation restart
            obj.clock = inf; 
            obj.count = 0;  
            obj.waitingList = worker.empty();
            for i = 1:obj.numWorkers, obj.workersArray{i}.clear(); end
        end 
    end
end

