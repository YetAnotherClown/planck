local DependencyGraph = require(script.Parent.DependencyGraph)
local Pipeline = require(script.Parent.Pipeline)
local Phase = require(script.Parent.Phase)

type DependencyGraph<T> = DependencyGraph.DependencyGraph<T>
type Pipeline = Pipeline.Pipeline
type Phase = Phase.Phase

local utils = require(script.Parent.utils)
local conditions = require(script.Parent.conditions)

local getSystem = utils.getSystem
local getSystemName = utils.getSystemName
local getEventIdentifier = utils.getEventIdentifier

local isSystem = utils.isSystem
local isPhase = utils.isPhase
local isPipeline = utils.isPipeline
local isValidEvent = utils.isValidEvent

type GenericTable = utils.GenericTable
type SignalLike<U...> = utils.SignalLike<U...>
type ConnectionLike = utils.ConnectionLike
type ConnectFn<T, U...> = utils.ConnectFn<T, U...>
type Callback<U...> = utils.Callback<U...>

export type SystemFn<U...> = utils.SystemFn<U...>
export type InitializerSystemFn<U...> = utils.InitializerSystemFn<U...>
export type InitializerResult<U...> = utils.InitializerResult<U...>

type InternalSystem<U...> = utils.InternalSystem<U...>
export type System<U...> = utils.System<U...>
export type SystemTable<U...> = utils.SystemTable<U...>

type Condition<U...> = conditions.Condition<U...>

type Vec<T> = { T }
type Map<K, V> = { [K]: V }

type BasePlugin<T> = {
	build: (self: T, scheduler: Scheduler<...unknown>) -> (),
	new: (...any) -> T,
}

type PluginImpl = {
	__index: PluginImpl,
	build: (self: Plugin, scheduler: Scheduler<...unknown>) -> (),
	cleanup: ((self: Plugin) -> ())?,
	new: (...any) -> Plugin,
}

type Plugin = setmetatable<{}, PluginImpl>

export type SystemInfo<U...> = {
	system: InternalSystem<U...>,
	run: InternalSystem<U...>,
	cleanup: SystemFn<U...>?,
	initialized: boolean,
	name: string,
	deltaTime: number?,
	lastTime: number?,
	timeLastLogged: number?,
	recentLogs: { [string]: boolean }?,
	logs: { string },
	phase: Phase,
}

type Dependent<U...> = Pipeline | Phase | System<U...>
type Dependency = Pipeline | Phase

-- Recent errors in Planks itself
local recentLogs = {}
local timeLastLogged = os.clock()

--- @class Scheduler
---
--- An Object which handles scheduling Systems to run within different
--- Phases. The order of which Systems run will be defined either
--- implicitly by when it was added, or explicitly by tagging the system
--- with a Phase.
local Scheduler = {}
Scheduler.__index = Scheduler

--- @method addPlugin
--- @within Scheduler
--- @param plugin PlanckPlugin
---
--- Initializes a plugin with the scheduler, see the [Plugin Docs](/docs/plugins) for more information.
function Scheduler.addPlugin<T, U...>(
	self: Scheduler<U...>,
	plugin: setmetatable<{}, BasePlugin<T>>
)
	local _plugin = plugin :: Plugin
	_plugin:build(self)

	table.insert(self._plugins, _plugin)
	return self
end

type PartialHookContext = {
	scheduler: Scheduler<...unknown>,
}

type Hook<T> = {
	__T: T,
}

type Hooks = {
	SystemAdd: Hook<(context: SystemHookContext) -> ()>,
	SystemRemove: Hook<(context: SystemHookContext) -> ()>,
	SystemReplace: Hook<(context: SystemReplaceContext) -> ()>,
	SystemCleanup: Hook<(context: SystemErrorContext) -> ()>,
	SystemError: Hook<(context: SystemErrorContext) -> ()>,
	SystemTriedRun: Hook<(context: SystemHookContext) -> ()>,

	OuterSystemCall: Hook<(context: SystemCallContext) -> SystemCallHookFn>,
	InnerSystemCall: Hook<(context: SystemCallContext) -> SystemCallHookFn>,
	SystemCall: Hook<(context: SystemCallContext) -> SystemCallHookFn>,

	PhaseAdd: Hook<(context: PhaseContext) -> ()>,
	PhaseBegan: Hook<(context: PhaseContext) -> ()>,
}

