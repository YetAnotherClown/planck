---
title: Introduction
description: An introduction to Planck
sidebar_position: 1
---

## Installation

Planck is available for installation via Wally or as a `.rbxm` in GitHub Releases.

To install for wally, you can do:
```toml
[dependencies]
Planck = "yetanotherclown/planck@0.2.0"
```

It's suggested you get it installed before we continue, following along
while reading will help you better understand Planck.

## What is Planck?

Planck is a standalone scheduler, which allows you to execute code on specific events, with certain conditions, and in a particular order.

This scheduler is library agnostic, which means that it *doesn't matter* which ECS library your using or if you're even using an ECS.
You can use this with [Jecs], [Matter], [ECR], and other Luau ECS Libraries.

## Does any of this really matter?

Yes, and no.
Your ECS code should be able to run in any order, without any conditions, and without concern for which event it's running on, as long as *it is* running.

The order of execution, and conditions both serve to *optimize* your code. Some systems don't need to run every frame, which is why we have conditions.
And the actual order of execution is to reduce latency between changes and effects in your ECS world.

Let's say we have `systemA` and `systemB`. `systemA` modifies data in our world which `systemB` depends on.
If `systemA` runs *after* `systemB`, then `systemB` will have to wait a whole frame for the modifications to be made.
This is called being *off-by-a-frame*, and this is why we care about the order of execution.

## What's Next?

You may not completely understand what's written above. That's fine.

These concepts will continue to be explained as you learn more about Planck. For now, learn about the basics of Planck, such as the Scheduler, Systems,
and Phases. These are the very basics that are needed to setup and use Planck. Consider them the 'bare minium' required to build a game with Planck.

→ [The Scheduler](./scheduler.md)

## Inspiration

Planck's API design is heavily influenced by the [Bevy Engine](https://bevyengine.org/), with Schedules, RunConditions, and more.
Planck also draws inspiration from [Flecs](https://www.flecs.dev/) for Pipelines and Phases.

We're combining the simple, and beloved API of Bevy with the concept of Pipelines and Phases.

[Jecs]: https://ukendio.github.io/jecs
[Matter]: https://matter-ecs.github.io/matter
[ECR]: https://centau.github.io/ecr/
