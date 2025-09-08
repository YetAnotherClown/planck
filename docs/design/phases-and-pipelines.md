---
title: Phases and Pipelines
description: Designing with Phases and Pipelines
sidebar_position: 3
---

import Tabs from "@theme/Tabs";
import TabItem from "@theme/TabItem";

# Phases and Pipelines

## Phases

When you're working with custom Phases, it is important to try and reduce
the complexity of your order of execution. Too many Phases could prove
difficult to work with if they are not managed properly.

When you have multiple *related* phases, which means phases that all run on
the same event, and in order of one after another, you should create a
Pipeline to manage them.

## Pipelines

Pipelines are ordered groups of Phases, they make it easy to work with large
collections of Phases when they run on the same event.

An example of a Pipeline would be the built-in `RunService.Heartbeat`
Pipeline, appropriately named 'Main'.

First -> PreUpdate -> Update -> PostUpdate -> Last

All of these Phases run on the same event, `RunService.Heartbeat`. And they
are explicitly ordered to run one after another.

By grouping Phases like this, we can manage them more effectively. Here's
an example of what I mean:

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local Phase = Planck.Phase
local Pipeline = Planck.Pipeline
local Scheduler = Planck.Scheduler

local PreUpdate = Phase.new()
local Update = Phase.new()
local PostUpdate = Phase.new()

local UpdatePipeline = Pipeline.new()
	:insert(PreUpdate)
	:insert(Update)
	:insert(PostUpdate)

local scheduler = scheduler.new(world)
    :insert(UpdatePipeline, RunService, "Heartbeat")
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
import { Phase, Pipeline, Scheduler } from "@rbxts/planck";

const PreUpdate = new Phase();
const Update = new Phase();
const PostUpdate = new Phase();

const UpdatePipeline = new Pipeline()
    .insert(PreUpdate)
    .insert(Update)
    .insert(PostUpdate);

const scheduler = new Scheduler(world)
    .insert(UpdatePipeline, RunService, "Heartbeat");
```
</TabItem>
</Tabs>
Instead of using `insert` on every Phase, we instead just insert the
Pipeline and all of the Phases in the Pipeline are inserted on the same
event.

## What's Next

Let's look into Conditions, which allow us to set strict conditions on
when a System, Phase, or Pipeline can run.

It's important to note that conditions *do not* run any code. When a Phase
is executed, it will check the conditions on itself and it's systems, if the
conditions are met, the Phase or System will run.