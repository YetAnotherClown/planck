import type { Plugin } from ".";
import type { Condition } from "./conditions";
import type { Phase } from "./Phase";
import type { Pipeline } from "./Pipeline";
import type { EventInstance, EventLike, ExtractEvents } from "./utils";

/**
 * A system function that executes game logic with provided arguments. Runs each
 * time the scheduler runs it. A system should not return a value.
 *
 * @example
 *
 * ```ts
 * function movementSystem(world: World): void {
 *   // Update entity positions
 * }
 * ```
 */
export type SystemFn<T extends unknown[]> = (...args: T) => void | undefined;

/**
 * A cleanup function that executes when a system is removed from the scheduler.
 * Used for resource cleanup when a system is unscheduled, or in hot-reload
 * scenarios.
 */
export type CleanupFn<T extends unknown[]> = (...args: T) => void | undefined;

/**
 * The runtime system and optional cleanup function returned from
 * initialization.
 *
 * At least one field must be present:
 *
 * - `system`: Runtime function that runs on each execution after initialization
 * - `cleanup`: Cleanup function for hot-reload support.
 *
 * @example
 *
 * ```ts
 * // Runtime system with cleanup
 * return {
 *   system: (world) => updateLogic(world),
 *   cleanup: () => cleanupResources(),
 * };
 * ```
 */
export interface InitializerResult<T extends unknown[]> {
  /**
   * Runtime system function that executes immediately after initialization and
   * on all subsequent frames.
   */
  system?: SystemFn<T>;
  /** Cleanup function that runs when the system is removed. */
  cleanup?: CleanupFn<T>;
}

/**
 * An initializer system that performs one-time setup and returns the runtime
 * system. The initialization logic runs once on first execution, then the
 * returned function executes immediately and on all subsequent executions.
 *
 * @example
 *
 * ```ts
 * // Function return syntax
 * function renderSystem(world: World): SystemFn<[World]> {
 *   const renderables = world.query(Transform, Model).cached();
 *
 *   return (world: World) => {
 *     for (const [entity, transform, model] of renderables) {
 *       render(transform, model);
 *     }
 *   };
 * }
 *
 * // With cleanup
 * function renderSystem(world: World): InitializerResult<[World]> {
 *   const renderables = world.query(Transform, Model).cached();
 *   return {
 *     system: (world: World) => {
 *       for (const [entity, transform, model] of renderables) {
 *         render(transform, model);
 *       }
 *     },
 *   };
 * }
 * ```
 */
export type InitializerSystemFn<T extends unknown[]> = (
  ...args: T
) => InitializerResult<T> | LuaTuple<[SystemFn<T>, CleanupFn<T>]> | SystemFn<T>;
 
/**
 * Base configuration shared by all system table types. Contains optional
 * metadata and execution conditions.
 */
export interface BaseSystemTable<T extends unknown[]> {
  /** Allow additional properties for plugin extensibility. */
  [key: string]: unknown;
  /** Human-readable name for debugging and profiling. */
  name?: string;
  /** The execution phase for this system. Defaults to Main phase. */
  phase?: Phase;
  /** Conditions that must be met for the system to execute. */
  runConditions?: Condition<T>[];
}

/**
 * Configuration table for systems. Supports standard systems, initializer
 * systems, and initializers with cleanup.
 */
export interface SystemTable<T extends unknown[]> extends BaseSystemTable<T> {
  system: InitializerSystemFn<T> | SystemFn<T>;
}

/**
 * A system can be either a function or a configuration table. Use a function
 * for simple systems, or a table for systems that need additional configuration
 * like phases, run conditions, or names.
 *
 * Systems can optionally perform one-time initialization by returning a
 * function on their first execution. See {@link InitializerSystemFn} for
 * initialization patterns.
 *
 * @example
 *
 * ```ts
 * // Standard system (runs repeatedly)
 * function updateSystem(world: World): void {
 *   // update entities
 * }
 *
 * // Initializer system (setup runs once, then inner runs immediately)
 * function movementSystem(world: World): SystemFn<[World]> {
 *   const entities = world.query(Transform, Velocity).cached();
 *   return (world) => {
 *     for (const [, transform, velocity] of entities) {
 *       transform.position.add(velocity);
 *     }
 *   };
 * }
 *
 * // Simple function system
 * export = updateSystem;
 *
 * // Table system with configuration
 * export = {
 *   name: "Complex System",
 *   system: audioSystem,
 *   phase: Phases.Update,
 *   runConditions: [onlyWhenNeeded],
 * };
 * ```
 */
export type System<T extends unknown[]> = InitializerSystemFn<T> | SystemFn<T> | SystemTable<T>;

/**
 * An Object which handles scheduling Systems to run within different Phases.
 * The order of which Systems run will be defined either implicitly by when it
 * was added, or explicitly by tagging the system with a Phase.
 */
export class Scheduler<T extends unknown[]> {
  /**
   * Creates a new Scheduler, the args passed will be passed to any System
   * anytime it is ran by the Scheduler.
   */
  constructor(...args: T);

  /**
   * Initializes a plugin with the scheduler, see the [Plugin
   * Docs](/docs/plugins) for more information.
   */
  addPlugin(plugin: Plugin<T>): this;

  /**
   * Adds the System to the Scheduler, scheduling it to be ran implicitly within
   * the provided Phase or on the default Main phase.
   */
  addSystem(system: System<T>, phase?: Phase): this;

  /**
   * Adds the Systems to the Scheduler, scheduling them to be ran implicitly
   * within the provided Phase or on the default Main phase.
   */
  addSystems(systems: System<T>[], phase?: Phase): this;