--- @prop Hooks { [string]: string }
--- @within Scheduler
--- @since 0.3.0
---
--- See [creating plugins](/docs/plugins/creating).
Scheduler.Hooks = (
	{
		SystemAdd = "SystemAdd",
		SystemRemove = "SystemRemove",
		SystemReplace = "SystemReplace",
		SystemCleanup = "SystemCleanup",
		SystemError = "SystemError",
		SystemTriedRun = "SystemTriedRun",

		OuterSystemCall = "OuterSystemCall",
		InnerSystemCall = "InnerSystemCall",
		SystemCall = "SystemCall",

		PhaseAdd = "PhaseAdd",
		PhaseBegan = "PhaseBegan",
	} :: any
) :: Hooks

type HookId = keyof<typeof(Scheduler.Hooks)>

--- @within Scheduler
--- @since 0.3.0
---
--- Allows for registering hooks, see [creating plugins](/docs/plugins/creating).
Scheduler.addHook = function<T, U...>(self: Scheduler<U...>, hook: Hook<T>, fn: T)
	local hookId: HookId = hook :: any

	assert(self._hooks[hookId], `Unknown Hook: {hook}`)
	table.insert(self._hooks[hookId], fn)
end

--- @method _addHook
--- @within Scheduler
--- @deprecated 0.3.0 -- Use `Scheduler:addHook()` instead
--- @private
---
--- Internal method for adding hooks maintained for backwards compatibility.
--- Use [Scheduler:addHook] instead.
Scheduler._addHook = Scheduler.addHook

local function callHooks<U...>(
	hooks: Vec<(PartialHookContext) -> unknown>,
	info: PartialHookContext
)
	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end
end

export type SystemHookContext = PartialHookContext & {
	system: SystemInfo<...any>,
}

function Scheduler._systemAdd<U...>(
	self: Scheduler<U...>,
	systemInfo: SystemInfo<U...>
)
	local context = {
		scheduler = self,
		system = systemInfo,
	}

	callHooks(self._hooks["SystemAdd"], context)
end

function Scheduler._systemRemove<U...>(
	self: Scheduler<U...>,
	systemInfo: SystemInfo<U...>
)
	local context: SystemHookContext = {
		scheduler = self,
		system = systemInfo :: any,
	}

	callHooks(self._hooks["SystemRemove"], context)
end

export type SystemReplaceContext = PartialHookContext & {
	new: SystemInfo<...any>,
	old: SystemInfo<...any>,
}

function Scheduler._systemReplace<U...>(
	self: Scheduler<U...>,
	oldSystemInfo: SystemInfo<U...>,
	newSystemInfo: SystemInfo<U...>
)
	local context: SystemReplaceContext = {
		scheduler = self,
		new = newSystemInfo :: any,
		old = oldSystemInfo :: any,
	}

	callHooks(self._hooks["SystemReplace"], context)
end

export type SystemErrorContext = PartialHookContext & {
	system: SystemInfo<...any>,
	error: unknown?,
}

function Scheduler._systemCleanup<E, U...>(
	self: Scheduler<U...>,
	systemInfo,
	cleanupError: E?
)
	local context: SystemErrorContext = {
		scheduler = self,
		system = systemInfo,
		error = cleanupError,
	}

	callHooks(self._hooks["SystemCleanup"], context)
end

function Scheduler._systemError<E, U...>(self: Scheduler<U...>, systemInfo, err: E)
	local context: SystemErrorContext = {
		scheduler = self,
		system = systemInfo,
		error = err,
	}

	callHooks(self._hooks["SystemError"], context)
end

function Scheduler._systemTriedRun<T, U...>(self: Scheduler<U...>, systemInfo)
	local context: SystemHookContext = {
		scheduler = self,
		system = systemInfo,
	}

	callHooks(self._hooks["SystemTriedRun"], context)
end

type SystemHookId = "OuterSystemCall" | "InnerSystemCall" | "SystemCall"

