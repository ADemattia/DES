classdef (Abstract) server < handle
    % server è la classe astratta che rappresenta i servitori sono
    % implementate alcune proprietà 
    
    properties
        id
        clock 
         
        destinationQueue  % coda arrivo (unica) 
        previousQueues  % code precedenti (anche più di una) 
        numPreviousQueues % numero code precedenti 
        selectedQueue % coda selezionata per servizio 
        
        
        numServer % numero server
        serverState % indicatori stato server (Free, Working, Waiting, Producing, etc.) 
        clockServer % tempi completamento per ogni server
        customerToServer % vettore customer serviti da server 
        
        serverDistribution % distribuzione tempi di completamento 
        eventServer % server associato al primo evento 
        
        notFullyOccupied % indica se è disponibile almeno un servitore (1)  
 
        exitWaitingList % lista customer in uscita 

        revenueFunction % funzione di revenue 
        revenue % revenue totali server 

        count % conteggio customer 

        % vettori per calcolo tempo in uno stato dei server
        timeInFree
        timeInWorking
        timeInWaiting
        timeInStuck

        clockPreviousState  % variabile ausiliaria 
    end
    
    methods
        % Costruttore su caratteristiche intrinseche
        function obj = server(numServer, serverDistribution, revenueFunction) 
            % istanziazioni di default
            obj.id = nodeIdGenerator.getId();
            obj.clock = inf; 
            obj.eventServer = NaN;
            obj.exitWaitingList = customer.empty(); 
            obj.notFullyOccupied = 1;
            obj.revenue = 0;
            obj.count = 0; 

            % istanziazioni caratteristiche 
              
            obj.numServer = numServer;  
            obj.customerToServer = repmat(customer(), obj.numServer, 1); % indica quale customer sta servendo il server 
            obj.serverState = repmat(serverState.Free, obj.numServer, 1); % classe enumerazione 
            obj.clockServer = inf(obj.numServer,1); 
            obj.serverDistribution = serverDistribution; 
            obj.revenueFunction = revenueFunction;

            obj.timeInFree = zeros(obj.numServer,1); 
            obj.timeInWorking = zeros(obj.numServer,1);
            obj.timeInWaiting = zeros(obj.numServer,1);
            obj.timeInStuck = zeros(obj.numServer,1);
            obj.clockPreviousState = zeros(numServer,1); % inizializzata a 0 

        end
        
        % caratterizzazione Network locale 

        function destinationQueueAssignment(obj, destinationQueue)
            obj.destinationQueue = destinationQueue; % coda uscita
        end

        function previousQueuesAssignment(obj, previousQueues)
            obj.previousQueues = previousQueues; % code precedenti 
            obj.numPreviousQueues = length(obj.previousQueues); 
        end


        % funzione ausiliaria per ricerca customer 
        function [found, serverId] = getServerFromCustomer(obj, targetCustomer)
            found = false; 
            serverId = [];

            for i = 1:length(obj.customerToServer)
                if isequal(obj.customerToServer(i), targetCustomer)
                    found = true; 
                    serverId = i;
                    return;
                end
            end
        end

        % COMMENTO : si potrebbe raffinare sul tipo di customer
        function exitAllowed = canExit(obj) % indica se un lavoro finito può uscire        
            if isempty(obj.exitWaitingList) 
                exitAllowed = false;
                return;
            end

            queue = obj.destinationQueue; 
            isAvailable = queue.isQueueAvailable(); % disponibilità coda 
            exitAllowed = isAvailable; % possibilità uscita da server
        end 
    
        % funzione ausiliaria per calcolo 
        function updateServerTime(obj, serverId, externalClock)

            % calcola il tempo trascorso dall'ultimo aggiornamento
            deltaT = externalClock - obj.clockPreviousState(serverId);
        
            % Identifica lo stato corrente del server
            switch obj.serverState(serverId)
                case serverState.Free
                    obj.timeInFree(serverId) = obj.timeInFree(serverId) + deltaT;
                case serverState.Working
                    obj.timeInWorking(serverId) = obj.timeInWorking(serverId) + deltaT;
                case serverState.Waiting
                    obj.timeInWaiting(serverId) = obj.timeInWaiting(serverId) + deltaT;
                case serverState.StuckInTraffic
                    obj.timeInStuck(serverId) = obj.timeInStuck(serverId) + deltaT;
            end
        
            % aggiorna il tempo precedente di stato
            obj.clockPreviousState(serverId) = externalClock;
        end
    end 

    methods (Abstract)
         [servicePossible, selectedCustomer] = checkAvailability(obj); % server può iniziare nuovo lavoro? 
         scheduleNextEvents(obj,customer,externalClock); % schedulazione nuovo completmento
         addWaiting(obj, externalClock);  % porta un customer nella coda dei wait
         exitCustomer(obj, externalClock); % fa uscire un customer 
         clearServer(obj); 
    end

end

