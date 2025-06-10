local rollingAverage = require("@self/rollingAverage.luau")

type SystemInfo = {
	name: string,
	phase: any,
	system: (...any) -> ...any,
}

type HookArgs = {
	scheduler: any,
	system: SystemInfo,
	nextFn: (...any) -> ...any,
}

type PhaseBeganArgs = {
	scheduler: any,
	phase: any,
}

type SystemsAddRemove = {
	scheduler: any,
	system: SystemInfo,
}

type SystemError = {
	scheduler: any,
	system: SystemInfo,
	error: string,
}

type SystemsEdit = {
	scheduler: any,
	new: SystemInfo,
	old: SystemInfo,
}

type PhaseAdd = {
	scheduler: any,
	phase: any,
}

type Middleware = (nextFn: () -> (), eventName: string) -> () -> ()

type ConnectionObject = {
	Disconnect: (() -> ())?,
	Destroy: (() -> ())?,
	disconnect: (() -> ())?,
	destroy: (() -> ())?,
} | () -> ()

type CustomEvent = {
	Connect: (...any) -> ConnectionObject,
	[any]: any,
} | {
	on: (...any) -> ConnectionObject,
	[any]: any,
} | {
	connect: (...any) -> ConnectionObject,
	[any]: any,
}

local Plugin = {}
Plugin.__index = Plugin

-- TODO: Implement ._systemLogs for Matter Hooks .log hook

function Plugin:build(scheduler: any)
	if not scheduler._systemLogs then
		scheduler._systemLogs = {}
	end

	local loop = {}
	loop._state = scheduler._vargs
	loop._worlds = self._worlds
	loop._skipSystems = {}
	loop._orderedSystemsByEvent = {}
	loop._systemErrors = {}
	loop._systemLogs = scheduler._systemLogs
	loop.profiling = {}

	local middlewares = {}

	function loop.addMiddleware(_, middleware: Middleware)
		table.insert(middlewares, middleware)
	end

	local function getEvent(phase)
		for event, phases in scheduler._eventToPhases do
			if table.find(phases, phase) then
				return event
			end
		end

		return nil
	end

	local function addPhase(args: PhaseAdd)
		local name = args.phase._name

		loop._orderedSystemsByEvent[name] =
			scheduler._phaseToSystems[args.phase]

		local phase = scheduler._orderedPhases[1].new(`Middleware@{name}`)

		local position = table.find(scheduler._orderedPhases, args.phase)
		local event = getEvent(args.phase)

		scheduler:_insertPhaseAt(phase, position)

		if event then
			if not scheduler._eventToPhases[event] then
				scheduler._eventToPhases[event] = {}
			end

			table.insert(scheduler._eventToPhases[event], phase)
		end

		scheduler:addSystem(function()
			local nextFn = function() end

			for _, middleware in middlewares do
				nextFn = middleware(nextFn, name)
			end

			nextFn()
		end, phase)
	end

	local currentPhases = table.clone(scheduler._orderedPhases)

	for _, phase in currentPhases do
		local event = getEvent(phase)

		addPhase({
			scheduler = scheduler,
			phase = phase,
			eventName = event and event.identifier,
		})
	end

	scheduler:_addHook(scheduler.Hooks.PhaseAdd, addPhase)

	scheduler:_addHook(scheduler.Hooks.SystemError, function(args: SystemError)
		local systemFn = args.system.system

		if not loop._systemErrors[systemFn] then
			loop._systemErrors[systemFn] = {}
		end

		-- This code snippet is sourced from Matter by evaera (https://github.com/evaera)
		-- License: Copyright (c) 2021 Eryn L. K., MIT License
		-- Source: https://github.com/matter-ecs/matter/blob/main/lib/Loop.luau

		local errorStorage = loop._systemErrors[systemFn]
		local lastError = errorStorage[#errorStorage]

		if lastError and lastError.error == args.error then
			lastError.when = os.time()
		else
			table.insert(loop._systemErrors[systemFn], {
				error = args.error,
				when = os.time(),
			})

			if #errorStorage > 100 then
				table.remove(errorStorage, 1)
			end
		end
	end)

	scheduler:_addHook(scheduler.Hooks.OuterSystemCall, function(args: HookArgs)
		return function()
			local systemFn = args.system.system

			-- This code snippet is sourced from Matter by evaera (https://github.com/evaera)
			-- License: Copyright (c) 2021 Eryn L. K., MIT License
			-- Source: https://github.com/matter-ecs/matter/blob/main/lib/Loop.luau

			if loop._skipSystems[systemFn] then
				if loop.profiling then
					loop.profiling[systemFn] = nil
				end

				return
			else
				local startTime = os.clock()
				args.nextFn()

				if loop.profiling ~= nil then
					local duration = os.clock() - startTime

					if loop.profiling[systemFn] == nil then
						loop.profiling[systemFn] = {}
					end

					local debugger = loop._debugger
					if
						debugger
						and debugger.debugSystem == systemFn
						and debugger._queries
					then
						local totalQueryTime = 0

						for _, query in debugger._queries do
							totalQueryTime += query.averageDuration
						end

						rollingAverage.addSample(
							loop.profiling[systemFn],
							if debugger.debugSystem
								then duration - totalQueryTime
								else duration
						)
					else
						rollingAverage.addSample(
							loop.profiling[systemFn],
							duration
						)
					end
				end
			end
		end
	end)

	self._loop = loop
end

function Plugin:getLoop()
	if not self._loop then
		error("Add Plugin to the Scheduler before retrieving the Loop")
	end

	return self._loop
end

function Plugin.new(worlds)
	local plugin = {}
	setmetatable(plugin, Plugin)

	plugin._worlds = worlds or {}

	return plugin
end

type SchedulerLike<U...> = {
	addPlugin: (
		self: SchedulerLike<U...>,
		plugin: Plugin<U...>
	) -> SchedulerLike<U...>,
	new: (U...) -> SchedulerLike<U...>,
	[any]: any,
}

type Plugin<U...> = {
	getLoop: (self: Plugin<U...>) -> {
		[any]: any,
	},
	build: (self: Plugin<U...>, scheduler: SchedulerLike<U...>) -> (),
	new: () -> Plugin<U...>,
}

return (Plugin :: any) :: Plugin<...any>
