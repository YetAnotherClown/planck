--!nonstrict
local DependencyGraph = require(script.Parent.DependencyGraph)
local Pipeline = require(script.Parent.Pipeline)
local Phase = require(script.Parent.Phase)

local utils = require(script.Parent.utils)
local hooks = require(script.Parent.hooks)
local conditions = require(script.Parent.conditions)

local getSystem = utils.getSystem
local getSystemName = utils.getSystemName

local isPhase = utils.isPhase
local isPipeline = utils.isPipeline

local isValidEvent = utils.isValidEvent
local getEventIdentifier = utils.getEventIdentifier

-- Recent errors in Planks itself
local recentLogs = {}
local timeLastLogged = os.clock()

--- @type SystemFn ((U...) -> any)
--- @within Scheduler

--- @interface SystemTable
--- @within Scheduler
--- .system SystemFn<U...>
--- .phase Phase?
--- .[any] any

--- @type System SystemFn<U...> | SystemTable<U...>
--- @within Scheduler

--- @class Scheduler
---
--- An Object which handles scheduling Systems to run within different
--- Phases. The order of which Systems run will be defined either
--- implicitly by when it was added, or explicitly by tagging the system
--- with a Phase.
local Scheduler = {}
Scheduler.__index = Scheduler

Scheduler.Hooks = hooks.Hooks

--- @method addPlugin
--- @within Scheduler
--- @param plugin PlanckPlugin
---
--- Initializes a plugin with the scheduler, see the [Plugin Docs](/docs/plugins) for more information.
function Scheduler:addPlugin(plugin)
	plugin:build(self)
	table.insert(self._plugins, plugin)
	return self
end

function Scheduler:_addHook(hook, fn)
	assert(self._hooks[hook], `Unknown Hook: {hook}`)
	table.insert(self._hooks[hook], fn)
end

--- @method getDeltaTime
--- @within Scheduler
--- @return number
---
--- Returns the time since the system was ran last.
--- This must be used within a registered system.
function Scheduler:getDeltaTime()
	local systemFn = debug.info(2, "f")
	if not systemFn or not self._systemInfo[systemFn] then
		error(
			"Scheduler:getDeltaTime() must be used within a registered system"
		)
	end

	return self._systemInfo[systemFn].deltaTime or 0
end

-- Inspiration from https://github.com/matter-ecs/matter <3
function Scheduler:_handleLogs(systemInfo)
	if not systemInfo.timeLastLogged then
		systemInfo.timeLastLogged = os.clock()
	end

	if not systemInfo.recentLogs then
		systemInfo.recentLogs = {}
	end

	if os.clock() - systemInfo.timeLastLogged > 10 then
		systemInfo.timeLastLogged = os.clock()
		systemInfo.recentLogs = {}
	end

	local name = debug.info(systemInfo.system, "n")

	for _, logMessage in systemInfo.logs do
		if not systemInfo.recentLogs[logMessage] then
			task.spawn(error, logMessage, 0)
			warn(
				`Planck: Error occurred in system{string.len(name) > 0 and ` '{name}'` or ""}, this error will be ignored for 10 seconds`
			)
			systemInfo.recentLogs[logMessage] = true
		end
	end

	table.clear(systemInfo.logs)
end

