export class Phase {
  static PreStartup: Phase;
  static Startup: Phase;
  static PostStartup: Phase;

  constructor(name?: string);
}