type SystemCallHookFn = () -> ()
type SystemCallCallback = (SystemCallContext) -> SystemCallHookFn
export type SystemCallContext = PartialHookContext & {
	system: SystemInfo<...any>,
	nextFn: SystemCallHookFn,
}

function Scheduler._systemCall<T, U...>(
	self: Scheduler<U...>,
	hookName: SystemHookId,
	systemInfo: SystemInfo<U...>,
	nextFn: SystemCallHookFn
)
	for _, hook in self._hooks[hookName] :: Vec<SystemCallCallback> do
		local context: SystemCallContext = {
			scheduler = self,
			system = systemInfo :: any,
			nextFn = nextFn,
		}

		nextFn = hook(context)

		if not nextFn then
			local source, line = debug.info(hook, "sl")
			warn(
				`{source}:{line}: Expected 'SystemCall' hook to return a function`
			)
		end
	end

	nextFn()
end

export type PhaseContext = PartialHookContext & {
	phase: Phase,
}

function Scheduler._phaseAdd<U...>(self: Scheduler<U...>, phase: Phase)
	local context: PhaseContext = {
		scheduler = self,
		phase = phase,
	}

	callHooks(self._hooks["PhaseAdd"], context)
end

function Scheduler._phaseBegan<U...>(self: Scheduler<U...>, phase: Phase)
	local context: PhaseContext = {
		scheduler = self,
		phase = phase,
	}

	callHooks(self._hooks["PhaseBegan"], context)
end

--- @method getDeltaTime
--- @within Scheduler
--- @return number
---
--- Returns the time since the system was ran last.
--- This must be used within a registered system.
function Scheduler.getDeltaTime<U...>(self: Scheduler<U...>)
	if self._currentSystem then
		return self._currentSystem.deltaTime or 0
	end

	local systemFn = debug.info(2, "f")
	if not systemFn or not self._systemInfo[systemFn] then
		error(
			"Scheduler:getDeltaTime() must be used within a registered system"
		)
	end

	return self._systemInfo[systemFn].deltaTime or 0
end

-- Inspiration from https://github.com/matter-ecs/matter <3
function Scheduler._handleLogs<U...>(_: Scheduler<U...>, systemInfo: SystemInfo<U...>)
	if not systemInfo.timeLastLogged then
		systemInfo.timeLastLogged = os.clock()
	end

	if not systemInfo.recentLogs then
		systemInfo.recentLogs = {}
	end

	-- selene: allow(incorrect_standard_library_use)
	do
		assert(systemInfo.timeLastLogged)
		assert(systemInfo.recentLogs)
	end

	if os.clock() - systemInfo.timeLastLogged > 10 then
		systemInfo.timeLastLogged = os.clock()
		systemInfo.recentLogs = {}
	end

	local name = systemInfo.name

	for _, logMessage in systemInfo.logs do
		if not systemInfo.recentLogs[logMessage] then
			-- LUAU FUTURE: Inference bug
			task.spawn<<(string, number)>>(error, logMessage, 0)
			warn(
				`Planck: Error occurred in system{string.len(name) > 0 and ` '{name}'` or ""}, this error will be ignored for 10 seconds`
			)
			systemInfo.recentLogs[logMessage] = true
		end
	end

	table.clear(systemInfo.logs)
end