function Scheduler:runSystem(system)
	if self:_canRun(system) == false then
		return
	end

	local systemInfo = self._systemInfo[system]
	local now = os.clock()

	systemInfo.deltaTime = now - (systemInfo.lastTime or now)
	systemInfo.lastTime = now

	if not self._thread then
		self._thread = coroutine.create(function()
			while true do
				local fn = coroutine.yield()
				self._yielded = true
				fn()
				self._yielded = false
			end
		end)

		coroutine.resume(self._thread)
	end

	local didYield = false

	local function systemCall()
		local function noYield()
			local success, err
			coroutine.resume(self._thread, function()
				success, err = xpcall(system, function(e)
					return debug.traceback(e)
				end, table.unpack(self._vargs))
			end)

			if success == false then
				didYield = true
				table.insert(systemInfo.logs, err)
				hooks.systemError(self, systemInfo, err)
				return
			end

			if self._yielded then
				didYield = true
				local source, line = debug.info(self._thread, 1, "sl")
				local errMessage = `{source}:{line}: System yielded`
				table.insert(
					systemInfo.logs,
					debug.traceback(self._thread, errMessage, 2)
				)
				hooks.systemError(
					self,
					systemInfo,
					debug.traceback(self._thread, errMessage, 2)
				)
			end
		end

		hooks.systemCall(self, "SystemCall", systemInfo, noYield)
	end

	local function inner()
		hooks.systemCall(self, "InnerSystemCall", systemInfo, systemCall)
	end

	local function outer()
		hooks.systemCall(self, "OuterSystemCall", systemInfo, inner)
	end

	if os.clock() - timeLastLogged > 10 then
		timeLastLogged = os.clock()
		recentLogs = {}
	end

	local success, err: string? = pcall(outer)
	if not success and not recentLogs[err] then
		task.spawn(error, err, 0)
		warn(
			`Planck: Error occurred while running hooks, this error will be ignored for 10 seconds`
		)
		hooks.systemError(
			self,
			systemInfo,
			`Error occurred while running hooks: {err}`
		)
		recentLogs[err] = true
	end

	if didYield then
		coroutine.close(self._thread)

		self._thread = coroutine.create(function()
			while true do
				local fn = coroutine.yield()
				self._yielded = true
				fn()
				self._yielded = false
			end
		end)

		coroutine.resume(self._thread)
	end

	self:_handleLogs(systemInfo)
end

function Scheduler:runPhase(phase)
	if self:_canRun(phase) == false then
		return
	end

	hooks.phaseBegan(self, phase)

	if not self._phaseToSystems[phase] then
		self._phaseToSystems[phase] = {}
	end

	for _, system in self._phaseToSystems[phase] do
		self:runSystem(system)
	end
end

function Scheduler:runPipeline(pipeline)
	if self:_canRun(pipeline) == false then
		return
	end

	local orderedList = pipeline.dependencyGraph:getOrderedList()
	assert(
		orderedList,
		`Pipeline {pipeline} contains a circular dependency, check it's Phases`
	)

	for _, phase in orderedList do
		self:runPhase(phase)
	end
end

function Scheduler:_canRun(dependent)
	local conditions = self._runIfConditions[dependent]

	if conditions then
		for _, runIf in conditions do
			if runIf(table.unpack(self._vargs)) == false then
				return false
			end
		end
	end

	return true
end

--- @method run
--- @within Scheduler
--- @param phase Phase
--- @return Scheduler
---
--- Runs all Systems tagged with the Phase in order.

--- @method run
--- @within Scheduler
--- @param pipeline Pipeline
--- @return Scheduler
---
--- Runs all Systems tagged with any Phase within the Pipeline in order.

--- @method run
--- @within Scheduler
--- @param system System
--- @return Scheduler
---
--- Runs the System, passing in the arguments of the Scheduler, `U...`.

function Scheduler:run(dependent)
	if not dependent then
		error("No dependent specified in Scheduler:run(_)")
	end

	self:runPipeline(Pipeline.Startup)

	if getSystem(dependent) then
		self:runSystem(dependent)
	elseif isPhase(dependent) then
		self:runPhase(dependent)
	elseif isPipeline(dependent) then
		self:runPipeline(dependent)
	else
		error("Unknown dependent passed into Scheduler:run(unknown)")
	end

	return self
end

