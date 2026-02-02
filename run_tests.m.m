try
    run('queues/examples/classicTest.m');
    run('queues/examples/bufferTest.m');
    run('queues/examples/MM1Balking.m');
    run('queues/examples/revenueManagement.m');
    run('queues/examples/gasStation.m');


    run('epidemics/examples/SIRmodel.m');
    run('epidemics/examples/SIRSmodel.m');
    run('epidemics/examples/SImodel.m');

    run('games/examples/majorityGame.m');
    run('games/examples/publicGood.m');
    
    disp('All selected tests completed successfully!');
catch ME
    disp(['Error in file: ' ME.identifier]);
    exit(1); 
end
exit(0);