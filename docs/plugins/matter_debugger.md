---
title: Matter Debugger
description: A Plugin to add support for the Matter Debugger to Planck
sidebar_position: 3
---

The Matter Debugger plugin provides support for Planck within the Matter
debugger.

### Installation

```toml title="wally.toml"
[dependencies]
DebuggerPlugin = "yetanotherclown/planck-matter-debugger@0.2.0"
```

### Setup and Use

First, we need to create the scheduler, and add the Debugger Plugin to it.

```lua title="src/shared/scheduler.luau"
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require("@packages/Matter")
local Plasma = require("@packages/Plasma")

local Planck = require("@packages/Planck")
local Scheduler = Planck.Scheduler

local world = require("@shared/world")

local DebuggerPlugin = require("@packages/DebuggerPlugin")
local debuggerPlugin = DebuggerPlugin.new({ world })

local debugger = Matter.Debugger.new(Plasma)
local widgets = debugger:getWidgets()

local scheduler = scheduler.new(world, widgets)
    :addPlugin(debuggerPlugin)

debugger:autoInitialize(debuggerPlugin:getLoop())

return scheduler
```

Next, you can add your systems to the scheduler and use your widgets and the debugger to inspect your code.

See the [Debugger Guide](https://matter-ecs.github.io/matter/docs/Guides/MatterDebugger) on the Matter Documentation site for more information about the Debugger.