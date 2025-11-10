---
title: The Scheduler
description: An introduction to Planck's Scheduler
sidebar_position: 2
---

import Tabs from "@theme/Tabs";
import TabItem from "@theme/TabItem";

# The Scheduler

The scheduler is the core of Planck! This is where you handle setup and initialization for
your game's scheduling.

:::tip
The Scheduler's API Design is largely influenced by [Bevy](https://bevyengine.org/) Schedules!
:::

To create a new Scheduler, we can do it like so,

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local Planck = require("@packages/Planck")
local Scheduler = Planck.Scheduler

local scheduler = Scheduler.new()
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
import { Scheduler } from "@rbxts/planck";

const scheduler = new Scheduler();
```
</TabItem>
</Tabs>

This is technically all the setup you need to do with the Scheduler, there's no `start` or initialization method
by design.

In this step, you can also add [Planck Plugins](../plugins/plugins.md) to extend the functionality of the scheduler or add support for 3rd party tooling like Jabby.

Another thing you might want to do is passing state to your systems. You can do this by passing them into the `Scheduler.new()` function.
We will go over how to access this state later.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua {4-8,10}
local Planck = require("@packages/Planck")
local Scheduler = Planck.Scheduler

local Jecs = require("@packages/Jecs")
local World = Jecs.World

local world = World.new()
local state = {}

local scheduler = Scheduler.new(world, state)
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts {2-5,7}
import { Scheduler } from "@rbxts/planck";
import { World } from "@rbxts/jecs";

const world = new World();
const state = {};

const scheduler = new Scheduler(world, state);
```
</TabItem>
</Tabs>

## What's Next?

Let's learn how to make Systems and add then to our Scheduler now.

→ [Systems](./systems.md)
