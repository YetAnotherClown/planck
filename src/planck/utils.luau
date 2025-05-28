type Phase = any
type Pipeline = any

type SystemFn<U...> = ((U...) -> any) | ((U...) -> ())

type SystemTable<U...> = {
	system: SystemFn<U...>,
	phase: Phase?,
	[any]: any,
}

type System<U...> = SystemFn<U...> | SystemTable<U...>

local function getSystem<U...>(system: any): SystemTable<U...>?
	if type(system) == "function" then
		return system
	elseif type(system) == "table" and system.system then
		return system.system
	else
		return nil
	end
end

local function getSystemName(system: any): string
	local name = debug.info(system, "n")
	if not name or string.len(name) == 0 then
		local source, line = debug.info(system, "sl")
		name = `{source}:{line}`
	end

	return name
end

local function isPhase(phase: any): Phase?
	if type(phase) == "table" and phase._type == "phase" then
		return phase
	else
		return nil
	end
end

local function isPipeline(pipeline: any): Pipeline?
	if type(pipeline) == "table" and pipeline._type == "pipeline" then
		return pipeline
	else
		return nil
	end
end

local function getEventIdentifier(instance, event)
	return `{instance}{event and `@{event}` or ""}`
end

local EVENT_CONNECT_METHODS = { "Connect", "On", "on", "connect" }

export type EventLike = RBXScriptSignal | {
	connect: (self: EventLike, ...any) -> any,
	[any]: any,
} | {
	Connect: (self: EventLike, ...any) -> any,
	[any]: any,
} | {
	on: (self: EventLike, ...any) -> any,
	[any]: any,
}

export type EventInstance = Instance | {
	[any]: EventLike,
}

type ConnectFn<U...> = (callback: (U...) -> ()) -> ()

-- This function is inspired by useEvent in Matter, a library by evaera (https://github.com/evaera)
-- License: Copyright (c) 2021 Eryn L. K., MIT License
-- Source: https://github.com/matter-ecs/matter/blob/main/lib/hooks/useEvent.luau
local function getConnectFunction<U...>(
	instance: EventInstance | EventLike,
	event: string | EventLike
): ConnectFn<U...>?
	local eventInstance = instance

	if typeof(event) == "RBXScriptSignal" or type(event) == "table" then
		eventInstance = event
	elseif type(event) == "string" then
		eventInstance = (instance :: any)[event]
	end

	if type(eventInstance) == "function" then
		return eventInstance
	elseif typeof(eventInstance) == "RBXScriptSignal" then
		return function(callback)
			eventInstance:Connect(callback)
		end
	end

	if type(eventInstance) == "table" then
		for _, method in EVENT_CONNECT_METHODS do
			if type(eventInstance[method]) ~= "function" then
				continue
			end

			return function(callback)
				eventInstance[method](eventInstance, callback)
			end
		end
	end

	return nil
end

local function isValidEvent(instance, event)
	return getConnectFunction(instance, event) ~= nil
end

return {
	getSystem = getSystem,
	getSystemName = getSystemName,
	isPhase = isPhase,
	isPipeline = isPipeline,
	getEventIdentifier = getEventIdentifier,
	isValidEvent = isValidEvent,
	getConnectFunction = getConnectFunction,
}
