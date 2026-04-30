local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Planck = require(script.Parent.Planck)
type Scheduler<U...> = Planck.Scheduler<U...>
type System<U...> = Planck.System<U...>
type Phase = Planck.Phase

type PhaseContext = Planck.PhaseContext
type SystemHookContext = Planck.SystemHookContext
type SystemReplaceContext = Planck.SystemReplaceContext
type SystemCallContext = Planck.SystemCallContext

local log = require(script.hooks.log)
local useDeltaTime = require(script.hooks.useDeltaTime)
local useEvent = require(script.hooks.useEvent)
local useThrottle = require(script.hooks.useThrottle)

local topoRuntime = require(script.topoRuntime)

type SystemState = topoRuntime.SystemState

-- When using Matter, we must use the topoRuntime in the library
if ReplicatedStorage:FindFirstChild("Packages") then
	local library: Folder & {
		matter: ModuleScript & {
			hooks: Folder & {
				log: ModuleScript,
				useDeltaTime: ModuleScript,
				useEvent: ModuleScript,
				useThrottle: ModuleScript,
			},
			topoRuntime: ModuleScript,
		},
	}

	for _, package in ReplicatedStorage.Packages._Index:GetChildren() do
		if
			string.find(package.Name, "matter%-ecs_matter@")
			or string.find(package.Name, "evaera_matter@")
		then
			library = package :: any
			break
		end
	end

	if library then
		local hooks = library["matter"]["hooks"]

		log = (require)(hooks.log) :: typeof(log)
		useDeltaTime = (require)(hooks.useDeltaTime) :: typeof(useDeltaTime)
		useEvent = (require)(hooks.useEvent) :: typeof(useEvent)
		useThrottle = (require)(hooks.useThrottle) :: typeof(useThrottle)
		topoRuntime = (require)(
				library.matter.topoRuntime
			) :: typeof(topoRuntime)
	end
end

local function defaultPhaseState()
	local currentTime = os.clock()

	return {
		currentTime = currentTime,
		lastTime = currentTime,
		deltaTime = 0,
		generation = false,
	}
end

local Plugin = {}
Plugin.__index = Plugin

function Plugin.build(self: Plugin, scheduler: Scheduler<...unknown>)
	for phase in scheduler._phaseToSystems do
		self._phaseState[phase] = defaultPhaseState()
	end

	scheduler:addHook(scheduler.Hooks.PhaseAdd, function(context: PhaseContext)
		local phase = context.phase
		self._phaseState[phase] = defaultPhaseState()
	end)

	scheduler:addHook(
		scheduler.Hooks.SystemAdd,
		function(context: SystemHookContext)
			local systemInfo = context.system
			local system = systemInfo.system

			self._systemState[system] = {}
			self._systemLogs[system] = {}
		end
	)

	scheduler:addHook(
		scheduler.Hooks.SystemRemove,
		function(context: SystemHookContext)
			local systemInfo = context.system
			local system = systemInfo.system

			self._systemState[system] = nil
			self._systemLogs[system] = nil
		end
	)

	scheduler:addHook(
		scheduler.Hooks.SystemReplace,
		function(context: SystemReplaceContext)
			local newSystemInfo = context.new
			local newSystem = newSystemInfo.system
			local oldSystem = context.old.system

			self._systemState[newSystem] = self._systemState[oldSystem]
			self._systemLogs[newSystem] = self._systemLogs[oldSystem]
			self._systemState[oldSystem] = nil
			self._systemLogs[oldSystem] = nil
		end
	)

	scheduler:addHook(
		scheduler.Hooks.OuterSystemCall,
		function(context: SystemCallContext)
			local systemInfo = context.system
			local system = systemInfo.system
			local phase = systemInfo.phase

			local phaseState = self._phaseState[phase]
			local systemState = self._systemState[system]
			local systemLogs = self._systemLogs[system]

			return function()
				topoRuntime.start({
					currentSystem = system,
					system = systemState,
					frame = {
						deltaTime = phaseState.deltaTime,
						generation = phaseState.generation,
						logs = systemLogs,
					},
				}, context.nextFn)
			end
		end
	)
end

function Plugin.new(): Plugin
	local plugin = {
		_phaseState = {},
		_systemState = {},
		_systemLogs = {},
	}

	return setmetatable(plugin, Plugin)
end

type PhaseState = {
	currentTime: number,
	lastTime: number,
	deltaTime: number,
	generation: boolean,
}

type Plugin = setmetatable<{
	_phaseState: { [Phase]: PhaseState },
	_systemState: { [System<...unknown>]: SystemState },
	_systemLogs: { [System<...unknown>]: { string } },
}, typeof(Plugin)>

return {
	log = log,
	useDeltaTime = useDeltaTime,
	useEvent = useEvent,
	useThrottle = useThrottle,
	useHookState = topoRuntime.useHookState,

	Plugin = Plugin,
}
