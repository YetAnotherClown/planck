local Planck = require(script.Parent.Planck)

type Scheduler<U...> = Planck.Scheduler<U...>
type SystemInfo<U...> = Planck.SystemInfo<U...>
type System<U...> = Planck.System<U...>

type SystemCallContext = Planck.SystemCallContext
type PhaseContext = Planck.PhaseContext
type SystemErrorContext = Planck.SystemErrorContext

type InternalSystem<U...> =
	| Planck.SystemFn<U...>
	| Planck.InitializerSystemFn<U...>

local rollingAverage = require("@self/rollingAverage.luau")

type Loop = {
	_debugger: any?,
	_state: { unknown },
	_worlds: { unknown },
	_skipSystems: { [InternalSystem<...unknown>]: boolean },
	_orderedSystemsByEvent: { [string]: { InternalSystem<...unknown> } },
	_systemErrors: {
		[InternalSystem<...unknown>]: {
			{
				error: any,
				when: number,
			}
		},
	},
	_systemLogs: { unknown },

	profiling: { [InternalSystem<...unknown>]: {
		[any]: any,
	} },

	addMiddleware: (self: Loop, middleware: Middleware) -> (),
}

type Middleware = (nextFn: () -> (), eventName: string) -> () -> ()

local Plugin = {}
Plugin.__index = Plugin

function Plugin.build(self: Plugin, scheduler: Scheduler<...unknown>)
	local loop: Loop = {
		_debugger = nil :: any?,
		_state = scheduler._vargs,
		_worlds = self._worlds,
		_skipSystems = {},
		_orderedSystemsByEvent = {},
		_systemErrors = {} :: any,
		-- TODO: Implement ._systemLogs for Matter Hooks .log hook
		_systemLogs = {},
		profiling = {},

		addMiddleware = function(_: Loop, middleware: Middleware)
			table.insert(self._middleware, middleware)
		end,
	}

	local function addPhase(context: PhaseContext)
		local name = context.phase._name

		loop._orderedSystemsByEvent[name] =
			scheduler._phaseToSystems[context.phase]
	end

	for phase in scheduler._phaseToSystems do
		addPhase({
			scheduler = scheduler,
			phase = phase,
		})
	end

	scheduler:addHook(scheduler.Hooks.PhaseAdd, addPhase)

	scheduler:addHook(
		scheduler.Hooks.SystemCall,
		function(context: SystemCallContext)
			local systemInfo = context.system

			return function()
				local nextFn = context.nextFn

				for _, middleware in self._middleware do
					nextFn = middleware(nextFn, systemInfo.phase._name)
				end

				nextFn()
			end
		end
	)

	scheduler:addHook(
		scheduler.Hooks.SystemError,
		function(context: SystemErrorContext)
			local systemInfo = context.system
			local system = systemInfo.system

			if not loop._systemErrors[system] then
				loop._systemErrors[system] = {}
			end

			-- This code snippet is sourced from Matter by evaera (https://github.com/evaera)
			-- License: Copyright (c) 2021 Eryn L. K., MIT License
			-- Source: https://github.com/matter-ecs/matter/blob/main/lib/Loop.luau
			-- Modification: Modified to work with this Planck Plugin

			local errorStorage = loop._systemErrors[system]
			local lastError = errorStorage[#errorStorage]

			if lastError and lastError.error == context.error then
				lastError.when = os.time()
			else
				table.insert(loop._systemErrors[system], {
					error = context.error,
					when = os.time(),
				})

				if #errorStorage > 100 then
					table.remove(errorStorage, 1)
				end
			end
		end
	)

	scheduler:addHook(
		scheduler.Hooks.InnerSystemCall,
		function(context: SystemCallContext)
			local systemInfo = context.system
			local system = systemInfo.system

			return function()
				-- This code snippet is sourced from Matter by evaera (https://github.com/evaera)
				-- License: Copyright (c) 2021 Eryn L. K., MIT License
				-- Source: https://github.com/matter-ecs/matter/blob/main/lib/Loop.luau
				-- Modifications: Modified to work with this Planck Plugin

				if loop._skipSystems[system] then
					if loop.profiling then
						loop.profiling[system] = nil
					end

					return
				else
					local startTime = os.clock()
					context.nextFn()

					if loop.profiling ~= nil then
						local duration = os.clock() - startTime

						if loop.profiling[system] == nil then
							loop.profiling[system] = {}
						end

						local debugger = loop._debugger
						if
							debugger
							and debugger.debugSystem == system
							and debugger._queries
						then
							local totalQueryTime = 0

							for _, query in debugger._queries do
								totalQueryTime += query.averageDuration
							end

							rollingAverage.addSample(
								loop.profiling[system],
								if debugger.debugSystem
									then duration - totalQueryTime
									else duration
							)
						else
							rollingAverage.addSample(
								loop.profiling[system],
								duration
							)
						end
					end
				end
			end
		end
	)

	self._loop = loop
end

function Plugin.getLoop(self: Plugin)
	if not self._loop then
		error("Add Plugin to the Scheduler before retrieving the Loop")
	end

	return self._loop
end

function Plugin.new(worlds: { unknown }): Plugin
	local plugin = {
		-- We will create the loop in the build step.
		_loop = nil :: any,
		_middleware = {},
		_worlds = worlds or {},
	}

	return setmetatable(plugin, Plugin)
end

type Plugin = setmetatable<{
	_loop: Loop,
	_middleware: { Middleware },
	_worlds: { unknown },
}, typeof(Plugin)>

return Plugin
