---
title: RunService Phases
description: A Plugin to adds built-in RunService Phases and Pipelines
sidebar_position: 4
---

import Tabs from "@theme/Tabs";
import TabItem from "@theme/TabItem";

Planck provides a plugin that adds built-in Phases and Pipelines for each
RunService event.

### Installation

<Tabs groupId="package-manager">
<TabItem value="wally" label="Wally">
```toml title="wally.toml"
[dependencies]
PlanckRunService = "yetanotherclown/planck-runservice@0.2.0"
```
</TabItem>
<TabItem value="npm" label="NPM">
Run `npm i @rbxts/planck-runservice` in your terminal.
</TabItem>
</Tabs>

### Setup

First, we need to create the scheduler, and add the Plugin to it.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
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
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts title="src/shared/scheduler.ts"
import { Scheduler } from "@rbxts/planck";

import world from "shared/world";

import { Plugin as RunServicePlugin } from "@rbxts/planck-runservice";
const runServicePlugin = new RunServicePlugin();

const scheduler = new Scheduler(world)
    .addPlugin(runServicePlugin);

export default scheduler;
```
</TabItem>
</Tabs>

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

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local PlanckRunService = require("@packages/PlanckRunService")

local Pipelines = PlanckRunService.Pipelines

local PreRender = Pipelines.PreRender
local PreAnimation = Pipelines.PreAnimation
local PreSimulation = Pipelines.PreSimulation
local PostSimulation = Pipelines.PostSimulation
local Heartbeat = Pipelines.Heartbeat
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
import { Pipelines } from "@rbxts/planck-runservice";

const PreRender = Pipelines.PreRender;
const PreAnimation = Pipelines.PreAnimation;
const PreSimulation = Pipelines.PreSimulation;
const PostSimulation = Pipelines.PostSimulation;
const Heartbeat = Pipelines.Heartbeat;
```
</TabItem>
</Tabs>

### Phases

And it's own Phase, with the exception of `Heartbeat` which has many Phases.

| Event          | Phase          |
| -------------- | -------------- |
| PreRender      | PreRender      |
| PreAnimation   | PreAnimation   |
| PreSimulation  | PreSimulation  |
| PostSimulation | PostSimulation |
| Heartbeat      | Update         |

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local PlanckRunService = require("@packages/PlanckRunService")

local Phases = PlanckRunService.Phases

local PreRender = Phases.PreRender
local PreAnimation = Phases.PreAnimation
local PreSimulation = Phases.PreSimulation
local PostSimulation = Phases.PostSimulation
local Update = Phases.Update
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
import { Phases } from "@rbxts/planck-runservice";

const PreRender = Phases.PreRender;
const PreAnimation = Phases.PreAnimation;
const PreSimulation = Phases.PreSimulation;
const PostSimulation = Phases.PostSimulation;
const Update = Phases.Update;
```
</TabItem>
</Tabs>
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

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local PlanckRunService = require("@packages/PlanckRunService")

local Phases = PlanckRunService.Phases

local First = Phases.First
local PreUpdate = Phases.PreUpdate
local Update = Phases.Update
local PostUpdate = Phases.PostUpdate
local Last = Phases.Last
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
import { Phases } from "@rbxts/planck-runservice";

const First = Phases.First;
const PreUpdate = Phases.PreUpdate;
const Update = Phases.Update;
const PostUpdate = Phases.PostUpdate;
const Last = Phases.Last;
```
</TabItem>
</Tabs>