function Scheduler.runSystem<U...>(
	self: Scheduler<U...>,
	system: InternalSystem<U...>,
	justInitialized: boolean
)
	local systemInfo = self._systemInfo[system]
	local now = os.clock()

	if not systemInfo then
		error(
			"Attempted to run a non-registered system, make sure it is added to the Scheduler"
		)
	end

	if justInitialized ~= true then
		if self:_canRun(system) == false then
			self:_systemTriedRun(systemInfo)
			return
		end

		systemInfo.deltaTime = now - (systemInfo.lastTime or now)
	end

	systemInfo.lastTime = now
	self._currentSystem = systemInfo

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

	-- selene: allow(incorrect_standard_library_use)
	assert(self._thread)

	local didYield = false
	local hasSystem = false

	local function systemCall()
		local function noYield()
			local success, errOrSys, cleanup

			coroutine.resume(self._thread, function()
				success, errOrSys, cleanup = xpcall(function()
					return systemInfo.run(table.unpack(self._vargs))
				end, function(e: string)
					return debug.traceback(e)
				end)
			end)

			if success == false then
				didYield = true

				-- selene: allow(incorrect_standard_library_use)
				assert(errOrSys)
				table.insert(systemInfo.logs, errOrSys)
				self:_systemError(systemInfo, errOrSys)

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

				self:_systemError(
					systemInfo,
					debug.traceback(self._thread, errMessage, 2)
				)
				return
			end

			if not systemInfo.initialized then
				if errOrSys == nil and cleanup == nil then
					systemInfo.initialized = true
					return
				end

				if type(errOrSys) == "function" then
					systemInfo.run = errOrSys
					systemInfo.initialized = true
					if type(cleanup) == "function" then
						systemInfo.cleanup = cleanup
					end

					hasSystem = true
					return
				end

				if type(errOrSys) == "table" then
					hasSystem = type(errOrSys.system) == "function"
					local hasCleanup = type(errOrSys.cleanup) == "function"

					if hasSystem or hasCleanup then
						if hasSystem then
							systemInfo.run = errOrSys.system
						end

						if hasCleanup then
							systemInfo.cleanup = errOrSys.cleanup
						end

						systemInfo.initialized = true
						return
					end
				end

				local err = `System '{systemInfo.name}' initializer returned invalid type. `
					.. "Expected: function, {system?, cleanup?}, or (function, function). "
					.. `Got: {typeof(errOrSys)}, {typeof(cleanup)}`
				table.insert(systemInfo.logs, err)
				self:_systemError(systemInfo, err)
				systemInfo.initialized = true
			end
		end

		self:_systemCall("SystemCall", systemInfo, noYield)
	end

	local function inner()
		self:_systemCall("InnerSystemCall", systemInfo, systemCall)
	end

	local function outer()
		self:_systemCall("OuterSystemCall", systemInfo, inner)
	end

	if os.clock() - timeLastLogged > 10 then
		timeLastLogged = os.clock()
		recentLogs = {}
	end

	-- LUAU FUTURE: Better types for pcalls
	local success, err: string? = pcall(outer :: any)
	if not success and not recentLogs[err] then
		-- LUAU FUTURE: Inference bug
		task.spawn<<(string?, number)>>(error, err, 0)
		warn(
			`Planck: Error occurred while running hooks, this error will be ignored for 10 seconds`
		)
		self:_systemError(
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
	self._currentSystem = nil

	if hasSystem and justInitialized ~= true then
		self:runSystem(system, true)
	end
end

function Scheduler.runPhase<U...>(self: Scheduler<U...>, phase: Phase)
	if self:_canRun(phase) == false then
		return
	end

	self:_phaseBegan(phase)

	if not self._phaseToSystems[phase] then
		self._phaseToSystems[phase] = {}
	end

	for _, system in self._phaseToSystems[phase] do
		self:runSystem(system, false)
	end
end

function Scheduler.runPipeline<U...>(self: Scheduler<U...>, pipeline: Pipeline)
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

function Scheduler._canRun<U...>(self: Scheduler<U...>, dependent: Dependent<U...>)
	local runConditions = self._runIfConditions[dependent :: any]

	if runConditions then
		for _, runIf in runConditions do
			if runIf and not runIf(table.unpack(self._vargs)) then
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
function Scheduler.run<U...>(self: Scheduler<U...>, dependent: Dependent<U...>)
	assert(
		dependent ~= nil,
		"No dependent specified in Scheduler:run(dependent?)"
	)

	self:runPipeline(Pipeline.Startup)

	if isSystem(dependent) then
		self:runSystem(dependent :: any, false)
	elseif isPhase(dependent) then
		self:runPhase(dependent :: any)
	elseif isPipeline(dependent) then
		self:runPipeline(dependent :: any)
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
function Scheduler.runAll<U...>(self: Scheduler<U...>)
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
			orderedList,
			`Event Group '{identifier}' contains a circular dependency, check your Pipelines/Phases`
		)

		for _, dependency in orderedList do
			self:run(dependency)
		end
	end

	return self
