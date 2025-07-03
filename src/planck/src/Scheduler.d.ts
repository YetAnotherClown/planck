import { Plugin } from ".";
import { Condition } from "./conditions";
import { Phase } from "./Phase";
import { Pipeline } from "./Pipeline";
import { EventInstance, EventLike, ExtractEvents } from "./utils";

export type SystemFn<T extends unknown[]> = (...args: T) => any;
export interface SystemTable<T extends unknown[]> {
  system: SystemFn<T>;
  phase?: Phase;
  name?: string;
  runConditions?: Condition<T>[];
  [key: string]: any;
}
export type System<T extends unknown[]> = SystemTable<T> | SystemFn<T>;

/**
 * An Object which handles scheduling Systems to run within different
 * Phases. The order of which Systems run will be defined either
 * implicitly by when it was added, or explicitly by tagging the system
 * with a Phase.
 */
export class Scheduler<T extends unknown[]> {
  /**
   * Creates a new Scheduler, the args passed will be passed to
   * any System anytime it is ran by the Scheduler.
   */
  constructor(...args: T);

  /** Initializes a plugin with the scheduler, see the [Plugin Docs](/docs/plugins) for more information. */
  addPlugin(plugin: Plugin<T>): this;

  /**
   * Adds the System to the Scheduler, scheduling it to be ran
   * implicitly within the provided Phase or on the default Main phase.
   */
  addSystem(system: System<T>, phase?: Phase): this;

  /**
   * Adds the Systems to the Scheduler, scheduling them to be ran
   * implicitly within the provided Phase or on the default Main phase.
   */
  addSystems(systems: System<T>[], phase?: Phase): this;

  /** Changes the Phase that this system is scheduled on. */
  editSystem(system: System<T>, newPhase: Phase): this;

  /** Removes the System from the Scheduler. */
  removeSystem(system: System<T>): this;

  /** Replaces the System with a new System. */
  replaceSystem(system: System<T>, newSystem: System<T>): this;

  /**
   * Returns the time since the system was ran last.
   * This must be used within a registered system.
   */
  getDeltaTime(): number;

  /**
   * Initializes the Phase within the Scheduler, ordering it implicitly by
   * setting it as a dependent of the previous Phase/Pipeline.
   */
  insert(phase: Phase): this;
  /**
   * Initializes the Pipeline and it's Phases within the Scheduler,
   * ordering the Pipeline implicitly by setting it as a dependent
   * of the previous Phase/Pipeline.
   */
  insert(pipeline: Pipeline): this;
  /**
   * Initializes the Phase within the Scheduler, ordering it implicitly
   * by setting it as a dependent of the previous Phase/Pipeline, and
   * scheduling it to be ran on the specified event.
   *
   * ```ts
   * const myScheduler = new Scheduler()
   *     .insert(myPhase, RunService, "Heartbeat")
   * ```
   */
  insert<T extends EventInstance>(
    phase: Phase,
    instance: T,
    event: ExtractEvents<T>
  ): this;
  /**
   * Initializes the Phase within the Scheduler, ordering it implicitly
   * by setting it as a dependent of the previous Phase/Pipeline, and
   * scheduling it to be ran on the specified event.
   *
   * ```ts
   * const myScheduler = new Scheduler()
   *     .insert(myPhase, RunService, "Heartbeat")
   * ```
   */
  insert(phase: Phase, instance: EventLike, event: string): this;
  /**
   * Initializes the Pipeline and it's Phases within the Scheduler,
   * ordering the Pipeline implicitly by setting it as a dependent of
   * the previous Phase/Pipeline, and scheduling it to be ran on the
   * specified event.
   *
   * ```ts
   * const myScheduler = new Scheduler()
   *     .insert(myPipeline, RunService, "Heartbeat")
   * ```
   */
  insert<T extends EventInstance>(
    pipeline: Pipeline,
    instance: T,
    event: ExtractEvents<T>
  ): this;
  /**
   * Initializes the Pipeline and it's Phases within the Scheduler,
   * ordering the Pipeline implicitly by setting it as a dependent of
   * the previous Phase/Pipeline, and scheduling it to be ran on the
   * specified event.
   *
   * ```ts
   * const myScheduler = new Scheduler()
   *     .insert(myPipeline, RunService, "Heartbeat")
   * ```
   */
  insert(pipeline: Pipeline, instance: EventLike, event: string): this;

  /**
   * Initializes the Phase within the Scheduler, ordering it
   * explicitly by setting the after Phase/Pipeline as a dependent.
   */
  insertAfter(phase: Phase, after: Phase | Pipeline): this;
  /**
   * Initializes the Pipeline and it's Phases within the Scheduler,
   * ordering the Pipeline explicitly by setting the after Phase/Pipeline
   * as a dependent.
   */
  insertAfter(pipeline: Pipeline, after: Phase | Pipeline): this;

  /**
   * Initializes the Phase within the Scheduler, ordering it
   * explicitly by setting the before Phase/Pipeline as a dependency.
   */
  insertBefore(phase: Phase, before: Phase | Pipeline): this;
  /**
   * Initializes the Pipeline and it's Phases within the Scheduler,
   * ordering the Pipeline explicitly by setting the before Phase/Pipeline
   * as a dependency.
   */
  insertBefore(pipeline: Pipeline, before: Phase | Pipeline): this;

  /**
   * Adds a Run Condition which the Scheduler will check before
   * this System is ran.
   */
  addRunCondition(system: System<T>, fn: Condition<T>, ...args: any): this;
  /**
   * Adds a Run Condition which the Scheduler will check before
   * any Systems within this Phase are ran.
   */
  addRunCondition(phase: Phase, fn: Condition<T>, ...args: any): this;
  /**
   * Adds a Run Condition which the Scheduler will check before
   * any Systems within any Phases apart of this Pipeline are ran.
   */
  addRunCondition(pipeline: Pipeline, fn: Condition<T>, ...args: any): this;

  /** Runs all Systems tagged with the Phase in order. */
  run(system: Phase): this;
  /** Runs all Systems tagged with any Phase within the Pipeline in order. */
  run(pipeline: Pipeline): this;
  /** Runs the System, passing in the arguments of the Scheduler, `U...`. */
  run(system: System<T>): this;

  /**
   * Runs all Systems within order.
   *
   * ### NOTE
   *
   * When you add a Pipeline or Phase with an event, it will be grouped
   * with other Pipelines/Phases on that event. Otherwise, it will be
   * added to the default group.
   *
   * When not running systems on Events, such as with the `runAll` method,
   * the Default group will be ran first, and then each Event Group in the
   * order created.
   *
   * Pipelines/Phases in these groups are still ordered by their dependencies
   * and by the order of insertion.
   */
  runAll(): this;

  /**
   * Disconnects all events, closes all threads, and performs
   * other cleanup work.
   *
   * ### Danger
   * Only use this if you intend to not use the associated
   * Scheduler anymore. It will not work as intended.
   *
   * You should dereference the scheduler object so that
   * it may be garbage collected.
   *
   * ### Warning
   * If you're creating a "throwaway" scheduler, you should
   * not add plugins like Jabby or the Matter Debugger to it.
   * These plugins are unable to properly be cleaned up, use
   * them with caution.
   */
  cleanup(): void;
}
