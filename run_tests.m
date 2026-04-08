setup;
set(0, 'DefaultFigureVisible', 'off'); % headless mode for CI

try
    % Queue tests
    run('queues/examples/classicTest.m');
    run('queues/examples/bufferTest.m');
    run('queues/examples/MM1Balking.m');
    run('queues/examples/revenueManagment.m');
    run('queues/examples/gasStation.m');

    % Epidemic tests
    run('epidemics/examples/SIRmodel.m');
    run('epidemics/examples/SIRSmodel.m');
    run('epidemics/examples/SImodel.m');

    % Game tests (skip visualization: no display in CI)
    run('games/examples/majorityGame.m');
    run('games/examples/publicGood.m');

    disp('All tests completed successfully!');
catch ME
    fprintf('Error: %s\n', ME.message);
    fprintf('File: %s\n', ME.stack(1).file);
    fprintf('Line: %d\n', ME.stack(1).line);
    exit(1);
end
exit(0);
