/**
 * Phases represent tags that tell the scheduler when to
 * schedule a set of systems.
 */
export class Phase {
  /** Runs before the `Startup` Phase. */
  static PreStartup: Phase;
  /**
   * This Phase will run once, the first time the Scheduler is ran,
   * before any other Phases are ran.
   */
  static Startup: Phase;
  /** Runs after the `Startup` phase. */
  static PostStartup: Phase;

  /**
   * Creates a new Phase, with an optional name to use for debugging.
   * When no name is provided, the script and line number will be used.
   */
  constructor(name?: string);
}