--- @method runAll
--- @within Scheduler
--- @return Scheduler
---
--- Runs all Systems within order.
---
--- :::note
--- When you add a Pipeline or Phase with an event, it will be grouped
--- with other Pipelines/Phases on that event. Otherwise, it will be
--- added to the default group.
---
--- When not running systems on Events, such as with the `runAll` method,
--- the Default group will be ran first, and then each Event Group in the
--- order created.
---
--- Pipelines/Phases in these groups are still ordered by their dependencies
--- and by the order of insertion.
--- :::
function Scheduler:runAll()
	local orderedDefaults = self._defaultDependencyGraph:getOrderedList()
	assert(
		orderedDefaults,
		"Default Group contains a circular dependency, check your Pipelines/Phases"
	)

	for _, dependency in orderedDefaults do
		self:run(dependency)
	end

	for identifier, dependencyGraph in self._eventDependencyGraphs do
		local orderedList = dependencyGraph:getOrderedList()
		assert(
			orderedDefaults,
			`Event Group '{identifier}' contains a circular dependency, check your Pipelines/Phases`
		)
		for _, dependency in orderedList do
			self:run(dependency)
		end
	end

	return self
end

--- @method insert
--- @within Scheduler
--- @param phase Phase
--- @return Scheduler
---
--- Initializes the Phase within the Scheduler, ordering it implicitly by
--- setting it as a dependent of the previous Phase/Pipeline.

--- @method insert
--- @within Scheduler
--- @param pipeline Pipeline
--- @return Scheduler
---
--- Initializes the Pipeline and it's Phases within the Scheduler,
--- ordering the Pipeline implicitly by setting it as a dependent
--- of the previous Phase/Pipeline.

--- @method insert
--- @within Scheduler
--- @param phase Phase
--- @param instance Instance | EventLike
--- @param event string | EventLike
--- @return Scheduler
---
--- Initializes the Phase within the Scheduler, ordering it implicitly
--- by setting it as a dependent of the previous Phase/Pipeline, and
--- scheduling it to be ran on the specified event.
---
--- ```lua
--- local myScheduler = Scheduler.new()
---     :insert(myPhase, RunService, "Heartbeat")
--- ```

--- @method insert
--- @within Scheduler
--- @param pipeline Pipeline
--- @param instance Instance | EventLike
--- @param event string | EventLike
--- @return Scheduler
---
--- Initializes the Pipeline and it's Phases within the Scheduler,
--- ordering the Pipeline implicitly by setting it as a dependent of
--- the previous Phase/Pipeline, and scheduling it to be ran on the
--- specified event.
---
--- ```lua
--- local myScheduler = Scheduler.new()
---     :insert(myPipeline, RunService, "Heartbeat")
--- ```

function Scheduler:insert(dependency, instance, event)
	assert(
		isPhase(dependency) or isPipeline(dependency),
		"Unknown dependency passed to Scheduler:insert(unknown, _, _)"
	)

	if not instance then
		local dependencyGraph = self._defaultDependencyGraph
		dependencyGraph:insertBefore(dependency, self._defaultPhase)
	else
		assert(
			isValidEvent(instance, event),
			"Unknown instance/event passed to Scheduler:insert(_, instance, event)"
		)

		local dependencyGraph = self:_getEventDependencyGraph(instance, event)
		dependencyGraph:insert(dependency)
	end

	if isPhase(dependency) then
		self._phaseToSystems[dependency] = {}
		hooks.phaseAdd(self, dependency)
	end

	return self
end

--- @method insertAfter
--- @within Scheduler
--- @param phase Phase
--- @param after Phase | Pipeline
--- @return Scheduler
---
--- Initializes the Phase within the Scheduler, ordering it
--- explicitly by setting the after Phase/Pipeline as a dependent.

--- @method insertAfter
--- @within Scheduler
--- @param pipeline Pipeline
--- @param after Phase | Pipeline
--- @return Scheduler
---
--- Initializes the Pipeline and it's Phases within the Scheduler,
--- ordering the Pipeline explicitly by setting the after Phase/Pipeline
--- as a dependent.

function Scheduler:insertAfter(dependent, after)
	assert(
		isPhase(after) or isPipeline(after),
		"Unknown dependency passed in Scheduler:insertAfter(_, unknown)"
	)
	assert(
		isPhase(dependent) or isPipeline(dependent),
		"Unknown dependent passed in Scheduler:insertAfter(unknown, _)"
	)

	local dependencyGraph = self:_getGraphOfDependency(after)
	dependencyGraph:insertAfter(dependent, after)

	if isPhase(dependent) then
		self._phaseToSystems[dependent] = {}
		hooks.phaseAdd(self, dependent)
	end

	return self
