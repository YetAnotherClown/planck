---
title: Jabby
description: A Plugin to add support for Jabby
sidebar_position: 1
---

[Jabby](https://github.com/alicesaidhi/jabby), by alicesaidhi, is a Debugger developed for [Jecs](https://github.com/Ukendio/jecs), an ECS library by Ukendio.
This Plugin handles all setup to add the Planck Scheduler to Jabby.

### Installation

```toml title="wally.toml"
[dependencies]
PlanckJabby = "yetanotherclown/planck-jabby@0.2.0"
```

### Setup and Use

First, we need to create the scheduler, and add the Jabby Plugin to it.

```lua title="src/shared/scheduler.luau"
local Planck = require("@packages/Planck")
local Scheduler = Planck.Scheduler

local world = require("@shared/world")

local PlanckJabby = require("@packages/PlanckJabby")
local jabbyPlugin = PlanckJabby.new()

local scheduler = scheduler.new(world)
    :addPlugin(jabbyPlugin)

return scheduler
```

This only adds the Scheduler to Jabby, you'll have to add the
World and other setup yourself.
