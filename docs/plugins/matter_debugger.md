---
title: Matter Debugger
description: A Plugin to add support for the Matter Debugger to Planck
sidebar_position: 3
---

import Tabs from "@theme/Tabs";
import TabItem from "@theme/TabItem";

The Matter Debugger plugin provides support for Planck within the Matter
debugger.

### Installation

```toml title="wally.toml"
[dependencies]
DebuggerPlugin = "yetanotherclown/planck-matter-debugger@0.2.0"
```

### Setup and Use

First, we need to create the scheduler, and add the Debugger Plugin to it.


<Tabs groupId="language">
<TabItem value="lua" label="Luau">
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
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts title="src/shared/scheduler.ts"
import { Debugger } from "@rbxts/matter-debugger";
import Plasma from "@rbxts/plasma";
import { Scheduler } from "@rbxts/planck";

import world from "shared/world";

import DebuggerPlugin from "@rbxts/planck-matter-debugger";
const debuggerPlugin = new DebuggerPlugin([world]);

const debugger = new Debugger(Plasma);
const widgets = debugger.getWidgets();

const scheduler = new Scheduler(world, widgets)
    .addPlugin(debuggerPlugin);

debugger.autoInitialize(debuggerPlugin.getLoop());

export default scheduler;
```
</TabItem>
</Tabs>
Next, you can add your systems to the scheduler and use your widgets and the debugger to inspect your code.

See the [Debugger Guide](https://matter-ecs.github.io/matter/docs/Guides/MatterDebugger) on the Matter Documentation site for more information about the Debugger.
