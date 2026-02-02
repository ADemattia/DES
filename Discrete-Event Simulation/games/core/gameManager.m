classdef gameManager < handle    
    % gameManager: auxiliary class for monitoring and logging game dynamics
    % it stores the global strategy profile, tracks the state trajectory over 
    % time, and provides interactive visualization of the network evolution

    properties
        playersArry % cell array containing all players 
        profile % current global strategy profile (vector)
        actionsSpace % vector defining the general set of available strategies 
        trajectory  % cell array storing the history of profile states
        times % cell array storing the timestamps of profile updates
    end

    methods
        function obj = gameManager(playersArray, actionsSpace) 
            % constructor: initializes the shared profile and links players to this manager
            obj.playersArry = playersArray;
            numberPlayers = numel(playersArray);
            obj.actionsSpace = actionsSpace;

            obj.profile = zeros(1, numberPlayers);
            for pos = 1:numberPlayers
                obj.playersArry{pos}.managerAssignment(pos, obj); % link to manager  
                obj.profile(pos) = obj.playersArry{pos}.action; 
            end 

            obj.times = {0}; 
            obj.trajectory = {obj.profile}; 
        end

        function updateProfile(obj, managerId, action, externalClock)
            % updateProfile: records a strategy change and logs the new state in the trajectory
            obj.profile(managerId) = action; 
            obj.trajectory{end+1} = obj.profile; 
            obj.times{end+1} = externalClock; 
        end

        function displayStats(obj, adjacencyMatrix)
            % displayStats: creates an interactive UI to visualize strategy evolution
            numSteps = length(obj.trajectory);
            if numSteps == 0, error('The trajectory is empty.'); end
            
            fig = figure('Name', 'Network Dynamics Carousel', 'Color', 'w', ...
                         'WindowScrollWheelFcn', @obj.scrollCallback); 
            
            ax = axes('Parent', fig, 'Position', [0.1 0.2 0.65 0.7]);
            G = graph(adjacencyMatrix);
            
            p = plot(ax, G, 'Layout', 'force', 'MarkerSize', 10, 'LineWidth', 1.2);
            fixedX = p.XData;
            fixedY = p.YData;
            
            uniqueActions = sort(obj.actionsSpace);
            cmap = lines(numel(uniqueActions)); 
            
            updateFrame = @(step) obj.renderStep(step, ax, p, cmap, uniqueActions, fixedX, fixedY);
            
            sld = uicontrol('Parent', fig, 'Style', 'slider', ...
                'Units', 'normalized', 'Position', [0.2 0.05 0.6 0.05], ...
                'Min', 1, 'Max', numSteps, 'Value', 1, ...
                'SliderStep', [1/(numSteps-1), 10/(numSteps-1)], ...
                'Callback', @(src, ~) updateFrame(round(src.Value)));
            
            setappdata(fig, 'mySlider', sld);
            setappdata(fig, 'updateFunc', updateFrame);
            
            hold(ax, 'on');
            h = gobjects(length(uniqueActions), 1);
            for i = 1:length(uniqueActions)
                h(i) = plot(ax, NaN, NaN, 'o', 'MarkerFaceColor', cmap(i,:), ...
                     'MarkerEdgeColor', 'k', 'MarkerSize', 10, ...
                     'DisplayName', sprintf('Action %g', uniqueActions(i)));
            end
            
            lgd = legend(h, 'Location', 'northeastoutside', 'Box', 'on', 'FontSize', 10);
            title(lgd, 'Strategies');
            
            updateFrame(1);
        end

        function renderStep(obj, step, ax, plotHandle, cmap, uniqueActions, x, y)
            step = round(step);
            currentProfile = obj.trajectory{step};
            
            if iscell(obj.times)
                currentTime = obj.times{step};
            else
                currentTime = obj.times(step);
            end
            
            colorIndices = arrayfun(@(val) find(uniqueActions == val, 1), currentProfile);
            plotHandle.NodeColor = cmap(colorIndices, :);
            
            plotHandle.XData = x;
            plotHandle.YData = y;

            title(ax, {['\bf{Network Evolution} - Step: ', num2str(step), ' / ', num2str(length(obj.trajectory))], ...
                       ['\rm{Simulation Time: ', num2str(currentTime, '%.2f'), '}']}, 'FontSize', 12);
        end

        function scrollCallback(~, src, event)
            sld = getappdata(src, 'mySlider');
            updateFunc = getappdata(src, 'updateFunc');
            if isempty(sld), return; end
            
            newVal = sld.Value - event.VerticalScrollCount;
            newVal = max(sld.Min, min(sld.Max, newVal));
            
            sld.Value = newVal;
            updateFunc(newVal);
        end
    end
end