end

--- @method insertBefore
--- @within Scheduler
--- @param phase Phase
--- @param before Phase | Pipeline
--- @return Scheduler
---
--- Initializes the Phase within the Scheduler, ordering it
--- explicitly by setting the before Phase/Pipeline as a dependency.

--- @method insertBefore
--- @within Scheduler
--- @param pipeline Pipeline
--- @param before Phase | Pipeline
--- @return Scheduler
---
--- Initializes the Pipeline and it's Phases within the Scheduler,
--- ordering the Pipeline explicitly by setting the before Phase/Pipeline
--- as a dependency.

function Scheduler:insertBefore(dependent, before)
	assert(
		isPhase(before) or isPipeline(before),
		"Unknown dependency passed in Scheduler:insertBefore(_, unknown)"
	)
	assert(
		isPhase(dependent) or isPipeline(dependent),
		"Unknown dependent passed in Scheduler:insertBefore(unknown, _)"
	)

	local dependencyGraph = self:_getGraphOfDependency(before)
	dependencyGraph:insertBefore(dependent, before)

	if isPhase(dependent) then
		self._phaseToSystems[dependent] = {}
		hooks.phaseAdd(self, dependent)
	end

	return self
end

--- @method addSystems
--- @within Scheduler
--- @param systems System
--- @param phase Phase?
---
--- Adds the System to the Scheduler, scheduling it to be ran
--- implicitly within the provided Phase or on the default Main phase.
function Scheduler:addSystem(system, phase)
	local systemFn = getSystem(system)

	if not systemFn then
		error("Unknown system passed to Scheduler:addSystem(unknown, phase?)")
	end

	local name = getSystemName(systemFn)
	if type(system) == "table" and system.name then
		name = system.name
	end

	local systemInfo = {
		system = systemFn,
		phase = phase,
		name = name,
		logs = {},
	}

	if not phase then
		if type(system) == "table" and system.phase then
			systemInfo.phase = system.phase
		else
			systemInfo.phase = self._defaultPhase
		end
	end

	self._systemInfo[systemFn] = systemInfo

	if not self._phaseToSystems[systemInfo.phase] then
		self._phaseToSystems[systemInfo.phase] = {}
	end

	table.insert(self._phaseToSystems[systemInfo.phase], systemFn)

	hooks.systemAdd(self, systemInfo)

	if type(system) == "table" and system.runConditions then
		for _, condition in system.runConditions do
			self:addRunCondition(systemFn, condition)
		end
	end

	return self
end

--- @method addSystems
--- @within Scheduler
--- @param systems { System }
--- @param phase Phase?
---
--- Adds the Systems to the Scheduler, scheduling them to be ran
--- implicitly within the provided Phase or on the default Main phase.
function Scheduler:addSystems(systems, phase)
	if type(systems) ~= "table" then
		error("Unknown systems passed to Scheduler:addSystems(unknown, phase?)")
	end

	local foundSystem = false
	local n = 0

	for _, system in systems do
		n += 1
		if getSystem(system) then
			foundSystem = true
			self:addSystem(system, phase)
		end
	end

	if n == 0 then
		error("Empty table passed to Scheduler:addSystems({ }, phase?)")
	end

	if not foundSystem then
		error(
			"Unknown table passed to Scheduler:addSystems({ unknown }, phase?)"
		)
	end

	return self
end

