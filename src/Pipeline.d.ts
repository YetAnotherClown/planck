import { Phase } from "./Phase";

export class Pipeline {
  constructor(name?: string);

  insert(phase: Phase): this;
  insertAfter(phase: Phase, after: Phase): this;
  insertBefore(phase: Phase, after: Phase): this;
}
