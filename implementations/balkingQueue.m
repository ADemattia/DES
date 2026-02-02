classdef balkingQueue < queue
    % coda balking con una certa quantità di posti (hardCapacity) occupati
    % deterministicamente e una certa quantità di posti (softCapacity) occupati
    % aletoriamente
    
    properties
        hardCapacity  
        
        softCapacity  

        totalCapacity  

        softCapacityDistribution % funzione randomica per accettazione posto soft 
    end
    
    methods
        function obj = balkingQueue(overtakingFlag, waitingFlag, hardCapacity, softCapacity, softCapacityDistribution)
            % chiamata a costruttore classe astratta
            obj@queue(overtakingFlag, waitingFlag); 

            % proprietà caratteristiche 
            obj.hardCapacity = hardCapacity; 
            obj.softCapacity = softCapacity; 
            obj.totalCapacity = obj.hardCapacity + obj.softCapacity; 

            obj.softCapacityDistribution = softCapacityDistribution;
        end

        function arrivalManagment(obj, customer)

            % aggiornamento path ed eventi customer 
            customer.path(end + 1) = obj.id;
            customer.startTime(obj.id) = obj.clock; 

            % politica di balking
            if obj.lengthQueue < obj.hardCapacity 
                % inserimento in coda 
                obj.customerList(end + 1) = customer;

                % aggiornamento conteggi 
                obj.lengthQueue = obj.lengthQueue + 1; 
                obj.count = obj.count + 1;  

            elseif obj.lengthQueue >= obj.hardCapacity && obj.lengthQueue < obj.totalCapacity % gestione posti soft
                    % campionamento decisione 
                    decision = obj.softCapacityDistribution(); 

                    if decision == 1
                        % inserimento in coda
                        obj.customerList(end + 1) = customer;

                        % aggiornamento conteggi 
                        obj.lengthQueue = obj.lengthQueue + 1; 
                        obj.count = obj.count + 1; 

                    else % decision == 0 
                        obj.lostCustomer = obj.lostCustomer + 1; 
                    end

            else % obj.lengthQueue == obj.totalCapacity - posti esauriti 
                obj.lostCustomer = obj.lostCustomer + 1; 
            end 
        end

        function isAvailable = isQueueAvailable(obj) 
            % sempre disponibile
            isAvailable = obj.waitingFlag;  
        end 
        
        % Pulitore statistiche 
        function clearQueue(obj)
            obj.clock = 0;
            obj.customerList = customer.empty();
            obj.lengthQueue = 0;
            obj.count = 0;
            obj.lostCustomer = 0;
            obj.averageLength = 0; 
        end

        function printStats(obj)
            fprintf('Lunghezza coda: %d\n', obj.lengthQueue);
            fprintf('Clienti persi: %d\n', obj.lostCustomer);
            fprintf('------------------------\n');
        end
    end
end

