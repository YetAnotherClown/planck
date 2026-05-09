---
title: Creating Plugins
description: Information & API on the development of Plugins
sidebar_position: 1
---

:::caution
Avoid using private members, denoted by a `_` at the start, within the Scheduler.
These are considered private and may change or be removed without notice
in any version. This includes minor and patch versions.

You are allowed to access the SystemInfo type and its members. While
breaking changes may occur, you will be given notice.
:::

### Required and Optional Members

All plugins feature a `build` method and a `new` function. Optionally, some
plugins may include a `cleanup` method to perform cleanup logic when the
scheduler is cleaned up.

This is an example of what the type for your plugin may look like.

```lua
type Plugin = setmetatable<{}, {
	build: (self: Plugin, scheduler: Scheduler<...unknown>) -> (),
	cleanup: ((self: Plugin) -> ())?,
	new: (...any) -> Plugin,
}>
```

### Template

To make the process of creating Plugins simple, you can use and build upon the following template.
This is what all the official Planck plugins use, you can use them as a reference as well.

```lua
local Planck = require("@packages/planck")
type Scheduler<U...> = Planck.Scheduler<U...>

local Plugin = {}
Plugin.__index = Plugin

--- The Scheduler calls this function internally, passing itself to the plugin.
--- Here, you can add hooks, systems, phases, etc.
function Plugin.build(self: Plugin, scheduler: Scheduler<...unknown>)
	-- ...
end

--- This is called whenever `Scheduler:cleanup()` is called, allowing you to
--- disconnect connections or perform other cleanup logic when the scheduler is thrown away.
function Plugin.cleanup(self: Plugin)
	-- ...
end

--- You can require users to pass anything you need into the arguments of `Plugin.new()`.
function Plugin.new(): Plugin
	local plugin = {}

	-- ...

	return setmetatable(plugin, Plugin)
end

type Plugin = setmetatable<{
	-- Add properties here
	-- _myState: { [any]: any },
}, typeof(Plugin)>

return Plugin
```

### Using your Plugin

