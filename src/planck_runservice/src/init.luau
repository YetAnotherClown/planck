local RunService = game:GetService("RunService")

local Planck = require(script.Parent.Planck)

local Phase = Planck.Phase
type Phase = Planck.Phase

local Pipeline = Planck.Pipeline
type Pipeline = Planck.Pipeline

type System<U...> = Planck.System<U...>
type Scheduler<U...> = Planck.Scheduler<U...>

type SystemInfo<U...> = {
	name: string,
	phase: Phase,
	system: System<U...>,
}
 
type HookArgs<U...> = {
	scheduler: Scheduler<U...>,
	system: SystemInfo<U...>,
	nextFn: System<U...>,
}

type SystemsAddRemove<U...> = {
	scheduler: Scheduler<U...>,
	system: SystemInfo<U...>,
}

type SystemsReplace<U...> = {
	scheduler: Scheduler<U...>,
	new: SystemInfo<U...>,
	old: SystemInfo<U...>,
}

export type Phases = {
	PreRender: Phase,
	PreAnimation: Phase,
	PreSimulation: Phase,
	PostSimulation: Phase,

	First: Phase,
	PreUpdate: Phase,
	Update: Phase,
	PostUpdate: Phase,
	Last: Phase,
}

export type Pipelines = {
	Heartbeat: Pipeline,
	PreRender: Pipeline,
	PreAnimation: Pipeline,
	PreSimulation: Pipeline,
	PostSimulation: Pipeline,
}

local Phases = {} :: Phases

Phases.PreRender = Phase.new("PreRender")
Phases.PreAnimation = Phase.new("PreAnimation")
Phases.PreSimulation = Phase.new("PreSimulation")
Phases.PostSimulation = Phase.new("PostSimulation")

Phases.First = Phase.new("First")
Phases.PreUpdate = Phase.new("PreUpdate")
Phases.Update = Phase.new("Update")
Phases.PostUpdate = Phase.new("PostUpdate")
Phases.Last = Phase.new("Last")

local Pipelines: Pipelines = {} :: Pipelines

Pipelines.Heartbeat = Pipeline.new("HeartbeatPipeline")
	:insert(Phases.First)
	:insert(Phases.PreUpdate)
	:insert(Phases.Update)
	:insert(Phases.PostUpdate)
	:insert(Phases.Last)

Pipelines.PreRender = Pipeline.new("PreRenderPipeline"):insert(Phases.PreRender)

Pipelines.PreAnimation = Pipeline.new("PreAnimationPipeline")
	:insert(Phases.PreAnimation)

Pipelines.PreSimulation = Pipeline.new("PreSimulationPipeline")
	:insert(Phases.PreSimulation)

Pipelines.PostSimulation = Pipeline.new("PostSimulationPipeline")
	:insert(Phases.PostSimulation)

local Plugin = {}
Plugin.__index = Plugin

function Plugin:build<U...>(scheduler: Scheduler<U...>)
	for event, pipeline in pairs(Pipelines) do
		scheduler:insert(pipeline, RunService, event)
	end

	local _scheduler = scheduler :: any
	_scheduler._defaultDependencyGraph = (Pipelines.Heartbeat :: any).dependencyGraph
	_scheduler._defaultPhase = Phases.Update
end

function Plugin.new()
	return setmetatable({}, Plugin)
end

type Plugin<U...> = {
	build: (self: Plugin<U...>, scheduler: Scheduler<U...>) -> (),
	cleanup: ((self: Plugin<U...>) -> ())?,
	new: () -> Plugin<U...>,
}

return {
	Plugin = (Plugin :: any) :: Plugin<...any>,
	Phases = Phases,
	Pipelines = Pipelines,
}
