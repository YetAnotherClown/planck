---
title: Order of Execution
description: The basics on ordering
sidebar_position: 5
---

import Tabs from "@theme/Tabs";
import TabItem from "@theme/TabItem";

# Order of Execution

When using Planck, it is important to understand how your Pipelines, Phases,
and Systems will be ordered.

The order of execution is determined by two key things:
- Order of Insertion
- Phases/Pipelines dependents/dependencies

Planck uses these two things within an algorithm to order your Pipelines,
Phases, and Systems each frame.

## The Algorithm

Planck uses Kahn's algorithm to determine the order your Pipelines and
Phases will run in. Whereas systems are just ordered by the order of
insertion into the Scheduler.

### Key Terms

It is important to understand the following terms while explaining how ordering works:
- A *dependency* is any Phase/Pipeline another Phase/Pipeline depends on.
- A *dependent* if the Phase/Pipeline that depends on another Phase/Pipeline.

This looks like, `insertAfter(dependent, dependency)` or `insertBefore(dependent, dependency)`.

### Steps

And now to explain how the algorithm works, here are the steps it takes

> 1. Start with the first Phase/Pipeline inserted
> 2. If this Phase/Pipeline has any dependency, skip it and move onto the next one.
> 3. Add this Phase/Pipeline to the order
> 4. If this Phase/Pipeline has any dependents, repeat this process in order of insertion for each dependent Phase/Pipeline.
> 5. Move onto the next Phase/Pipeline.

## Pipelines and Phases

### Built-in

It is important to note that all of the built-in Phases you see will run
in the order they appear in the Documentation. Each of these Phases represent
a single sync point within a single frame of your game.

PreRender -> PreAnimation -> PreSimulation -> PostSimulation -> UpdatePipeline

### Custom

When using custom Pipelines or Phases, `Scheduler:insert()` will order them
by order of insertion. This is done by making the last added Phase/Pipeline a
dependency of the latest Phase/Pipeline.

For example,
<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local scheduler = Scheduler.new()
    :insert(phaseA)
    :insert(phaseB)
    :runAll()
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
const scheduler = new Scheduler()
    .insert(phaseA)
    .insert(phaseB)
    .runAll();
```
</TabItem>
</Tabs>

`phaseA` will run before `phaseB` when we do `scheduler:runAll()`.
In this scenario, `phaseA` is a dependency of `phaseB`, where `phaseA`
must run before `phaseB`.

Systems don't have any dependencies, they are only ordered by insertion
within a phase,
<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local scheduler = Scheduler.new()
    :addSystem(systemA)
    :addSystem(systemB)
    :runAll()
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
const scheduler = new Scheduler()
    .addSystem(systemA)
    .addSystem(systemB)
    .runAll();
```
</TabItem>
</Tabs>

So, `systemA` runs before `systemB`.

You can create dependencies for Phases/Pipelines explicitly too by using
`Scheduler:insertAfter()` and `Scheduler:insertBefore()`.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local scheduler = Scheduler.new()
    :insert(phaseA)
    :insertAfter(phaseB, phaseA)
    :runAll()
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
const scheduler = new Scheduler()
    .insert(phaseA)
    .insertAfter(phaseB, phaseA)
    .runAll();
```
</TabItem>
</Tabs>
`phaseB` now depends on `phaseA`, meaning it can't run until `phaseA` runs.

`Scheduler:insertBefore(phaseB, phaseA)` works similarly too, except `phaseB` can only
run before `phaseA`.

### With Events

Phases and Pipelines are grouped together into Groups.
Each Event is it's own group, and then we also have the `Default` group.

When using `insertAfter()` or `insertBefore()`, the dependent Phase/Pipeline
will inherit the event of it's dependency, joining that group.
Using `insert()` will always add a Phase/Pipeline to the `Default` group when
no event is specified.

Phases/Pipelines in different groups are not ordered together, instead each
group is isolated and their Phases/Pipelines will run in an order within the
group.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local scheduler = Scheduler.new()
    :insert(pipelineA, RunService.Heartbeat)
    :insertAfter(pipelineB, RunService.PostSimulation)
    :runAll()
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
const scheduler = new Scheduler()
    .insert(pipelineA, RunService.Heartbeat)
    .insertAfter(pipelineB, RunService.PostSimulation)
    .runAll();
```
</TabItem>
</Tabs>
This code will create two groups: `Heartbeat` and `PostSimulation`.
When `Scheduler:runAll()` runs, first it will process every Phase or Pipeline
on the `Heartbeat` group. And then, it will process every Phase or Pipeline on the
`PostSimulation` group.

## Whats Next?

You're ready to begin building a game with Planck!

Checkout the setup guides for:
- [Matter](../setup_guides/matter.md)
- [Jecs](../setup_guides/jecs.mdx)

Already read those guides? Already have a game with Planck?
Learn how to properly design Pipelines, Phases, and Systems.

→ [The Order of Execution](../design/design.md)