end

type InsertFn =
	& (<U...>(
		self: Scheduler<U...>,
		dependency: Phase | Pipeline
	) -> Scheduler<U...>)
	-- RBXScriptSignal & nil
	& (<U...>(
		self: Scheduler<U...>,
		dependency: Phase | Pipeline,
		signal: RBXScriptSignal<U...>
	) -> Scheduler<U...>)
	-- Instance & RBXScriptSignal
	-- Instance & string
	& (<U...>(
		self: Scheduler<U...>,
		dependency: Phase | Pipeline,
		instance: Instance,
		event: RBXScriptSignal<U...> | string
	) -> Scheduler<U...>)
	-- SignalLike & nil
	& (<U...>(
		self: Scheduler<U...>,
		dependency: Phase | Pipeline,
		signal: SignalLike<U...>
	) -> Scheduler<U...>)
	-- table & string
	& (<U...>(
		self: Scheduler<U...>,
		dependency: Phase | Pipeline,
		table: GenericTable,
		event: string
	) -> Scheduler<U...>)
	-- table & connectable method
	& (<T, U...>(
		self: Scheduler<U...>,
		dependency: Phase | Pipeline,
		instance: GenericTable,
		connectMethod: (GenericTable, Callback<U...>, ...any) -> T
	) -> Scheduler<U...>)
	-- connectable function
	& (<T, U...>(
		self: Scheduler<U...>,
		dependency: Phase | Pipeline,
		connectFn: (Callback<U...>, ...any) -> T
	) -> Scheduler<U...>)

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
local insertFn: InsertFn = function<U...>(
	self: Scheduler<U...>,
	dependency: Phase | Pipeline,
	instance: any,
	event: any
): Scheduler<U...>
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
		self._phaseToSystems[dependency :: Phase] = {}
		self:_phaseAdd(dependency :: Phase)
	end

	return self
end

Scheduler.insert = insertFn

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
function Scheduler.insertAfter<U...>(
	self: Scheduler<U...>,
	dependent: Dependency,
	after: Dependency
)
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
		self._phaseToSystems[dependent :: Phase] = {}
		self:_phaseAdd(dependent :: Phase)
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
function Scheduler.insertBefore<U...>(
	self: Scheduler<U...>,
	dependent: Dependency,
	before: Dependency
)
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
		self._phaseToSystems[dependent :: Phase] = {}
		self:_phaseAdd(dependent :: Phase)
	end

	return self
end

--- @method addSystem
--- @within Scheduler
--- @param system System
--- @param phase Phase?
--- @return Scheduler
---
--- Adds the System to the Scheduler, scheduling it to be ran
--- implicitly within the provided Phase or on the default Main phase.
---
--- **Initializer Systems**: Systems can optionally return a function on their
--- first execution, which becomes the runtime system. This allows one-time
--- setup logic without creating separate initialization phases.
---
--- ```lua
--- local function renderSystem(world, state)
---     -- This runs once on first execution
---     local renderables = world:query(Transform, Model):cached()
---
---     -- This runs on each subsequent execution
---     return function(world, state)
---         for id, transform, model in renderables do
---             render(transform, model)
---         end
---     end, function()
---         -- Optional cleanup logic runs on removeSystem
---     end
--- end
--- ```
function Scheduler.addSystem<U...>(
	self: Scheduler<U...>,
	system: System<U...>,
	phase: Phase?
)
	local systemFn = getSystem(system)
	assert(systemFn, "Unknown system passed to Scheduler:addSystem(unknown, _)")

	local name = getSystemName(system)

	local scheduledPhase
	if phase then
		scheduledPhase = phase
	elseif type(system) == "table" and system.phase then
		scheduledPhase = system.phase
	else
		scheduledPhase = self._defaultPhase
	end

	local systemInfo: SystemInfo<U...> = {
		system = systemFn,
		run = systemFn,
		cleanup = nil,
		phase = scheduledPhase,
		name = name,
		logs = {},
		initialized = false,
	}

	self._systemInfo[systemFn] = systemInfo :: any

	if not self._phaseToSystems[systemInfo.phase] then
		self._phaseToSystems[systemInfo.phase] = {}
	end

	table.insert(
		self._phaseToSystems[systemInfo.phase],
		systemFn :: InternalSystem<...any>
	)

	self:_systemAdd(systemInfo)

	if type(system) == "table" and system.runConditions then
		for _, condition in system.runConditions do
			condition = if typeof(condition) == "table"
				then condition[1]
				else condition
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
function Scheduler.addSystems<U...>(
	self: Scheduler<U...>,
	systems: { System<U...> },
	phase: Phase?
)
	assert(
		type(systems) == "table",
		"Unknown value passed to Scheduler:addSystems(unknown, _). This value should be an array."
	)

	local foundSystem = false
	local n = 0

	for _, system in systems do
		n += 1
		if getSystem(system) then
			foundSystem = true
			self:addSystem(system, phase)
		end
	end

	assert(n ~= 0, "Empty table passed to Scheduler:addSystems({ }, _)")

	assert(
		foundSystem,
		"Table containing unknown values passed to Scheduler:addSystems({ unknown }, _)"
	)

	return self
