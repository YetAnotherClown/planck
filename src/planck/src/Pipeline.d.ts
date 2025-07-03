import { Phase } from "./Phase";

/**
 * Pipelines represent a set of ordered Phases. Systems cannot be
 * assigned to Pipelines themselves, but rather to Phases within
 * those Pipelines.
 */
export class Pipeline {
  /** A Pipeline containing the `PreStartup`, `Startup`, and `PostStartup` phases. */
  static Startup: Pipeline;

  /**
   * Creates a new Pipeline, with an optional name to use for debugging.
   * When no name is provided, the script and line number will be used.
   */
  constructor(name?: string);

  /** Adds a Phase to the Pipeline, ordering it implicitly. */
  insert(phase: Phase): this;
  /** Adds a Phase to the Pipeline after another Phase, ordering it explicitly. */
  insertAfter(phase: Phase, after: Phase): this;
  /** Adds a Phase to the Pipeline before another Phase, ordering it explicitly. */
  insertBefore(phase: Phase, before: Phase): this;
}
