import { Phase, Pipeline, Scheduler } from "@rbxts/planck";
import type { Plugin as PluginInterface } from "@rbxts/planck";

export class Plugin<T extends unknown[]> implements PluginInterface<T> {
  build(scheduler: Scheduler<T>): void;
  cleanup(): void;
}

export const Phases: {
  /**
   * Runs on `RunService.PreRender`.
   *
   * RunService.PreRender is equivalent to `RunService.RenderStepped`.
   */
  PreRender: Phase;
  /** Runs on `RunService.PreAnimation`. */
  PreAnimation: Phase;
  /**
   * Runs on `RunService.PreSimulation`.
   *
   * `RunService.PreSimulation` is equivalent to `RunService.Stepped`.
   */
  PreSimulation: Phase;
  /** Runs on `RunService.PostSimulation`. */
  PostSimulation: Phase;

  /**
   * The first Phase to run in the `Update` Pipeline,
   * runs before the `PreUpdate` Phase.
   */
  First: Phase;
  /** Runs before the `Update` Phase. */
  PreUpdate: Phase;
  /**
   * Runs on `RunService.Heartbeat`. This is the default
   * Phase that all systems will be added to unless
   * otherwise specified.
   */
  Update: Phase;
  /** Runs before the `Last` Phase. */
  PostUpdate: Phase;
  /** The last Phase to run in the `Update` Pipeline. */
  Last: Phase;
};

export const Pipelines: {
  Heartbeat: Pipeline;
  PreRender: Pipeline;
  PreAnimation: Pipeline;
  PreSimulation: Pipeline;
  PostSimulation: Pipeline;
};
