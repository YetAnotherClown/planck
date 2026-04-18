local Pipeline = require(script.Parent.Pipeline)
local Phase = require(script.Parent.Phase)

type Pipeline = Pipeline.Pipeline
type Phase = Phase.Phase

--- @type SystemFn ((U...) -> ())
--- @within Scheduler
--- Standard system function that runs every time it's scheduled
export type SystemFn<U...> = (U...) -> ()
type AnyFunction = (...any) -> ...any

--- @type CleanupFn (() -> ())
--- @within Scheduler
--- Cleanup function called when system is removed

export type InitializerResult<U...> =
	{
		system: SystemFn<U...>,
	}
	| {
		cleanup: SystemFn<U...>,
	}
	| {
		system: SystemFn<U...>,
		cleanup: SystemFn<U...>,
	}

--- @type InitializerSystemFn ((U...) -> (SystemFn<U...> | (SystemFn<U...>, CleanupFn)))
--- @within Scheduler
--- Initializer system that returns the runtime function, optionally with cleanup
export type InitializerSystemFn<U...> = (
	U...
) -> SystemFn<U...> | SystemFn<U...>

export type InternalSystem<U...> = SystemFn<U...> | InitializerSystemFn<U...>

--- @interface SystemTable
--- @within Scheduler
--- .system SystemFn<U...> | InitializerSystemFn<U...>
--- .phase Phase?
--- .name string?
--- .runConditions {RunCondition}?
--- .[any] any
export type SystemTable<U...> = {
	system: InternalSystem<U...>,
	phase: Phase?,
	name: string?,
	runConditions: { (U...) -> boolean }?,
	[any]: any,
}

--- @type System SystemFn<U...> | SystemTable<U...> | InitializerSystemFn<U...>
--- @within Scheduler
export type System<U...> =
	SystemFn<U...>
	| InitializerSystemFn<U...>
	| SystemTable<U...>

local function getSystem<U...>(system: System<U...>): InternalSystem<U...>?
	if type(system) == "function" then
		return system
	elseif type(system) == "table" and system.system then
		return system.system
	else
		return nil
	end
end

local function getSystemName<U...>(system: System<U...>): string
	if type(system) == "table" and system.name then
		return system.name
	end

	local fn: AnyFunction = if type(system) == "table"
		then system.system
		else system

	local name = debug.info(fn, "n")
	if not name or string.len(name) == 0 then
		local source, line = debug.info(fn, "sl")
		name = `{source}:{line}`
	end

	return name
end

local function isSystem<U...>(system: unknown): InternalSystem<U...>?
	if type(system) == "function" then
		return system
	else
		return nil
	end
end

local function isPhase(phase: unknown): Phase?
	if type(phase) == "table" and phase._type == "phase" then
		return phase :: Phase
	else
		return nil
	end
end

local function isPipeline(pipeline: unknown): Pipeline?
	if type(pipeline) == "table" and pipeline._type == "pipeline" then
		return pipeline :: Pipeline
	else
		return nil
	end
end

local function getEventIdentifier(instance, event)
	return `{instance}{event and `@{event}` or ""}`
end

local EVENT_CONNECT_METHODS = { "Connect", "On", "on", "connect" }

export type ConnectionLike = RBXScriptConnection | {
	disconnect: (self: ConnectionLike, ...any) -> any,
	[any]: any,
} | {
	Disconnect: (self: ConnectionLike, ...any) -> any,
	[any]: any,
} | {
	destroy: (self: ConnectionLike, ...any) -> any,
	[any]: any,
} | {
	Destroy: (self: ConnectionLike, ...any) -> any,
	[any]: any,
} | (...any) -> any

local EVENT_DISCONNECT_METHODS =
	{ "disconnect", "Disconnect", "destroy", "Destroy" }

local function disconnectEvent(connection: ConnectionLike)
	if type(connection) == "function" then
		connection()
		return
	elseif typeof(connection) == "RBXScriptConnection" then
		connection:Disconnect()
		return
	elseif type(connection) == "table" then
		for _, method in EVENT_DISCONNECT_METHODS do
			local connect: unknown = (connection :: any)[method]

			if connect and connect == "function" then
				(connect :: any)(connection)
				return
			end
		end
	end
end

export type Callback<U...> = (U...) -> ...any
export type ConnectFn<T, U...> = (callback: (U...) -> ...any) -> T
export type GenericTable = { [any]: any }

export type SignalLike<U...> =
	{
		connect: (self: SignalLike<U...>, Callback<U...>, ...any?) -> any,
		[any]: any,
	}
	| {
		Connect: (self: SignalLike<U...>, Callback<U...>, ...any?) -> any,
		[any]: any,
	}
	| {
		on: (self: SignalLike<U...>, Callback<U...>, ...any?) -> any,
		[any]: any,
	}
	| {
		On: (self: SignalLike<U...>, Callback<U...>, ...any?) -> any,
		[any]: any,
	}

type GetConnectFn =
	-- RBXScriptSignal & nil
	(<U...>(RBXScriptSignal<U...>) -> ConnectFn<RBXScriptConnection, U...>)
	-- Instance & RBXScriptSignal
	-- Instance & string
	& (<U...>(
		Instance,
		RBXScriptSignal<U...> | string
	) -> ConnectFn<RBXScriptConnection, U...>)
	-- SignalLike & nil
	& (<U...>(SignalLike<U...>) -> ConnectFn<any, U...>)
	-- table & string
	& (<U...>(GenericTable, string) -> ConnectFn<any, U...>)
	-- table & connectable method
	& (<T, U...>(
		GenericTable,
		(GenericTable, Callback<U...>, ...any) -> T
	) -> ConnectFn<T, U...>)
	-- connectable function
	& (<T, U...>((Callback<U...>, ...any) -> T) -> ConnectFn<T, U...>)

-- This function is inspired by useEvent in Matter, a library by evaera (https://github.com/evaera)
-- License: Copyright (c) 2021 Eryn L. K., MIT License
-- Source: https://github.com/matter-ecs/matter/blob/main/lib/hooks/useEvent.luau
local getConnectFn: GetConnectFn = function(instance: any, event: any): any
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
			return eventInstance:Connect(callback)
		end
	end

	if type(eventInstance) == "table" then
		if type(event) == "function" then
			return function(callback)
				return (event :: any)(eventInstance, callback)
			end
		end

		for _, method in EVENT_CONNECT_METHODS do
			if type(eventInstance[method]) ~= "function" then
				continue
			end

			return function(callback)
				return eventInstance[method](eventInstance, callback)
			end
		end
	end

	return nil
end

local function isValidEvent(instance, event)
	return getConnectFn(instance, event) ~= nil
end

return {
	getSystem = getSystem,
	getSystemName = getSystemName,
	isSystem = isSystem,
	isPhase = isPhase,
	isPipeline = isPipeline,
	getEventIdentifier = getEventIdentifier,
	isValidEvent = isValidEvent,
	getConnectFn = getConnectFn,
	disconnectEvent = disconnectEvent,
}