end

--- @method editSystem
--- @within Scheduler
--- @param system System
--- @param newPhase Phase
---
--- Changes the Phase that this system is scheduled on.
function Scheduler.editSystem<U...>(
	self: Scheduler<U...>,
	system: System<U...>,
	newPhase: Phase
)
	local systemFn = getSystem(system)
	assert(
		systemFn,
		"Unknown system passed to Scheduler:editSystem(unknown, _)"
	)

	local systemInfo = self._systemInfo[systemFn]
	assert(
		systemInfo,
		"Attempt to edit a non-existent system in Scheduler:editSystem(system, _)"
	)

	assert(
		newPhase and self._phaseToSystems[newPhase] ~= nil or true,
		"Phase never initialized before using Scheduler:editSystem(_, phase)"
	)

	local systems = self._phaseToSystems[systemInfo.phase]

	local index = table.find(systems, systemFn :: InternalSystem<...any>)
	assert(index, "Unable to find system within phase")

	table.remove(systems, index)

	if not self._phaseToSystems[newPhase] then
		self._phaseToSystems[newPhase] = {}
	end
	table.insert(
		self._phaseToSystems[newPhase],
		systemFn :: InternalSystem<...any>
	)

	systemInfo.phase = newPhase
	return self
end

function Scheduler._removeCondition<U...>(
	self: Scheduler<U...>,
	dependent: Dependent<U...>,
	condition: Condition<U...>
)
	self._runIfConditions[dependent :: any] = nil

	for _, _conditions in self._runIfConditions do
		if table.find(_conditions :: any, condition) then
			return
		end
	end

	conditions.cleanupCondition(condition)
end

--- @method removeSystem
--- @within Scheduler
--- @param system System
--- @return Scheduler
---
--- Removes the System from the Scheduler.
---
--- If the system provided a cleanup function during initialization,
--- that cleanup function will be executed before removal.
---
--- ```lua
--- -- System with cleanup
--- local function networkSystem(world, state)
---     local connection = Players.PlayerAdded:Connect(function(player)
---         -- Player joined logic
---     end)
---
---     return function(world, state)
---         -- Runtime logic
---     end, function()
---         -- Cleanup runs on removeSystem
---         connection:Disconnect()
---     end
--- end
---
--- scheduler:addSystem(networkSystem, Phase.Update)
--- -- Later...
--- scheduler:removeSystem(networkSystem) -- Cleanup executes here
--- ```
function Scheduler.removeSystem<U...>(self: Scheduler<U...>, system: System<U...>)
	local systemFn = getSystem(system)
	assert(systemFn, "Invalid system passed to Scheduler:removeSystem(system)")

	local systemInfo = self._systemInfo[systemFn]
	assert(
		systemInfo,
		"Attempt to remove a non-existent system in Scheduler:removeSystem(system)"
	)

	if systemInfo.cleanup then
		-- LUAU FUTURE: Better types for pcalls
		local success: boolean, err: string? = (pcall :: any)(
			systemInfo.cleanup,
			table.unpack(self._vargs)
		)

		if success then
			self:_systemCleanup(systemInfo, nil)
		else
			local errMsg = string.format(
				"Cleanup failed for system '%s': %s",
				systemInfo.name,
				tostring(err)
			)
			self:_systemError(systemInfo, errMsg)
			self:_systemCleanup(systemInfo, errMsg)
		end
	end

	local systems = self._phaseToSystems[systemInfo.phase]

	local index = table.find(systems :: any, systemFn)
	assert(index, "Unable to find system within phase")

	table.remove(systems, index)
	self._systemInfo[systemFn] = nil

	if self._runIfConditions[system :: any] then
		for _, condition in self._runIfConditions[system :: any] do
			self:_removeCondition(system, condition)
		end

		self._runIfConditions[system :: any] = nil
	end

	self:_systemRemove(systemInfo :: SystemInfo<U...>)

	return self
