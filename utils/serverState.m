classdef serverState
    enumeration
        Free         % il server è libero
        Waiting      % il server ha completato il servizio, è in attesa di rilasciarlo nella coda
        Working      % sta servendo un cliente
        StuckInTraffic % il server ha finito il servizio, ma non può uscire poichè bloccato nel traffico 
    end
end

