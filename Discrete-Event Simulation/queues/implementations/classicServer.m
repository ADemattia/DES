classdef classicServer < server
    % classicServer: Models a standard multi-server node with parallel workers
    % Workers are statistically independent but share the same service-time distribution
    % No constraints are applied to customer types or physical access
    
    methods
        function  obj = classicServer(numServer, serverDistribution)
            % constructor: initializes parallel workers and their distributions
            obj@server(numServer, serverDistribution); 
        end
        
        function initialize(obj, ~, displayFlag)
            % sets up the server and prints its network configuration
            if displayFlag
                fprintf('————————————————————————————————————————————————————————————\n');
                fprintf('[SERVER %d] TYPE: Classic Server\n', obj.simulationId);
                fprintf('            ID: %d\n', obj.id);
                fprintf('            WORKERS: %d\n', obj.numWorkers);
                
                sources = [];
                for i = 1:obj.numSourceQueues
                    sources(end+1) = obj.sourceQueues{i}.id;
                end
                fprintf('            SOURCE QUEUES: [%s]\n', num2str(sources));
                
                if ~isempty(obj.destinationQueue)
                    fprintf('            DESTINATION QUEUE: %d\n', obj.destinationQueue.id);
                else
                    fprintf('            DESTINATION QUEUE: None (Exit Node)\n');
                end
                fprintf('————————————————————————————————————————————————————————————\n');
            end
        end

        function [canServe, selectedCustomer, selectedWorker, selectedQueue] = checkArrival(obj) 
            % determines if an idle worker and a non-empty source queue are available
            nonEmptyQueues = obj.sourceQueues(cellfun(@(q) q.lengthQueue > 0, obj.sourceQueues));

            if any(obj.availableWorkers) && ~isempty(nonEmptyQueues)
                % select the first available worker and the first available queue
                id = find(obj.availableWorkers, 1); 
                queue = nonEmptyQueues{1};  
               
                canServe = true;
                selectedCustomer = queue.customersList(1); % FIFO Policy
                selectedWorker = obj.workersArray{id};
                selectedQueue = queue;
                
            else
                % no service possible
                canServe = false;
                selectedCustomer = []; selectedWorker = []; selectedQueue = []; 
            end 
        end
        
        function handleArrival(obj, selectedCustomer, selectedWorker, selectedQueue, externalClock, eventsList, displayFlag)
            % starts service: logs entry time and sets the worker to BUSY
            selectedCustomer.path(end + 1) = obj.id; 
            selectedCustomer.startTime(obj.id) = externalClock; 

            selectedWorker.startService(selectedCustomer, externalClock); 
            obj.availableWorkers(selectedWorker.id) = 0;  

            % remove customer from source queue
            selectedQueue.handleExit(selectedCustomer, externalClock, displayFlag); 

            if displayFlag        
                fprintf('[SERVER %d] Worker %d set to BUSY with Customer %d (Clock: %.2f)\n', ...
                obj.simulationId, selectedWorker.id, selectedWorker.customer.id, externalClock);
            end
            obj.updateClock(eventsList); 
        end

        function handleWaiting(obj, externalClock, eventsList, displayFlag) 
            % moves a worker to WAITING status when service ends  
            obj.workerEvent.startWaiting(externalClock); 
            obj.waitingList{end+1} = obj.workerEvent;
           
            if  displayFlag        
                fprintf('[SERVER %d] Worker %d set to WAITING with Customer %d (Clock: %.2f)\n', ...
                    obj.simulationId, obj.workerEvent.id, obj.workerEvent.customer.id, externalClock);
            end
            obj.updateClock(eventsList);
        end 

        function handleExit(obj, externalClock, eventsList, displayFlag)
            % completes the exit procedure and moves the customer to the next queue 
            selectedWorker = obj.waitingList{1};
            obj.waitingList(1) = [];
            obj.availableWorkers(selectedWorker.id) = 1; % set worker as idle 

            customer = selectedWorker.startExit(externalClock); 
            customer.endTime(obj.id) = externalClock; 
           
            if displayFlag        
                fprintf('[SERVER %d] Worker %d set to IDLE released Customer %d (Clock: %.2f)\n', ...
                    obj.simulationId, selectedWorker.id, customer.id, externalClock);
            end

            obj.destinationQueue.handleArrival(customer, externalClock, displayFlag); % handle customer arrival in destination queue   
            obj.count = obj.count + 1; 
            obj.updateClock(eventsList); 
        end

        function exitFlag = checkExit(obj)   
            % returns true if a worker is waiting and the destination queue can accept them
            exitFlag = ~isempty(obj.waitingList) && obj.destinationQueue.checkArrival();
        end 

        function displayAgentState(obj, externalClock)
            % displayAgentState: Prints final throughput and detailed worker metrics
            fprintf('————————————————————————————————————————————————————————————\n');
            fprintf('[SERVER %-3d] FINAL STATISTICS (Clock: %.2f)\n', obj.simulationId, externalClock);
            fprintf('              ID: %d | TYPE: Classic Server\n', obj.id);
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