--- @method editSystem
--- @within Scheduler
--- @param system System
--- @param newPhase Phase
---
--- Changes the Phase that this system is scheduled on.
function Scheduler:editSystem(system, newPhase)
	local systemFn = getSystem(system)
	local systemInfo = self._systemInfo[systemFn]
	assert(
		systemInfo,
		"Attempt to remove a non-exist system in Scheduler:removeSystem(_)"
	)

	assert(
		newPhase and self._phaseToSystems[newPhase] ~= nil or true,
		"Phase never initialized before using Scheduler:editSystem(_, Phase)"
	)

	local systems = self._phaseToSystems[systemInfo.phase]

	local index = table.find(systems, systemFn)
	assert(index, "Unable to find system within phase")

	table.remove(systems, index)

	if not self._phaseToSystems[newPhase] then
		self._phaseToSystems[newPhase] = {}
	end
	table.insert(self._phaseToSystems[newPhase], systemFn)

	systemInfo.phase = newPhase
	return self
end

function Scheduler:_removeCondition(dependent, condition)
	self._runIfConditions[dependent] = nil

	for _, _conditions in self._runIfConditions do
		if table.find(_conditions, condition) then
			return
		end
	end

	conditions.cleanupCondition(condition)
end

--- @method removeSystem
--- @within Scheduler
--- @param system System
---
--- Removes the System from the Scheduler.
function Scheduler:removeSystem(system)
	local systemFn = getSystem(system)
	local systemInfo = self._systemInfo[systemFn]
	assert(
		systemInfo,
		"Attempt to remove a non-exist system in Scheduler:removeSystem(_)"
	)

	local systems = self._phaseToSystems[systemInfo.phase]

	local index = table.find(systems, systemFn)
	assert(index, "Unable to find system within phase")

	table.remove(systems, index)
	self._systemInfo[systemFn] = nil

	if self._runIfConditions[system] then
		for _, condition in self._runIfConditions[system] do
			self:_removeCondition(system, condition)
		end

		self._runIfConditions[system] = nil
	end

	hooks.systemRemove(self, systemInfo)

	return self
end

--- @method replaceSystem
--- @within Scheduler
--- @param old System
--- @param new System
---
--- Replaces the System with a new System.
function Scheduler:replaceSystem(old, new)
	local oldSystemFn = getSystem(old)
	local oldSystemInfo = self._systemInfo[oldSystemFn]
	assert(
		oldSystemInfo,
		"Attempt to replace a non-existent system in Scheduler:replaceSystem(unknown, _)"
	)

	local newSystemFn = getSystem(new)
	assert(
		newSystemFn,
		"Attempt to pass non-system in Scheduler:replaceSystem(_, unknown)"
	)

	local systems = self._phaseToSystems[oldSystemInfo.phase]

	local index = table.find(systems, oldSystemFn)
	assert(index, "Unable to find system within phase")

	table.remove(systems, index)
	table.insert(systems, index, newSystemFn)

	local copy = table.clone(oldSystemInfo)

	oldSystemInfo.system = newSystemFn
	oldSystemInfo.name = getSystemName(newSystemFn)

	hooks.systemReplace(self, copy, oldSystemInfo)

	self._systemInfo[newSystemFn] = self._systemInfo[oldSystemFn]
	self._systemInfo[oldSystemFn] = nil

	return self
end

--- @method addRunCondition
--- @within Scheduler
--- @param system System
--- @param fn (U...) -> boolean
---
--- Adds a Run Condition which the Scheduler will check before
--- this System is ran.

--- @method addRunCondition
--- @within Scheduler
--- @param phase Phase
--- @param fn (U...) -> boolean
---
--- Adds a Run Condition which the Scheduler will check before
--- any Systems within this Phase are ran.

--- @method addRunCondition
--- @within Scheduler
--- @param pipeline Pipeline
--- @param fn (U...) -> boolean
---
--- Adds a Run Condition which the Scheduler will check before
--- any Systems within any Phases apart of this Pipeline are ran.\

function Scheduler:addRunCondition(dependent, fn)
	local system = getSystem(dependent)
	if system then
		dependent = system
	end

	assert(
		system or isPhase(dependent) or isPipeline(dependent),
		"Attempt to pass unknown dependent into Scheduler:addRunCondition(unknown, _)"
	)

	if not self._runIfConditions[dependent] then
		self._runIfConditions[dependent] = {}
	end

	table.insert(self._runIfConditions[dependent], fn)

	return self
