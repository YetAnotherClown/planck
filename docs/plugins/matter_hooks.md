---
title: Matter Hooks
description: A Plugin to add the Matter topoRuntime and Hooks to Planck
sidebar_position: 2
---

The Matter Hooks plugin provides a way to use the Matter topoRuntime to use any
hook made for [Matter](https://github.com/matter-ecs/matter).

:::tip
This Plugin can be used with any ECS library. It ***doesn't*** require Matter for you to use this hooks.
You can also use the extended [matter-hooks](<https://github.com/matter-ecs/matter-hooks>) library by the Matter team with this Plugin.
:::

### Installation

```toml title="wally.toml"
[dependencies]
MatterHooks = "yetanotherclown/planck-matter-hooks@0.2.1"
```

### Setup and Use

First, let's make a system and use our hooks.

Hooks are exported from the Matter Hooks plugin,
so we can use them within our systems like so:

```lua title="src/shared/systems/systemA.luau"
local MatterHooks = require("@packages/MatterHooks")

local useDeltaTime = MatterHooks.useDeltaTime
local useEvent = MatterHooks.useEvent
local useThrottle = MatterHooks.useThrottle

function systemA()
    if useThrottle(5) then
        print("Throttled for 5 seconds")
    end
end

return systemA
```

Then we need to create the scheduler, and add the Hooks Plugin to it.

```lua title="src/shared/scheduler.luau"
local Planck = require("@packages/Planck")
local Scheduler = Planck.Scheduler

local MatterHooks = require("@packages/MatterHooks")
local hooksPlugin = MatterHooks.new()

local scheduler = scheduler.new()
    :addPlugin(hooksPlugin)

return scheduler
```

And finally, add the system to your scheduler.

```lua title="src/shared/startup.luau"
local scheduler = require("@shared/scheduler")
local systemA = require("@shared/systems/systemA")

return function()
    scheduler
        :addSystem(systemA)
end
```

### API

API can be found on the Matter documentation site, click the following links to be redirected.

- [Scheduler.log](https://matter-ecs.github.io/matter/api/Matter#log)
- [Scheduler.useDeltaTime](https://matter-ecs.github.io/matter/api/Matter#useDeltaTime)
- [Scheduler.useEvent](https://matter-ecs.github.io/matter/api/Matter#useEvent)
- [Scheduler.useHookState](https://matter-ecs.github.io/matter/api/Matter#useHookState)
- [Scheduler.useThrottle](https://matter-ecs.github.io/matter/api/Matter#useThrottle)

### Using with Matter

To use Matter's Hooks in Matter, you still need to use this Plugin.

By default, the Plugin will look for the official Matter library in `ReplicatedStorage/Packages/_Index`.
This should work if you're installing from Wally. If you're not, you can pass in a reference to the
Matter library in the Plugin constructor.

```lua title="src/shared/scheduler.luau"
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Planck = require("@packages/Planck")
local Scheduler = Planck.Scheduler

local MatterHooks = require("@packages/MatterHooks")
local hooksPlugin = MatterHooks.new(ReplicatedStorage.Matter)

local scheduler = scheduler.new()
    :addPlugin(hooksPlugin)

return scheduler
```
