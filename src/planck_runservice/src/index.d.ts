import { Phase, Pipeline, Scheduler } from "@rbxts/planck";

export class Plugin<T extends unknown[]> {
  build(scheduler: Scheduler<T>): void;
}

export const Phases: {
  PreRender: Phase;
  PreAnimation: Phase;
  PreSimulation: Phase;
  PostSimulation: Phase;

  First: Phase;
  PreUpdate: Phase;
  Update: Phase;
  PostUpdate: Phase;
  Last: Phase;
};

export const Pipelines: {
  Heartbeat: Pipeline;
  PreRender: Pipeline;
  PreAnimation: Pipeline;
  PreSimulation: Pipeline;
  PostSimulation: Pipeline;
};
