classdef balkingQueue < queue
    % balkingQueue: A queue with a deterministic (hard) capacity and a 
    % probabilistic (soft) capacity where customers may "balk" (refuse to enter)
    
    properties
        hardCapacity % guaranteed entry threshold
        softCapacity % probabilistic entry range
        totalCapacity % combined capacity (hard + soft)
        softCapacityDistribution % distribution handle returning 1 (enter) or 0 (balk)  
    end
    
    methods
        function obj = balkingQueue(overtakingFlag, waitingFlag, hardCapacity, softCapacity, softCapacityDistribution)
            % constructor: initializes balking thresholds and entry logic
            obj@queue(overtakingFlag, waitingFlag); 
            obj.hardCapacity = hardCapacity; 
            obj.softCapacity = softCapacity; 
            obj.totalCapacity = obj.hardCapacity + obj.softCapacity; 
            obj.softCapacityDistribution = softCapacityDistribution;
        end

        function initialize(obj, ~, displayFlag)
            % prints its configuration setup
            if displayFlag
                fprintf('————————————————————————————————————————————————————————————\n');
                fprintf('[QUEUE  %-3d] TYPE: Balking Queue (Probabilistic Entry)\n', obj.simulationId);
                fprintf('              ID: %d\n', obj.id);
                fprintf('              HARD CAPACITY (Guaranteed): %d\n', obj.hardCapacity);
                fprintf('              SOFT CAPACITY (Balking):    %d\n', obj.softCapacity);
                fprintf('              TOTAL CAPACITY:             %d\n', obj.totalCapacity);
                
                overtakeStr = 'OFF'; if obj.overtakingFlag; overtakeStr = 'ON'; end
                waitingStr  = 'REJECT (Lost)'; if obj.waitingFlag; waitingStr = 'BLOCKING (Server waits)'; end
                
                fprintf('              OVERTAKING: %s\n', overtakeStr);
                fprintf('              WAITING POLICY: %s\n', waitingStr);

                sServers = cellfun(@(s) s.id, obj.sourceServers, 'UniformOutput', false);
                sGens = cellfun(@(g) g.id, obj.sourceGenerators, 'UniformOutput', false);
                
                fprintf('              SOURCE SERVERS: [%s]\n', num2str([sServers{:}]));
                fprintf('              SOURCE GENERATORS: [%s]\n', num2str([sGens{:}]));
                
                if ~isempty(obj.destinationServer)
                    fprintf('              DESTINATION SERVER: %d\n', obj.destinationServer.id);
                else
                    fprintf('              DESTINATION SERVER: None\n');
                end
                fprintf('————————————————————————————————————————————————————————————\n');
            end
        end

        function handleArrival(obj, customer, externalClock, displayFlag)
            % handleArrival: processes customer entry based on current queue occupancy
            if displayFlag
                fprintf('[QUEUE %d] Customer %d ARRIVAL (Clock: %.2f)\n', ...
                    obj.simulationId, customer.id, externalClock);
            end

            customer.path(end + 1) = obj.id;
            customer.startTime(obj.id) = externalClock;
            obj.updateStat(externalClock); 

            if obj.lengthQueue < obj.hardCapacity
                % hard Capacity: Guaranteed entry
                obj.customersList(end + 1) = customer;
                obj.lengthQueue = obj.lengthQueue + 1; 
                obj.count = obj.count + 1;  

            elseif obj.lengthQueue >= obj.hardCapacity && obj.lengthQueue < obj.totalCapacity 
                    % soft Capacity: probabilistic entry (Balking)
                    decision = obj.softCapacityDistribution(); 
                    if decision == 1
                        obj.customersList(end + 1) = customer;
                        obj.lengthQueue = obj.lengthQueue + 1; 
                        obj.count = obj.count + 1; 
                    else 
                        obj.lostCustomers = obj.lostCustomers + 1; % balked 
                    end
            else 
                % total capacity exceeded: forced rejection
                obj.lostCustomers = obj.lostCustomers + 1; 
            end 
        end

        function canEnter = checkArrival(obj) 
            % canEnter: true if there is any remaining space (including soft spots)
            canEnter = obj.waitingFlag;  
        end 
        
        function clear(obj)
            % reset all properties for a simulation restart
            obj.clock = inf; 
            obj.customerList = customer.empty();
            obj.lengthQueue = 0; 
            obj.count = 0;
            obj.lostCustomer = 0; 
            obj.averageLength = 0; 
        end
    end
end

