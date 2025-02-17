import { Condition } from "./conditions";
import { Phase } from "./Phase";
import { Pipeline } from "./Pipeline";
import { EventInstance, EventLike, ExtractEvents } from "./utils";

export type SystemFn<T extends unknown[]> = (...args: T) => void;
export interface SystemTable<T extends unknown[]> {
  system: SystemFn<T>;
  phase?: Phase;
}
export type System<T extends unknown[]> = SystemTable<T> | SystemFn<T>;

export class Scheduler<T extends unknown[]> {
  addPlugin(plugin: unknown): this;

  addSystem(system: System<T>, phase?: Phase): this;

  addSystems(systems: System<T>[], phase?: Phase): this;

  editSystem(system: System<T>, newPhase: Phase): this;

  getDeltaTime(): number;

  insert(phase: Phase): this;
  insert(pipeline: Pipeline): this;
  insert<T extends EventInstance>(phase: Phase, instance: EventInstance, event: ExtractEvents<T>): this;
  insert(phase: Phase, event: EventLike): this;
  insert<T extends EventInstance>(pipeline: Pipeline, instance: EventInstance, event: ExtractEvents<T>): this;
  insert(pipeline: Pipeline, event: EventLike): this;

  insertAfter(phase: Phase, after: Phase | Pipeline): this;
  insertAfter(pipeline: Pipeline, after: Phase | Pipeline): this;

  insertBefore(phase: Phase, before: Phase | Pipeline): this;
  insertBefore(pipeline: Pipeline, before: Phase | Pipeline): this;

  removeSystem(system: System<T>): this;

  replaceSystem(system: System<T>, newSystem: System<T>): this;

  addRunCondition(system: System<T>, fn: Condition): this;
  addRunCondition(phase: Phase, fn: Condition): this;
  addRunCondition(pipeline: Pipeline, fn: Condition): this;

  run(system: Phase): this;
  run(pipeline: Pipeline): this;
  run(system: System<T>): this;

  runAll(): this;
}
