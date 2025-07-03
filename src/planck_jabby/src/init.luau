local Jabby = require(script.Parent.Jabby)
 
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

type SystemsAddRemove = {
	scheduler: any,
	system: SystemInfo,
}

type SystemsReplace = {
	scheduler: any,
	new: SystemInfo,
	old: SystemInfo,
}

local Plugin = {}
Plugin.__index = Plugin

local n = 0

function Plugin:build(scheduler: any)
	n += 1

	local identifier = n > 1 and ` #{n}` or ""
	local name = `Planck{identifier}`

	local jabbyScheduler = Jabby.scheduler.create()

	local systemToId = {}

	for systemFn, systemInfo in scheduler._systemInfo do
		local id = jabbyScheduler:register_system({
			name = systemInfo.name,
			phase = tostring(systemInfo.phase),
		})

		systemToId[systemFn] = id
	end

	scheduler:_addHook(
		scheduler.Hooks.SystemAdd,
		function(info: SystemsAddRemove)
			local id = jabbyScheduler:register_system({
				name = info.system.name,
				phase = tostring(info.system.phase),
			})

			systemToId[info.system.system] = id
		end
	)

	scheduler:_addHook(
		scheduler.Hooks.SystemRemove,
		function(info: SystemsAddRemove)
			jabbyScheduler:remove_system(systemToId[info.system.system])
			systemToId[info.system.system] = nil
		end
	)

	scheduler:_addHook(
		scheduler.Hooks.SystemReplace,
		function(info: SystemsReplace)
			local newSystem = info.new.system
			local oldSystem = info.old.system

			jabbyScheduler:remove_system(systemToId[oldSystem])
			systemToId[oldSystem] = nil

			local id = jabbyScheduler:register_system({
				name = info.new.name,
				phase = tostring(info.new.phase),
			})

			systemToId[newSystem] = id
		end
	)

	local STARTUP_PHASES = { "PreStartup", "Startup", "PostStartup" }
	local startupSystems = {}

	scheduler:_addHook(scheduler.Hooks.SystemCall, function(args: HookArgs)
		local id = systemToId[args.system.system]

		return function()
			for _id, _ in startupSystems do
				jabbyScheduler:set_system_data(_id, {
					paused = true,
				})
			end

			jabbyScheduler:run(id, function()
				args.nextFn()

				local phase = tostring(args.system.phase)
				if table.find(STARTUP_PHASES, phase) then
					startupSystems[id] = true
				end
			end)
		end
	end)

	Jabby.register({
		applet = Jabby.applets.scheduler,
		name = name,
		configuration = {
			scheduler = jabbyScheduler,
		},
	})
end

function Plugin.new()
	return setmetatable({}, Plugin)
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
	build: (self: Plugin<U...>, scheduler: SchedulerLike<U...>) -> (),
	cleanup: ((self: Plugin<U...>) -> ())?,
	new: () -> Plugin<U...>,
}

return (Plugin :: any) :: Plugin<...any>
