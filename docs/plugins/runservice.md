---
title: RunService Phases
description: A Plugin to adds built-in RunService Phases and Pipelines
sidebar_position: 4
---

Planck provides a plugin that adds built-in Phases and Pipelines for each
RunService event.

### Installation

```toml title="wally.toml"
[dependencies]
PlanckRunService = "yetanotherclown/planck-runservice@0.2.0"
```

### Setup

First, we need to create the scheduler, and add the Plugin to it.

```lua title="src/shared/scheduler.luau"
local Planck = require("@packages/Planck")
local Scheduler = Planck.Scheduler

local world = require("@shared/world")

local PlanckRunService = require("@packages/PlanckRunService")
local runServicePlugin = PlanckRunService.new()

local scheduler = scheduler.new(world)
    :addPlugin(runServicePlugin)

return scheduler
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
