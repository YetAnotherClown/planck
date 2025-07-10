---
title: Phases
description: An introduction to Phases in Planck
sidebar_position: 4
---

# Phases

In Roblox, you might be familiar with the [RunService](https://create.roblox.com/docs/reference/engine/classes/RunService). You can think of events
like `Heartbeat`, `PreRender`, or `PostSimulation` as Phases.

All a Phase is, is a sync point within the execution of a frame. You can see
the order of execution of a frame in Roblox in this image.

![Task Scheduler Priority](https://prod.docsiteassets.roblox.com/assets/optimization/task-scheduler/scheduler-priority.png.webp)

The 'Events' shown in this image represent the different sync points, or
Phases that Roblox provides in a frame, all being ran in an explicit order.

In Planck, we represent Phases as an Object which you can assign to
Systems. You can create, insert, and add a Phase to a system like so,

```lua title="scheduler.luau"
local Planck = require("@packages/Planck")
local Scheduler = Planck.Scheduler
local Phase = Planck.Phase

-- ...

local systemA = require("@shared/systems/systemA")

local myPhase = Phase.new("myPhase")

local scheduler = Scheduler.new(world, state)
    :insert(myPhase)
    :addSystem(systemA, myPhase)
```

:::note
Remember SystemTables? Instead of setting the phase in `addSystem`, you can
add it to your SystemTable and the system will be added to that Phase.
:::

We can also assign Phases to Events and Signals.

```lua {8} title="scheduler.luau"
-- ...

local systemA = require("@shared/systems/systemA")

local myPhase = Phase.new("myPhase")

local scheduler = Scheduler.new(world, state)
    :insert(myPhase, RunService, "Heartbeat")
    :addSystem(systemA, myPhase)
```

## Built-in Phases

Planck provides built-in Phases like Startup Phases and also provides a Plugin
for Roblox RunService that adds Pipelines and Phases for each RunService Event.

While you're just getting started, it is suggested that you use these built-in
phases for now. You will learn about deciding to make a Phase (and Pipelines)
later.

### Startup Phases

Startup Phases are a special kind of Phase. Planck will only run these
systems once, and before any other system is ran.

- PreStartup
- Startup
- PostStartup

```lua
local Planck = require("@packages/Planck")
local Phase = Planck.Phase

local PreStartup = Phase.PreStartup
local Startup = Phase.Startup
local PostStartup = Phase.PostStartup
```

These Phases are useful for initialization work that you need to do once,
and before you start your game loop.

## RunService Phases Plugin

Planck provides a plugin that adds built-in Phases and Pipelines for each
RunService event.

### Installation

With Wally,
```toml
[dependencies]
PlanckRunService = "yetanotherclown/planck-runservice@0.2.0"
```

### Pipelines

Each RunService Event is now it's own Pipeline,

- PreRender
- PreAnimation
- PreSimulation
- PostSimulation
- Heartbeat

:::tip
You might be more familiar with the old names for some of these events.

- `PreRender` is equivalent to `RenderStepped`
- `PreSimulation` is equivalent to `Stepped`
:::

```lua
local PlanckRunService = require("@packages/PlanckRunService")

local Pipelines = PlanckRunService.Pipelines

local PreRender = Pipelines.PreRender
local PreAnimation = Pipelines.PreAnimation
local PreSimulation = Pipelines.PreSimulation
local PostSimulation = Pipelines.PostSimulation
local Heartbeat = Pipelines.Heartbeat
```

### Phases

And it's own Phase, with the exception of `Heartbeat` which has many Phases.

| Event          | Phase          |
| -------------- | -------------- |
| PreRender      | PreRender      |
| PreAnimation   | PreAnimation   |
| PreSimulation  | PreSimulation  |
| PostSimulation | PostSimulation |
| Heartbeat      | Update         |

```lua
local PlanckRunService = require("@packages/PlanckRunService")

local Phases = PlanckRunService.Phases

local PreRender = Phases.PreRender
local PreAnimation = Phases.PreAnimation
local PreSimulation = Phases.PreSimulation
local PostSimulation = Phases.PostSimulation
local Update = Phases.Update
```

### More Update Phases

`RunService.Heartbeat` isn't just a single Phase, instead its composed of
many Phases. This is because the Update Phases are where most of your
game's logic will run on, so we believe it's important that you can
express the order of execution easily right out of the box.

- First
- PreUpdate
- Update
- PostUpdate
- Last

```lua
local PlanckRunService = require("@packages/PlanckRunService")

local Phases = PlanckRunService.Phases

local First = Phases.First
local PreUpdate = Phases.PreUpdate
local Update = Phases.Update
local PostUpdate = Phases.PostUpdate
local Last = Phases.Last
```

## What's Next?

Now that we know about Phases, it's time to learn how to explicitly define
our order of execution.

→ [The Order of Execution](./order.md)