end

--- @method replaceSystem
--- @within Scheduler
--- @param old System
--- @param new System
---
--- Replaces the System with a new System.
function Scheduler.replaceSystem<U...>(
	self: Scheduler<U...>,
	old: System<U...>,
	new: System<U...>
)
	local oldSystemFn = getSystem(old) :: InternalSystem<...any>
	assert(
		oldSystemFn,
		"Attempt to pass non-system in Scheduler:replaceSystem(unknown, _)"
	)

	local oldSystemInfo = self._systemInfo[oldSystemFn]
	assert(
		oldSystemInfo,
		"Attempt to replace a non-existent system in Scheduler:replaceSystem(system, _)"
	)

	local newSystemFn = getSystem(new) :: InternalSystem<...any>
	assert(
		newSystemFn,
		"Attempt to pass non-system in Scheduler:replaceSystem(_, unknown)"
	)

	if oldSystemInfo.cleanup then
		-- LUAU FUTURE: Better types for pcalls
		local success: boolean, err: string? = (pcall :: any)(
			oldSystemInfo.cleanup,
			table.unpack(self._vargs)
		)
		if success then
			self:_systemCleanup(oldSystemInfo, nil)
		else
			local errMsg = string.format(
				"Cleanup failed for system '%s': %s",
				oldSystemInfo.name,
				tostring(err)
			)
			self:_systemError(oldSystemInfo, errMsg)
			self:_systemCleanup(oldSystemInfo, errMsg)
		end
	end

	local systems = self._phaseToSystems[oldSystemInfo.phase]

	local index = table.find(systems, oldSystemFn)
	assert(index, "Unable to find system within phase")

	table.remove(systems, index)
	table.insert(systems, index, newSystemFn)

	local copy = table.clone(oldSystemInfo)

	oldSystemInfo.system = newSystemFn
	oldSystemInfo.run = newSystemFn
	oldSystemInfo.cleanup = nil
	oldSystemInfo.initialized = false
	oldSystemInfo.name = getSystemName(new)

	self:_systemReplace(
		copy :: SystemInfo<U...>,
		oldSystemInfo :: SystemInfo<U...>
	)

	self._systemInfo[newSystemFn] = self._systemInfo[oldSystemFn]
	self._systemInfo[oldSystemFn] = nil

	return self
end

--- @method addRunCondition
--- @within Scheduler
--- @param system System
--- @param fn (U...) -> any
---
--- Adds a Run Condition which the Scheduler will check before
--- this System is ran.

--- @method addRunCondition
--- @within Scheduler
--- @param phase Phase
--- @param fn (U...) -> any
---
--- Adds a Run Condition which the Scheduler will check before
--- any Systems within this Phase are ran.

--- @method addRunCondition
--- @within Scheduler
--- @param pipeline Pipeline
--- @param fn (U...) -> any
---
--- Adds a Run Condition which the Scheduler will check before
--- any Systems within any Phases apart of this Pipeline are ran.
function Scheduler.addRunCondition<U...>(
	self: Scheduler<U...>,
	dependent: Dependent<U...>,
	fn: Condition<U...>
)
	fn = if typeof(fn) == "table" then fn[1] else fn

	local system: SystemFn<...any>? = getSystem(dependent :: any) :: any
	if system then
		dependent = system
	end

	assert(
		system or isPhase(dependent) or isPipeline(dependent),
		"Attempt to pass unknown dependent into Scheduler:addRunCondition(unknown, _)"
	)

	if not self._runIfConditions[dependent :: any] then
		self._runIfConditions[dependent :: any] = {}
	end

	table.insert(self._runIfConditions[dependent :: any], fn)

	return self