To add your plugin to the Scheduler, you can use [Scheduler:addPlugin](/api/Scheduler#addPlugin).

```lua
scheduler
	:addPlugin(MyPlugin.new())
```

---

## Hooks API

What makes Plugins in Planck so powerful is the Plugin Hooks API. This API allows Plugins to
hook onto several events that occur within the Scheduler, providing relevant context for those events.

To register a hook, you can use [Scheduler:addHook](/api/Scheduler#addHook) to register a callback to be called when the given
event fires.

```lua
scheduler:addHook(
	scheduler.Hooks.SystemAdd,
	function(context: SystemHookContext)
		local systemInfo = context.system
		local system = systemInfo.system
		-- ...
	end
)
```

Each hook gives different context related to it's associated event. Below, you can see what context each
hook provides and how to use it.

---

### SystemInfo

```lua
type SystemLog<E> = {
	-- An Error object or message
	e: E,
	-- The string that will be printed
	log: string,
	-- The traceback as reported by the Scheduler
	trace: string,
}

type SystemInfo<U...> {
	system: (U...) -> (), -- The original system
	run: (U...) -> (), -- The function to run
	cleanup: ((U...) -> ())?, -- The function to run on cleanup
	phase: Phase, -- What Phase this system belongs to
	name: string, -- The name of the system
	recentLogs: { [string]: boolean }, The logs that have been reported recently
	logs: { SystemLog<unknown> }, -- The accumulated errors/warnings from this system
	initialized: boolean, -- Whether or not this system has already been initialized
}
```

SystemInfo a shared type used within the context given by hooks.

---

### SystemAdd

```lua
type Context<U...> = {
	scheduler: Scheduler<U...>,
	system: SystemInfo
}
```

Whenever a system is added to the Scheduler, this hook is called.

This could be useful, for example, to integrate Planck into a Debugger.
Below, is a brief example of how the `planck-jabby` plugin works:

```lua
scheduler:addHook(
	scheduler.Hooks.SystemAdd,
	function(context: SystemHookContext)
		local systemInfo = context.system

		local id = jabbyScheduler:register_system({
			name = systemInfo.name,
			phase = tostring(systemInfo.phase),
		})

		systemToId[systemInfo.system] = id
	end
)
```

---

### SystemRemove

```lua
type Context<U...> = {
	scheduler: Scheduler<U...>,
	system: SystemInfo
}
```

This hook is called when a system is removed from the Scheduler.

In a development environment, when debugging, developers may
choose to hot-reload their code, including adding/removing systems.
If integrating Planck into a debugger, you will have to consider this.

As such, the `planck-jabby` plugin does just that by utilizing this hook:

```lua
scheduler:addHook(
	scheduler.Hooks.SystemRemove,
	function(context: SystemHookContext)
		local systemInfo = context.system
		local system = systemInfo.system

		jabbyScheduler:remove_system(systemToId[system])
		systemToId[system] = nil
	end
)
```

---

### SystemReplace

```lua
type Context<U...> = {
	scheduler: Scheduler<U...>,
	old: SystemInfo,
	new: SystemInfo
}
```

This is like a [SystemAdd](#SystemAdd) and a [SystemRemove](#SystemRemove) hook in one,
called when the [Scheduler:replaceSystem](/api/Scheduler#replaceSystem) method is called. You'll
want to use this hook for the same reasons as SystemAdd and SystemRemove.

In the `planck-jabby` plugin, we do just that:

```lua
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
```

---

### SystemCleanup

```lua
type Context<E, U...> = {
	scheduler: Scheduler<U...>,
	system: SystemInfo,
	error: SystemLog<E>?
}
```

Whenever a system is removed, whether from [Scheduler:removeSystem](/api/Scheduler#removeSystem) or
[Scheduler:replaceSystem](/api/Scheduler#replaceSystem) (for the old system), this hook is called
if the system has a [cleanup function](/docs/getting_started/systems#cleanup).

This context contains an `error` returned by the cleanup function
if it errored. If integrating Planck into a debugger, and you have some
way to display errors, you may want to utilize this hook.

:::note
When using this hook, keep in mind that `context.error.e` can be of any type.
This could be a string, a custom Error Object, or anything. Logs from Planck
will be a string, but system errors may return anything.
:::

---

### SystemError

```lua
type Context<E, U...> = {
	scheduler: Scheduler<U...>,
	system: SystemInfo,
	error: SystemLog<E>?
}
```

Whenever a system errors when being ran by the Scheduler, this hook
will be called and return a context containing an `error`. This is
the error returned by the system. Note that [SystemCleanup](#SystemCleanup) is a
separate hook that handles errors at cleanup.

If integrating Planck into a debugger, and you have some way to display
errors, you may want to utilize this hook.

:::note
When using this hook, keep in mind that `context.error.e` can be of any type.
This could be a string, a custom Error Object, or anything. Logs from Planck
will be a string, but system errors may return anything.
:::

---

### SystemTriedRun

```lua
type Context<U...> = {
	scheduler: Scheduler<U...>,
	system: SystemInfo
}
```

This hook is useful to indicate when a system tried to run but was not
allowed to. With [run conditions](/docs/design/conditions), the Scheduler may refuse to run a
system that frame.

When integrating Planck into a debugger that displays when systems are
running, you may want to consider how to handle run conditions.

In the `planck-jabby` plugin, we will mark the systems as paused so that
there is a visual indicator that they are not running and so that they
are not factored into the total frame time:

```lua
scheduler:_addHook(scheduler.Hooks.SystemTriedRun, function(context)
	local systemInfo = context.system
	local system = systemInfo.system
	local id = systemToId[system]

	jabbyScheduler:set_system_data(id, {
		paused = true
	})
end)
```

---

### SystemCall

```lua
type Context<U...> = {
	scheduler: Scheduler<U...>,
	system: SystemInfo,
	nextFn: () -> (),
}
```

System calls are a little special, because they come in three different
levels: [SystemCall](#SystemCall), [InnerSystemCall](#InnerSystemCall), and [OuterSystemCall](#OuterSystemCall).

Hooks on OuterSystemCall are called first, then InnerSystemCall, and then
finally SystemCall, each wrapping around each other and running before
the actual system does first.

:::caution
You must return a function in the callback and you must call
`context.nextFn()` within that function.

Your callback (the outer function) is only called once, whereas
the function you returned (the inner function) is called each time
a system is ran. If you do not call `context.nextFn()` within this hook, the system will never run. You are not allowed to prevent systems from running using this method. Instead, see [run conditions](/docs/design/conditions).
:::

In the `planck-jabby` plugin, we integrate Planck into the debugger
by calling `jabbyScheduler:run()` inside this hook:

```lua
scheduler:addHook(
	scheduler.Hooks.SystemCall,
	function(context: SystemCallContext)
		local systemInfo = context.system
		local system = systemInfo.system
		local id = systemToId[system]

		return function()
			-- Unpause in case SystemTriedRun paused it before
			jabbyScheduler:set_system_data(id, {
				paused = false
			})

			jabbyScheduler:run(id, context.nextFn)
		end
	end
)
```

We intentionally call `context.nextFn()` in the `JabbyScheduler:run()` callback here so that Jabby can track the run time for our systems. By using `SystemCall` instead of other levels, we can ensure Jabby is as close to the system as possible so that Jabby doesn't track other noise.

---

### InnerSystemCall

```lua
type Context<U...> = {
	scheduler: Scheduler<U...>,
	system: SystemInfo,
	nextFn: () -> (),
}
```

OuterSystemCall is the second hook to be called when a system is ran,
as this hook is wraps over SystemCall and is wrapped by OuterSystemCall.

**_See [SystemCall](#SystemCall) for more information and warnings on these hooks._**

---

### OuterSystemCall

```lua
type Context<U...> = {
	scheduler: Scheduler<U...>,
	system: SystemInfo,
	nextFn: () -> (),
}
```

OuterSystemCall is the first hook to be called when a system is ran,
being the most hook.

**_See [SystemCall](#SystemCall) for more information and warnings on these hooks._**

In the `planck-matter-hooks` plugin, we integrate the topoRuntime from
Matter into Planck by adding it as a hook onto OuterSystemCall. This
way, the topoRuntime now encompasses everything.

```lua
scheduler:addHook(
	scheduler.Hooks.OuterSystemCall,
	function(context: SystemCallContext)
		return function()
			topoRuntime.start({
				-- ...
			}, context.nextFn)
		end
	end
)
```

---

### PhaseAdd

```lua
type Context<U...> = {
	scheduler: Scheduler<U...>,
	phase: Phase
}
```

Whenever a phase is added to the scheduler, whether as a phase itself
or apart of a larger pipeline, this hook is called.

---

### PhaseBegan

```lua
type Context<U...> = {
	scheduler: Scheduler<U...>,
	phase: Phase
}
```

When a phase begins, e.g. ran by [Scheduler:run](/api/Scheduler#run) or by an event it has
been scheduled on, this hook is called.

---

### Other

Didn't find the hook you were looking for? Make an issue proposing the new
hook you envision and its use case! Contributions are also welcome.

All of these hooks were added to support the built-in plugins, so we may of
missed some useful hooks that we just didn't need.
