---
title: Jabby
description: A Plugin to add support for Jabby
sidebar_position: 1
---

import Tabs from "@theme/Tabs";
import TabItem from "@theme/TabItem";

[Jabby](https://github.com/alicesaidhi/jabby), by alicesaidhi, is a Debugger developed for [Jecs](https://github.com/Ukendio/jecs), an ECS library by Ukendio.
This Plugin handles all setup to add the Planck Scheduler to Jabby.

### Installation

<Tabs groupId="package-manager">
<TabItem value="wally" label="Wally">
```toml title="wally.toml"
[dependencies]
PlanckJabby = "yetanotherclown/planck-jabby@0.2.0"
```
</TabItem>
<TabItem value="npm" label="NPM">
Run `npm i @rbxts/planck-jabby` in your terminal.
</TabItem>
</Tabs>

### Setup and Use

First, we need to create the scheduler, and add the Jabby Plugin to it.

<Tabs groupId="language">
<TabItem value="lua" label="Luau">
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
</TabItem>
<TabItem value="ts" label="TypeScript">
```ts title="src/shared/scheduler.ts"
import { Scheduler } from "@rbxts/planck";

import world from "shared/world";

import PlanckJabby from "@rbxts/planck-jabby";
const jabbyPlugin = new PlanckJabby();

const scheduler = new Scheduler(world)
    .addPlugin(jabbyPlugin);

export default scheduler;
```
</TabItem>
</Tabs>
This only adds the Scheduler to Jabby, you'll have to add the
World and other setup yourself.
