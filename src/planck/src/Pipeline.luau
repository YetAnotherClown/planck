local DependencyGraph = require(script.Parent.DependencyGraph)
local Phase = require(script.Parent.Phase)

type DependencyGraph<T> = DependencyGraph.DependencyGraph<T>
type Phase = Phase.Phase

--- @class Pipeline
---
--- Pipelines represent a set of ordered Phases. Systems cannot be
--- assigned to Pipelines themselves, but rather to Phases within
--- those Pipelines.
local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline.__tostring(self: Pipeline): string
	return self._name
end

--- @method insert
--- @within Pipeline
--- @param phase Phase
--- @return Pipeline
---
--- Adds a Phase to the Pipeline, ordering it implicitly.
function Pipeline.insert(self: Pipeline, phase: Phase): Pipeline
	self.dependencyGraph:insert(phase)
	return self
end

--- @method insertAfter
--- @within Pipeline
--- @param phase Phase
--- @param after Phase
--- @return Pipeline
---
--- Adds a Phase to the Pipeline after another Phase, ordering it explicitly.
function Pipeline.insertAfter(
	self: Pipeline,
	phase: Phase,
	afterPhase: Phase
): Pipeline
	local i = table.find(self.dependencyGraph.nodes, afterPhase)
	assert(
		i,
		"Unknown Phase in Pipeline:insertAfter(_, unknown), try adding this Phase to the Pipeline."
	)

	self.dependencyGraph:insertAfter(phase, afterPhase)
	return self
end

--- @method insertBefore
--- @within Pipeline
--- @param phase Phase
--- @param before Phase
--- @return Pipeline
---
--- Adds a Phase to the Pipeline before another Phase, ordering it explicitly.
function Pipeline.insertBefore(
	self: Pipeline,
	phase: Phase,
	beforePhase: Phase
): Pipeline
	local i = table.find(self.dependencyGraph.nodes, beforePhase)
	assert(
		i,
		"Unknown Phase in Pipeline:insertBefore(_, unknown), try adding this Phase to the Pipeline."
	)

	self.dependencyGraph:insertBefore(phase, beforePhase)
	return self
end

--- @within Pipeline
---
--- Creates a new Pipeline, with an optional name to use for debugging.
--- When no name is provided, the script and line number will be used.
function Pipeline.new(name: string?): Pipeline
	name = name or debug.info(2, "sl") :: string

	local dependencyGraph: DependencyGraph<Phase> = DependencyGraph.new()

	return setmetatable({
		_name = name,
		_type = "pipeline",
		dependencyGraph = dependencyGraph,
	}, Pipeline)
end

--- @prop Startup Pipeline
--- @within Pipeline
---
--- A Pipeline containing the `PreStartup`, `Startup`, and `PostStartup` phases.
Pipeline.Startup = Pipeline.new()
	:insert(Phase.PreStartup)
	:insert(Phase.Startup)
	:insert(Phase.PostStartup)

export type Pipeline = setmetatable<{
	_name: string,
	_type: "pipeline",
	dependencyGraph: DependencyGraph<Phase>,
}, typeof(Pipeline)>

return Pipeline
