local Planck = require(script.Parent.Planck)

type Scheduler<U...> = Planck.Scheduler<U...>
type SystemInfo<U...> = Planck.SystemInfo<U...>
type SystemHookContext = Planck.SystemHookContext
type SystemReplaceContext = Planck.SystemReplaceContext
type SystemCallContext = Planck.SystemCallContext

type InternalSystem<U...> =
	| Planck.SystemFn<U...>
	| Planck.InitializerSystemFn<U...>

local Jabby = require(script.Parent.Jabby)

local Plugin = {}
Plugin.__index = Plugin

local n = 0

function Plugin.build(_: Plugin, scheduler: Scheduler<...unknown>)
	n += 1

	local identifier = n > 1 and ` #{n}` or ""
	local name = `Planck{identifier}`

	local jabbyScheduler = Jabby.scheduler.create()
	local startupScheduler = Jabby.scheduler.create()

	local systemToId = {}

	local STARTUP_PHASES = { "PreStartup", "Startup", "PostStartup" }

	local function addSystem<U...>(
		systemFn: InternalSystem<U...>,
		systemInfo: SystemInfo<U...>
	)
		local phase = tostring(systemInfo.phase)
		if table.find(STARTUP_PHASES, phase) then
			local id = startupScheduler:register_system({
				name = systemInfo.name,
				phase = phase,
			})

			startupScheduler:set_system_data(id, {
				paused = true,
			})
			systemToId[systemFn] = id
		else
			local id = jabbyScheduler:register_system({
				name = systemInfo.name,
				phase = phase,
			})

			jabbyScheduler:set_system_data(id, {
				paused = true,
			})
			systemToId[systemFn] = id
		end
	end

	for systemFn, systemInfo in scheduler._systemInfo do
		addSystem(systemFn, systemInfo)
	end

	scheduler:addHook(
		scheduler.Hooks.SystemAdd,
		function(context: SystemHookContext)
			local systemInfo = context.system
			addSystem(systemInfo.system, systemInfo)
		end
	)

	scheduler:addHook(
		scheduler.Hooks.SystemRemove,
		function(context: SystemHookContext)
			local systemInfo = context.system
			local system = systemInfo.system
			jabbyScheduler:remove_system(systemToId[system])
			systemToId[system] = nil
		end
	)

	scheduler:addHook(
		scheduler.Hooks.SystemReplace,
		function(context: SystemReplaceContext)
			local newSystemInfo = context.new
			local newSystem = newSystemInfo.system
			local oldSystem = context.old.system

			jabbyScheduler:remove_system(systemToId[oldSystem])
			systemToId[oldSystem] = nil

			local id = jabbyScheduler:register_system({
				name = newSystemInfo.name,
				phase = tostring(newSystemInfo.phase),
			})

			systemToId[newSystem] = id
		end
	)

	scheduler:addHook(
		scheduler.Hooks.SystemTriedRun,
		function(context: SystemHookContext)
			local systemInfo = context.system
			local system = systemInfo.system

			local id = systemToId[system]
			local phase = tostring(systemInfo.phase)

			if table.find(STARTUP_PHASES, phase) then
				startupScheduler:set_system_data(id, {
					paused = true,
				})
			else
				jabbyScheduler:set_system_data(id, {
					paused = true,
				})
			end
		end
	)

	scheduler:addHook(
		scheduler.Hooks.SystemCall,
		function(context: SystemCallContext)
			local systemInfo = context.system
			local system = systemInfo.system

			local id = systemToId[system]

			return function()
				local phase = tostring(systemInfo.phase)
				if table.find(STARTUP_PHASES, phase) then
					startupScheduler:set_system_data(id, {
						paused = false,
					})
					startupScheduler:run(id, function()
						context.nextFn()
					end)
				else
					jabbyScheduler:set_system_data(id, {
						paused = false,
					})
					jabbyScheduler:run(id, function()
						context.nextFn()
					end)
				end
			end
		end
	)

	Jabby.register({
		applet = Jabby.applets.scheduler,
		name = name .. " (Startup)",
		configuration = {
			scheduler = startupScheduler,
		},
	})

	Jabby.register({
		applet = Jabby.applets.scheduler,
		name = name,
		configuration = {
			scheduler = jabbyScheduler,
		},
	})
end

function Plugin.new(): Plugin
	local plugin = {}
	return setmetatable(plugin, Plugin)
end

type Plugin = setmetatable<{}, typeof(Plugin)>

return Plugin