end

function Scheduler:_addBuiltins()
	self._defaultPhase = Phase.new("Default")
	self._defaultDependencyGraph = DependencyGraph.new()

	self._defaultDependencyGraph:insert(Pipeline.Startup)
	self._defaultDependencyGraph:insert(self._defaultPhase)

	self:addRunCondition(Pipeline.Startup, conditions.runOnce())
	for _, phase in Pipeline.Startup.dependencyGraph.nodes do
		self:addRunCondition(phase, conditions.runOnce())
	end
end

function Scheduler:_scheduleEvent(instance, event)
	local connect = utils.getConnectFunction(instance, event)
	assert(
		connect,
		"Couldn't connect to event as no valid connect methods were found! Ensure the passed event has a 'Connect' or an 'on' method!"
	)

	local identifier = getEventIdentifier(instance, event)

	local dependencyGraph = DependencyGraph.new()

	local callback = function()
		local orderedList = dependencyGraph:getOrderedList()

		if orderedList == nil then
			local err =
				`Event Group '{identifier}' contains a circular dependency, check your Pipelines/Phases`
			if not recentLogs[err] then
				task.spawn(error, err, 0)
				warn(
					`Planck: Error occurred while running event, this error will be ignored for 10 seconds`
				)
				recentLogs[err] = true
			end
		end

		for _, dependency in orderedList do
			self:run(dependency)
		end
	end

	self._connectedEvents[identifier] = connect(callback)
	self._eventDependencyGraphs[identifier] = dependencyGraph
end

function Scheduler:_getEventDependencyGraph(instance, event)
	local identifier = getEventIdentifier(instance, event)

	if not self._connectedEvents[identifier] then
		self:_scheduleEvent(instance, event)
	end

	return self._eventDependencyGraphs[identifier]
end

function Scheduler:_getGraphOfDependency(dependency)
	if table.find(self._defaultDependencyGraph.nodes, dependency) then
		return self._defaultDependencyGraph
	end

	for _, dependencyGraph in self._eventDependencyGraphs do
		if table.find(dependencyGraph.nodes, dependency) then
			return dependencyGraph
		end
	end

	error("Dependency does not belong to a DependencyGraph")
end

--- @within Scheduler
---
--- Disconnects all events, closes all threads, and performs
--- other cleanup work.
---
--- :::danger
--- Only use this if you intend to not use the associated
--- Scheduler anymore. It will not work as intended.
---
--- You should dereference the scheduler object so that
--- it may be garbage collected.
--- :::
---
--- :::warning
--- If you're creating a "throwaway" scheduler, you should
--- not add plugins like Jabby or the Matter Debugger to it.
--- These plugins are unable to properly be cleaned up, use
--- them with caution.
--- :::
function Scheduler:cleanup()
	for _, connection in self._connectedEvents do
		utils.disconnectEvent(connection)
	end

	for _, plugin in self._plugins do
		if plugin.cleanup then
			plugin:cleanup()
		end
	end

	if self._thread then
		coroutine.close(self._thread)
	end

	for _, _conditions in self._runIfConditions do
		for _, condition in _conditions do
			conditions.cleanupCondition(condition)
		end
	end
end

--- @function new
--- @within Scheduler
--- @param args U...
---
--- Creates a new Scheduler, the args passed will be passed to
--- any System anytime it is ran by the Scheduler.
function Scheduler.new(...)
	local self = {}

	self._hooks = {}

	self._vargs = { ... }

	self._eventDependencyGraphs = {}
	self._connectedEvents = {}

	self._phaseToSystems = {}
	self._systemInfo = {}

	self._runIfConditions = {}

	self._plugins = {}

	setmetatable(self, Scheduler)

	for _, hookName in hooks.Hooks do
		if not self._hooks[hookName] then
			self._hooks[hookName] = {}
		end
	end

	self:_addBuiltins()

	return self
end

return Scheduler