end

function Scheduler._scheduleEvent<U...>(self: Scheduler<U...>, instance, event)
	local connect = utils.getConnectFn(instance, event)
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
				-- LUAU FUTURE: Inference bug
				task.spawn<<(string, number?)>>(error, err, 0)
				warn(
					`Planck: Error occurred while running event, this error will be ignored for 10 seconds`
				)
				recentLogs[err] = true
			end

			return
		end

		for _, dependency in orderedList do
			self:run(dependency :: any)
		end
	end

	self._connectedEvents[identifier] = connect(callback)
	self._eventDependencyGraphs[identifier] =
		dependencyGraph :: DependencyGraph<Dependency>
end

function Scheduler._getEventDependencyGraph<U...>(
	self: Scheduler<U...>,
	instance,
	event
)
	local identifier = getEventIdentifier(instance, event)

	if not self._connectedEvents[identifier] then
		self:_scheduleEvent(instance, event)
	end

	return self._eventDependencyGraphs[identifier]
end

function Scheduler._getGraphOfDependency<U...>(
	self: Scheduler<U...>,
	dependency: Dependency
)
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
function Scheduler.cleanup<U...>(self: Scheduler<U...>)
	for _, connection in self._connectedEvents do
		utils.disconnectEvent(connection)
	end

	for _, plugin in self._plugins do
		-- LUAU FUTURE: Type solver doesn't play nice here
		local cleanup: ((self: Plugin) -> ())? = plugin.cleanup
		if cleanup then
			cleanup(plugin)
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
function Scheduler.new<U...>(...: U...): Scheduler<U...>
	local defaultPhase = Phase.new("Default")
	local defaultDependencyGraph: DependencyGraph<Dependency> =
		DependencyGraph.new() :: any

	defaultDependencyGraph:insert(Pipeline.Startup)
	defaultDependencyGraph:insert(defaultPhase)

	local self: Scheduler<U...> = setmetatable({
		_defaultPhase = defaultPhase,
		_defaultDependencyGraph = defaultDependencyGraph,
		_eventDependencyGraphs = {},
		_connectedEvents = {},
		_plugins = {},
		_phaseToSystems = {},
		_hooks = {},
		_runIfConditions = {},
		_systemInfo = {},
		_thread = nil :: any,
		_currentSystem = nil :: any,
		_yielded = false,
		_vargs = { ... },
	}, Scheduler)

	for _, hookName in self.Hooks :: any do
		if not self._hooks[hookName] then
			self._hooks[hookName] = {}
		end
	end

	self:addRunCondition(Pipeline.Startup, conditions.runOnce())
	for _, phase in Pipeline.Startup.dependencyGraph.nodes do
		self:addRunCondition(phase, conditions.runOnce())
	end

	return self :: Scheduler<U...>
end

export type Scheduler<U...> = setmetatable<
	{
		_defaultPhase: Phase,
		_defaultDependencyGraph: DependencyGraph<Dependency>,
		_eventDependencyGraphs: { [string]: DependencyGraph<Dependency> },
		_connectedEvents: { [string]: utils.ConnectionLike },
		_plugins: Vec<Plugin>,
		-- LUAU FIXME: Should be System<U...>
		_phaseToSystems: Map<Phase, Vec<InternalSystem<...any>>>,
		_hooks: Map<HookId, Vec<(PartialHookContext) -> unknown>>,
		-- LUAU FIXME: Should be <Dependent<U...>, Condition<U...>>
		_runIfConditions: Map<Dependent<...any>, Vec<Condition<...any>>>,
		-- LUAU FIXME: Should be SystemInfo<U...>
		_systemInfo: Map<InternalSystem<U...>, SystemInfo<...any>>,
		_currentSystem: SystemInfo<...any>,
		_thread: thread?,
		_yielded: boolean,
		_vargs: { any },
	},
	typeof(Scheduler)
>

return Scheduler
