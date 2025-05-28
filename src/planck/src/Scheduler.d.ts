import { Condition } from "./conditions";
import { Phase } from "./Phase";
import { Pipeline } from "./Pipeline";
import { EventInstance, EventLike, ExtractEvents } from "./utils";

export type SystemFn<T extends unknown[]> = (...args: T) => void;
export interface SystemTable<T extends unknown[]> {
  system: SystemFn<T>;
  phase?: Phase;
  name?: string;
  runConditions?: Condition<T>[];
}
export type System<T extends unknown[]> = SystemTable<T> | SystemFn<T>;

export class Scheduler<T extends unknown[]> {
  constructor(...args: T);

  addPlugin(plugin: unknown): this;

  addSystem(system: System<T>, phase?: Phase): this;

  addSystems(systems: System<T>[], phase?: Phase): this;

  editSystem(system: System<T>, newPhase: Phase): this;

  getDeltaTime(): number;

  insert(phase: Phase): this;
  insert(pipeline: Pipeline): this;
  insert<T extends EventInstance>(phase: Phase, instance: T, event: ExtractEvents<T>): this;
  insert(phase: Phase, instance: EventLike, event: string): this;
  insert<T extends EventInstance>(pipeline: Pipeline, instance: T, event: ExtractEvents<T>): this;
  insert(pipeline: Pipeline, instance: EventLike, event: string): this;

  insertAfter(phase: Phase, after: Phase | Pipeline): this;
  insertAfter(pipeline: Pipeline, after: Phase | Pipeline): this;

  insertBefore(phase: Phase, before: Phase | Pipeline): this;
  insertBefore(pipeline: Pipeline, before: Phase | Pipeline): this;

  removeSystem(system: System<T>): this;

  replaceSystem(system: System<T>, newSystem: System<T>): this;

  addRunCondition(system: System<T>, fn: Condition<T>): this;
  addRunCondition(phase: Phase, fn: Condition<T>): this;
  addRunCondition(pipeline: Pipeline, fn: Condition<T>): this;

  run(system: Phase): this;
  run(pipeline: Pipeline): this;
  run(system: System<T>): this;

  runAll(): this;
}
