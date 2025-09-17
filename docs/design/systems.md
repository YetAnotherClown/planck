---
title: Systems
description: An introduction to Systems in Planck
sidebar_position: 2
---

import Tabs from "@theme/Tabs";
import TabItem from "@theme/TabItem";

# Systems

When designing systems in ECS, we should be mindful of the composition of systems. In a system, we will usually perform queries;
add, modify, or remove data from our world, and or reconcile our data to Roblox's DataModel (such as parts in the Workspace).

It's tempting to try and fit multiple different purposes into a system to make one huge system, but it is important to give
systems a *single responsibility*, to make them small, and to isolate their behavior.

## Single Responsibility

You should design your systems to have a single responsibility. A system
should not do a lot of things, you should try and split up your systems
into smaller systems when you can.

When you start out writing systems, you'll probably find yourself writing
large systems that do many things. You can always go back and split up
your systems afterwards.

## Self Contained

Systems should also be self-contained, with isolated behavior. They should
be designed to not depend on other systems. If we remove a system from
our game, it should only remove the behavior declared in that system.

## Aim for Generic, Reusable Systems

It's commonly said that using an ECS helps to create reusable code. This is
true! Especially if you aim for single-responsibility systems and design
them to be generic.

## Application of these Principles

Let's make a system first, and apply these principles after.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local world = require("@shared/world")
local scheduler = require("@shared/scheduler")

local interval = require("@shared/interval")
local throttle = interval(10)

local Enemy = world:component()
local Health = world:component()
local Position = world:component()
local Velocity = world:component()

local function handleEnemies()
    -- Spawn enemies every 10 seconds
    if throttle() then
        local entity = world:entity()

        world:add(entity, Enemy)
        world:set(entity, Health, 100)
        world:set(entity, Position, Vector3.zero)
        world:set(entity, Velocity, Vector3.new(1, 0, 1))
    end

    -- Move enemies every frame
    for entity, position, velocity in
        world:query(Position, Velocity):with(Enemy):iter()
    do
        local deltaTime = scheduler:getDeltaTime()

        world:set(entity, Position, position * deltaTime * velocity)
    end

    -- Despawn enemies with 0 health
    for entity, health in world:query(Health):with(Enemy):iter()
        if health == 0 then
            world:delete(entity)
        end
    end
end
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
import world from "shared/world";
import scheduler from "shared/scheduler";

import { interval } from "shared/interval";
const throttle = interval(10);

const Enemy = world.component();
const Health = world.component<number>();
const Position = world.component<Vector3>();
const Velocity = world.component<Vector3>();

function handleEnemies() {
    // Spawn enemies every 10 seconds
    if (throttle()) {
        const entity = world.entity();

        world.add(entity, Enemy);
        world.set(entity, Health, 100);
        world.set(entity, Position, Vector3.zero);
        world.set(entity, Velocity, Vector3.new(1, 0, 1));
    }

    // Move enemies every frame
    for (const [entity, position, velocity] of world.query(Position, Velocity).with(Enemy)) {
        const deltaTime = scheduler.getDeltaTime();

        world.set(entity, Position, position * deltaTime * velocity);
    }

    // Despawn enemies with 0 health
    for (const [entity, health] of world.query(Health).with(Enemy)) {
        if (health === 0) {
            world.delete(entity);
        }
    }
}
```
</TabItem>
</Tabs>
This system handles our enemies in our game, it has 3 distinct responsibilities:
spawning enemies, moving enemies, and despawning enemies.

This system will get larger as we add more logic for our enemies, such as reconciling
the position to an actual model, adding cases where enemies may lose health, and other
mechanics onto our enemies.

We should split this system up into multiple, single responsibility systems.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local world = require("@shared/world")

local interval = require("@shared/interval")
local throttle = interval(10)

local Enemy = world:component()
local Health = world:component()
local Position = world:component()
local Velocity = world:component()

local function spawnEnemies()
    -- Spawn enemies every 10 seconds
    if throttle() then
        local entity = world:entity()

        world:add(entity, Enemy)
        world:set(entity, Health, 100)
        world:set(entity, Position, Vector3.zero)
        world:set(entity, Velocity, Vector3.new(1, 0, 1))
    end
end
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
import world from "shared/world";

import { interval } from "shared/interval";
const throttle = interval(10);

const Enemy = world.component();
const Health = world.component<number>();
const Position = world.component<Vector3>();
const Velocity = world.component<Vector3>();

function spawnEnemies() {
    // Spawn enemies every 10 seconds
    if (throttle()) {
        const entity = world.entity();

        world.add(entity, Enemy);
        world.set(entity, Health, 100);
        world.set(entity, Position, Vector3.zero);
        world.set(entity, Velocity, Vector3.new(1, 0, 1));
    }
}
```
</TabItem>
</Tabs>

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local world = require("@shared/world")
local scheduler = require("@shared/scheduler")

local Enemy = world:component()
local Position = world:component()
local Velocity = world:component()

local function moveEnemies()
    -- Move enemies every frame
    for entity, position, velocity in
        world:query(Position, Velocity):with(Enemy):iter()
    do
        local deltaTime = scheduler:getDeltaTime()

        world:set(entity, Position, position * deltaTime * velocity)
    end
end
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
import world from "shared/world";
import scheduler from "shared/scheduler";

const Enemy = world.component();
const Position = world.component<Vector3>();
const Velocity = world.component<Vector3>();

function moveEnemies() {
    // Move enemies every frame
    for (const [entity, position, velocity] of world.query(Position, Velocity).with(Enemy)) {
        const deltaTime = scheduler.getDeltaTime();

        world.set(entity, Position, position * deltaTime * velocity);
    }
}
```
</TabItem>
</Tabs>


<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local world = require("@shared/world")

local Enemy = world:component()
local Health = world:component()

local function despawnEnemies()
    -- Despawn enemies with 0 health
    for entity, health in world:query(Health):with(Enemy):iter()
        if health == 0 then
            world:delete(entity)
        end
    end
end
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
import world from "shared/world";

const Enemy = world.component();
const Health = world.component<number>();

function despawnEnemies() {
    // Despawn enemies with 0 health
    for (const [entity, health] of world.query(Health).with(Enemy)) {
        if (health === 0) {
            world.delete(entity);
        }
    }
}
```
</TabItem>
</Tabs>
When designing systems, we should also think about reusability: how can you reuse a system in other parts of your game?

Well, we might want to move other models besides just Enemies. We can redesign our `moveEnemies` system to be generic.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
```lua
local world = require("@shared/world")
local scheduler = require("@shared/scheduler")

local Enemy = world:component()
local Position = world:component()
local Velocity = world:component()

local function moveModels()
    -- Move models every frame
    for entity, position, velocity in
        world:query(Position, Velocity):iter()
    do
        local deltaTime = scheduler:getDeltaTime()

        world:set(entity, Position, position * deltaTime * velocity)
    end
end
```
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts
import world from "shared/world";
import { Phase } from "@rbxts/planck";

const Enemy = world.component();
const Position = world.component<Vector3>();
const Velocity = world.component<Vector3>();

function moveModels() {
    // Move models every frame
    for (const [entity, position, velocity] of world.query(Position, Velocity)) {
        const deltaTime = scheduler.getDeltaTime();

        world.set(entity, Position, position * deltaTime * velocity);
    }
}
```
</TabItem>
</Tabs>
## What's Next?

Now that we know how to design Systems, we should learn more about Phase and Pipelines.