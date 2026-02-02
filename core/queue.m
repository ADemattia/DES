classdef (Abstract) queue < handle
    %QUEUE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        id
        clock 

        previousServers % server precedenti (anche più di uno)
        previousGenerators % generatori precedenti (anche più di uno)
        destinationServer % server destinazione (unico)

        customerList  
        lengthQueue  % lunghezza coda corrente 
        
        overtakingFlag % la coda che permette i sorpassi di customer nel servizio?
        waitingFlag % i customer dal server sono persi o aspettano liberazione posti? 
              
        count  % numero di customer che sono stati in coda (non conta i persi) 
        averageLength  
        lostCustomer  % numero customer persi

 
    end
    
    methods
        % Costruttore su caratteristiche intrinseche
        function obj = queue(overtakingFlag, waitingFlag) 
            % istanziazioni di default
            obj.id = nodeIdGenerator.getId();
            obj.clock = 0; 
            obj.customerList = customer.empty(); 
            obj.lengthQueue = 0;  
            obj.count = 0; 
            obj.averageLength = 0; 
            obj.lostCustomer = 0; 

            % istanziazioni caratteristiche
            obj.overtakingFlag = overtakingFlag; 
            obj.waitingFlag = waitingFlag; 
        end
        
         % caraterizzazione Network locale

         function destinationServerAssignment(obj, destinationServer)
            obj.destinationServer = destinationServer;
         end

         function previousServersAssignment(obj, previousServers)
            obj.previousServers = previousServers;
         end

         function previousGeneratorsAssignment(obj, previousGenerators)
            obj.previousGenerators = previousGenerators;
         end

        % funzione gestore uscita

        function exitMangement(obj, customer)
            % ricerca customer 
              for i = length(obj.customerList):-1:1
                  if obj.customerList(i) == customer

                      % aggiornamento eventi customer 
                      customer.endTime(obj.id) = obj.clock; 

                      obj.customerList(i) = []; 
                      obj.lengthQueue = obj.lengthQueue - 1;
                      break;
                  end
              end
        end 

        function clockUpdate(obj, externalClock) % aggiorna clock e lunghezza media 

            % lunghezza coda attuale è tenuta da precedente evento salvato
            % in obj.clock 

            % aggiornamento lunghezza media coda
            clockDiff = externalClock - obj.clock;   
            totalLength = obj.averageLength * obj.clock + clockDiff * obj.lengthQueue;
            obj.averageLength = totalLength/externalClock;

            % aggiorna clock 
            obj.clock = externalClock; 

        end 


    end
    methods (Abstract)
        arrivalManagment(obj,customer)
        isAvailable = isQueueAvailable(obj) % è possibile rilasciare customer in coda da server? 
        clearQueue(obj)
    end
end


