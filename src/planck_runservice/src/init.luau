local RunService = game:GetService("RunService")

local Planck = require(script.Parent.Planck)
type Scheduler<U...> = Planck.Scheduler<U...>

local Phase = Planck.Phase
type Phase = Planck.Phase

local Pipeline = Planck.Pipeline
type Pipeline = Planck.Pipeline

local Phases = {
	PreRender = Phase.new("PreRender"),
	PreAnimation = Phase.new("PreAnimation"),
	PreSimulation = Phase.new("PreSimulation"),
	PostSimulation = Phase.new("PostSimulation"),

	First = Phase.new("First"),
	PreUpdate = Phase.new("PreUpdate"),
	Update = Phase.new("Update"),
	PostUpdate = Phase.new("PostUpdate"),
	Last = Phase.new("Last"),
}

-- stylua: ignore
local Pipelines = {
	Heartbeat = Pipeline.new("HeartbeatPipeline")
		:insert(Phases.First)
		:insert(Phases.PreUpdate)
		:insert(Phases.Update)
		:insert(Phases.PostUpdate)
		:insert(Phases.Last),
	PreRender = Pipeline.new("PreRenderPipeline")
		:insert(Phases.PreRender),
	PreAnimation = Pipeline.new("PreAnimationPipeline")
		:insert(Phases.PreAnimation),
	PreSimulation = Pipeline.new("PreSimulationPipeline")
		:insert(Phases.PreSimulation),
	PostSimulation = Pipeline.new("PostSimulationPipeline")
		:insert(Phases.PostSimulation),
}

-- LUAU FUTURE: Remove this when they fix "Cannot iterate over a table without an indexer"
type Pipelines = { [keyof<typeof(Pipelines)>]: Pipeline }

local Plugin = {}
Plugin.__index = Plugin

function Plugin.build(_: Plugin, scheduler: Scheduler<...unknown>)
	for event, pipeline in Pipelines :: Pipelines do
		scheduler:insert(pipeline, RunService, event)
	end

	-- DependencyGraphs of Pipelines are typed as DependencyGraph<Phase> but
	-- the Default DependencyGraph should be DependencyGraph<Phase | Pipeline>.
	-- Since this type isn't public, casting to any is fine.
	scheduler._defaultDependencyGraph =
		Pipelines.Heartbeat.dependencyGraph :: any
	scheduler._defaultPhase = Phases.Update
end

function Plugin.new(): Plugin
	local plugin = {}
	return setmetatable(plugin, Plugin)
end

type Plugin = setmetatable<{}, typeof(Plugin)>

return {
	Plugin = Plugin,
	Phases = Phases,
	Pipelines = Pipelines,
}