  /** Changes the Phase that this system is scheduled on. */
  editSystem(system: System<T>, newPhase: Phase): this;

  /**
   * Removes the System from the Scheduler.
   *
   * If the system provided a cleanup function, that cleanup executes before
   * removal.
   *
   * @example
   *
   * ```ts
   * const networkSystem = (world: World) => {
   *   const conn = connect();
   *   return {
   *     system: (world: World) => sync(conn),
   *     cleanup: () => conn.disconnect(), // Runs on removeSystem
   *   };
   * };
   *
   * scheduler.addSystem(networkSystem, Phases.Update);
   * // Later...
   * scheduler.removeSystem(networkSystem); // Cleanup executes
   * ```
   */
  removeSystem(system: System<T>): this;

  /** Replaces the System with a new System. */
  replaceSystem(system: System<T>, newSystem: System<T>): this;

  /**
   * Returns the time since the system was ran last. This must be used within a
   * registered system.
   */
  getDeltaTime(): number;

  /**
   * Initializes the Phase within the Scheduler, ordering it implicitly by
   * setting it as a dependent of the previous Phase/Pipeline.
   */
  insert(phase: Phase): this;
  /**
   * Initializes the Pipeline and it's Phases within the Scheduler, ordering the
   * Pipeline implicitly by setting it as a dependent of the previous
   * Phase/Pipeline.
   */
  insert(pipeline: Pipeline): this;
  /**
   * Initializes the Phase within the Scheduler, ordering it implicitly by
   * setting it as a dependent of the previous Phase/Pipeline, and scheduling it
   * to be ran on the specified event.
   *
   * ```ts
   * const myScheduler = new Scheduler().insert(
   *   myPhase,
   *   RunService,
   *   "Heartbeat",
   * );
   * ```
   */
  insert<T extends EventInstance>(phase: Phase, instance: T, event: ExtractEvents<T>): this;
  /**
   * Initializes the Phase within the Scheduler, ordering it implicitly by
   * setting it as a dependent of the previous Phase/Pipeline, and scheduling it
   * to be ran on the specified event.
   *
   * ```ts
   * const myScheduler = new Scheduler().insert(
   *   myPhase,
   *   RunService,
   *   "Heartbeat",
   * );
   * ```
   */
  insert(phase: Phase, instance: EventLike, event: string): this;
  /**
   * Initializes the Pipeline and it's Phases within the Scheduler, ordering the
   * Pipeline implicitly by setting it as a dependent of the previous
   * Phase/Pipeline, and scheduling it to be ran on the specified event.
   *
   * ```ts
   * const myScheduler = new Scheduler().insert(
   *   myPipeline,
   *   RunService,
   *   "Heartbeat",
   * );
   * ```
   */
  insert<T extends EventInstance>(pipeline: Pipeline, instance: T, event: ExtractEvents<T>): this;
  /**
   * Initializes the Pipeline and it's Phases within the Scheduler, ordering the
   * Pipeline implicitly by setting it as a dependent of the previous
   * Phase/Pipeline, and scheduling it to be ran on the specified event.
   *
   * ```ts
   * const myScheduler = new Scheduler().insert(
   *   myPipeline,
   *   RunService,
   *   "Heartbeat",
   * );
   * ```
   */
  insert(pipeline: Pipeline, instance: EventLike, event: string): this;

  /**
   * Initializes the Phase within the Scheduler, ordering it explicitly by
   * setting the after Phase/Pipeline as a dependent.
   */
  insertAfter(phase: Phase, after: Phase | Pipeline): this;
  /**
   * Initializes the Pipeline and it's Phases within the Scheduler, ordering the
   * Pipeline explicitly by setting the after Phase/Pipeline as a dependent.
   */
  insertAfter(pipeline: Pipeline, after: Phase | Pipeline): this;

  /**
   * Initializes the Phase within the Scheduler, ordering it explicitly by
   * setting the before Phase/Pipeline as a dependency.
   */
  insertBefore(phase: Phase, before: Phase | Pipeline): this;
  /**
   * Initializes the Pipeline and it's Phases within the Scheduler, ordering the
   * Pipeline explicitly by setting the before Phase/Pipeline as a dependency.
   */
  insertBefore(pipeline: Pipeline, before: Phase | Pipeline): this;

  /**
   * Adds a Run Condition which the Scheduler will check before this System is
   * ran.
   */
  addRunCondition(system: System<T>, fn: Condition<T>, ...args: any): this;
  /**
   * Adds a Run Condition which the Scheduler will check before any Systems
   * within this Phase are ran.
   */
  addRunCondition(phase: Phase, fn: Condition<T>, ...args: any): this;
  /**
   * Adds a Run Condition which the Scheduler will check before any Systems
   * within any Phases apart of this Pipeline are ran.
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
   * When you add a Pipeline or Phase with an event, it will be grouped with
   * other Pipelines/Phases on that event. Otherwise, it will be added to the
   * default group.
   *
   * When not running systems on Events, such as with the `runAll` method, the
   * Default group will be ran first, and then each Event Group in the order
   * created.
   *
   * Pipelines/Phases in these groups are still ordered by their dependencies
   * and by the order of insertion.
   */
  runAll(): this;

  /**
   * Disconnects all events, closes all threads, and performs other cleanup
   * work.
   *
   * ### Danger
   *
   * Only use this if you intend to not use the associated Scheduler anymore. It
   * will not work as intended.
   *
   * You should dereference the scheduler object so that it may be garbage
   * collected.
   *
   * ### Warning
   *
   * If you're creating a "throwaway" scheduler, you should not add plugins like
   * Jabby or the Matter Debugger to it. These plugins are unable to properly be
   * cleaned up, use them with caution.
   */
  cleanup(): void;
}
