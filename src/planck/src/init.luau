local Phase = require(script.Phase) :: any
local Pipeline = require(script.Pipeline) :: any
local Scheduler = require(script.Scheduler) :: any

local conditions = require(script.conditions)
local utils = require(script.utils)

type GenericTable = utils.GenericTable
type SignalLike<U...> = utils.SignalLike<U...>
type ConnectionLike = utils.ConnectionLike
type ConnectFn<T, U...> = utils.ConnectFn<T, U...>
type Callback<U...> = utils.Callback<U...>

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
	[any]: any,
} | {
	build: (self: Plugin<U...>, scheduler: Scheduler<U...>) -> (),
	cleanup: (self: Plugin<U...>) -> (),
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

	insert: ((
		self: Scheduler<U...>,
		dependency: Phase | Pipeline
	) -> Scheduler<U...>)
		-- RBXScriptSignal & nil
		& ((
			self: Scheduler<U...>,
			dependency: Phase | Pipeline,
			signal: RBXScriptSignal<U...>
		) -> Scheduler<U...>)
		-- Instance & RBXScriptSignal
		-- Instance & string
		& ((
			self: Scheduler<U...>,
			dependency: Phase | Pipeline,
			instance: Instance,
			event: RBXScriptSignal<U...> | string
		) -> Scheduler<U...>)
		-- SignalLike & nil
		& ((
			self: Scheduler<U...>,
			dependency: Phase | Pipeline,
			signal: SignalLike<U...>
		) -> Scheduler<U...>)
		-- table & string
		& ((
			self: Scheduler<U...>,
			dependency: Phase | Pipeline,
			table: GenericTable,
			event: string
		) -> Scheduler<U...>)
		-- table & connectable method
		& (<T>(
			self: Scheduler<U...>,
			dependency: Phase | Pipeline,
			instance: GenericTable,
			connectMethod: (GenericTable, Callback<U...>, ...any) -> T
		) -> Scheduler<U...>)
		-- connectable function
		& (<T>(
			self: Scheduler<U...>,
			dependency: Phase | Pipeline,
			connectFn: (Callback<U...>, ...any) -> T
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

	insertBefore: ((
		self: Scheduler<U...>,
		phase: Phase,
		before: Phase | Pipeline
	) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		pipeline: Pipeline,
		before: Phase | Pipeline
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
