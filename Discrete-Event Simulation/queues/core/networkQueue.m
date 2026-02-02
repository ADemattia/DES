classdef networkQueue
    % networkQueue: Manages connectivity and performance metrics for the entire system.
    % Handles node linking via adjacency matrix and aggregates final simulation data.
    
    properties
        queueNodes % cell array of all network entities (generators, queues, servers)
        queueArray  % subset containing only queue objects for monitoring 
        queueGraph % adjacency matrix [nxn] defining the queue network connections
        endQueue % final sink node to collect and timestamp exited customers 
    end
    
    methods
        function obj = networkQueue(queueNodes, queueGraph)
            % constructor: initializes nodes and the final data collector (sink)
            obj.queueNodes = queueNodes; 
            obj.queueArray = [obj.queueNodes{cellfun(@(x) isa(x, 'queue'), obj.queueNodes)}]; 
            obj.queueGraph = queueGraph;
           
            % endQueue: infinite capacity sink for post-simulation analysis
            obj.endQueue = classicQueue(true, false, inf); 
            obj.endQueue.simulationId = inf;  
        end
        
        function networkSetUp(obj)
            % networkSetUp: resolves the graph to link agents' input/output ports
            networkLength = length(obj.queueNodes); 
            for i = 1: networkLength
                node = obj.queueNodes{i};

                if isa(node, 'generator')
                    % Link generator to its target queue
                    queueId = find(obj.queueGraph(i, :) == 1); 
                    node.destinationQueueAssignment(obj.queueNodes{queueId}, networkLength); 

                elseif isa(node, 'queue')
                    % Link queue to its downstream serve
                    destinationServerId = find(obj.queueGraph(i, :) == 1);
                    node.destinationServerAssignment(obj.queueNodes{destinationServerId}); 

                    % Identify and link upstream source agents
                    sourceIds = find(obj.queueGraph(:, i) == 1);
                    sourceNodes = obj.queueNodes(sourceIds);
                    sourceGenerators = sourceNodes(cellfun(@(x) isa(x,'generator'), sourceNodes));
                    sourceServers = sourceNodes(cellfun(@(x) isa(x,'server'), sourceNodes));
                    node.sourceServersAssignment(sourceServers);
                    node.sourceGeneratorsAssignment(sourceGenerators);
                    
                elseif isa(node, 'server')
                    % Link server to its source queues
                    sourceQueueId = find(obj.queueGraph(:, i) == 1); 
                    node.sourceQueuesAssignment(obj.queueNodes(sourceQueueId));

                    % Link to next queue or to Sink if terminal node
                    if i == networkLength 
                        node.destinationQueueAssignment(obj.endQueue)  
                    else
                        destinationQueueId = find(obj.queueGraph(i, :) == 1);
                        node.destinationQueueAssignment(obj.queueNodes{destinationQueueId});
                    end 
                end
            end 
        end

        function statistic(obj)
            % waitingTimeStatistic: calculates and displays average residence times per node
            customerList = obj.endQueue.customersList;
            numNodes = length(obj.queueNodes); 
            
            totalTimePerNode = zeros(numNodes, 1);
            countPerNode = zeros(numNodes, 1); 
            
            for i = 1:length(customerList)
                cust = customerList(i); 
                for j = 1:numNodes
                    if ~isnan(cust.endTime(j)) && ~isnan(cust.startTime(j))
                        countPerNode(j) = countPerNode(j) + 1;
                        totalTimePerNode(j) = totalTimePerNode(j) + (cust.endTime(j) - cust.startTime(j));
                    end 
                end 
            end 
        
            fprintf('\n============================================================\n');
            fprintf('%-15s | %-4s | %-10s | %-15s\n', 'NODE TYPE', 'ID', 'SERVED', 'AVG RESIDENCE');
            fprintf('————————————————————————————————————————————————————————————\n');

            for j = 1:numNodes
                node = obj.queueNodes{j};
                avgTime = totalTimePerNode(j) / countPerNode(j);
                
                if isa(node, 'generator'), label = 'Generator';
                elseif isa(node, 'queue'), label = 'Queue';
                elseif isa(node, 'server'), label = 'Server';
                else, label = 'Unknown'; end

                if countPerNode(j) > 0
                    fprintf('%-15s | %-4d | %-10d | %-15.2f\n', ...
                            label, node.id, countPerNode(j), avgTime);
                else
                    fprintf('%-15s | %-4d | %-10d | %-15s\n', ...
                            label, node.id, 0, 'N/A');
                end
            end
            fprintf('============================================================\n\n');
        end
    end
end

