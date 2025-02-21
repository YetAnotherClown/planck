local Phase = require("@Project/Phase") :: any
local Pipeline = require("@Project/Pipeline") :: any
local Scheduler = require("@Project/Scheduler") :: any

local conditions = require("@Project/conditions")
local utils = require("@Project/utils")

type EventLike = utils.EventLike
type EventInstance = utils.EventInstance

export type SystemFn<U...> = ((U...) -> any) | ((U...) -> ())

export type SystemTable<U...> = {
	system: SystemFn<U...>,
	phase: Phase?,
	name: string?,
	runConditions: { (U...) -> boolean }?,
	[any]: any,
}

export type System<U...> = SystemFn<U...> | SystemTable<U...>

export type Phase = {
	PreStartup: Phase,
	Startup: Phase,
	PostStartup: Phase,

	new: (debugName: string?) -> Phase,
}

export type Pipeline = {
	Startup: Pipeline,

	insert: (self: Pipeline, phase: Phase) -> Pipeline,
	insertAfter: (self: Pipeline, phase: Phase, after: Phase) -> Pipeline,
	new: (debugName: string?) -> Pipeline,
}

type Plugin<U...> = {
	build: (self: Plugin<U...>, scheduler: Scheduler<U...>) -> (),
	cleanup: ((self: Plugin<U...>) -> ())?,
	[any]: any,
}

export type Scheduler<U...> = {
	addPlugin: (self: Scheduler<U...>, plugin: Plugin<U...>) -> Scheduler<U...>,

	addSystem: (
		self: Scheduler<U...>,
		system: System<U...>,
		phase: Phase?
	) -> Scheduler<U...>,

	addSystems: (
		self: Scheduler<U...>,
		systems: { System<U...> },
		phase: Phase?
	) -> Scheduler<U...>,

	editSystem: (
		self: Scheduler<U...>,
		system: System<U...>,
		new: Phase
	) -> Scheduler<U...>,

	replaceSystem: (
		self: Scheduler<U...>,
		system: System<U...>,
		new: System<U...>
	) -> Scheduler<U...>,

	removeSystem: (
		self: Scheduler<U...>,
		system: System<U...>
	) -> Scheduler<U...>,

	addRunCondition: ((
		self: Scheduler<U...>,
		system: System<U...>,
		fn: (U...) -> boolean,
		...any
	) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		phase: Phase,
		fn: (U...) -> boolean,
		...any
	) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		pipeline: Pipeline,
		fn: (U...) -> boolean,
		...any
	) -> Scheduler<U...>),

	run: ((self: Scheduler<U...>, system: System<U...>) -> Scheduler<U...>)
		& ((self: Scheduler<U...>, phase: Phase) -> Scheduler<U...>)
		& ((self: Scheduler<U...>, pipeline: Pipeline) -> Scheduler<U...>),

	runAll: (self: Scheduler<U...>) -> Scheduler<U...>,

	getDeltaTime: (self: Scheduler<U...>) -> number,

	insert: ((self: Scheduler<U...>, phase: Phase) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		pipeline: Pipeline
	) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		phase: Phase,
		instance: EventInstance | EventLike,
		event: string | EventLike
	) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		Pipeline: Pipeline,
		instance: EventInstance | EventLike,
		event: string | EventLike
	) -> Scheduler<U...>),

	insertAfter: ((
		self: Scheduler<U...>,
		phase: Phase,
		after: Phase | Pipeline
	) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		pipeline: Pipeline,
		after: Phase | Pipeline
	) -> Scheduler<U...>),

	cleanup: (self: Scheduler<U...>) -> (),

	new: (U...) -> Scheduler<U...>,
}

return {
	Phase = Phase :: Phase,
	Pipeline = Pipeline :: Pipeline,
	Scheduler = Scheduler :: {
		new: <U...>(U...) -> Scheduler<U...>,
	},

	isNot = conditions.isNot,
	runOnce = conditions.runOnce,
	timePassed = conditions.timePassed,
	onEvent = conditions.onEvent,
}
