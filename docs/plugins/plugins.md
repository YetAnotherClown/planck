---
title: Plugins
description: About Planck Plugins
sidebar_position: 4
---

Plugins in Planck allow you to incorporate it easily into other ECS tooling and libraries.

And also, for example, instead of including the Matter topoRuntime in Planck itself,
you choose whether or not to include it. This ensures you only ever get what you need.

## Provided Plugins

### Matter Hooks

The Matter Hooks plugin provides a way to use the Matter topoRuntime to use any
hook made for Matter. **This can be used with any ECS library.**

:::tip
The Matter Hooks Plugin can be used with any ECS library, like Jecs or ECR.
If you want to still use hooks when using Matter, you must still add this
Plugin to the Scheduler for hooks to work.
:::

See the [Matter Hooks](/docs/plugins/matter_hooks) page.

### Matter Debugger

Matter provides a built-in Debugger, this plugin adds support for Planck.

See the [Matter Debugger](/docs/plugins/matter_debugger) page.

### Jabby

Jabby is a Debugger for Jecs by Ukendio. This Plugin handles all setup to
add the Planck Scheduler to Jabby.

See the [Jabby](/docs/plugins/jabby) page.

## Creating Plugins

See [Creating Plugins](/docs/plugins/creating).
