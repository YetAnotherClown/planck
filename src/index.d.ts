type VoidCallback<T extends unknown[]> = (...args: T) => void;

type UnknownCallback<T extends unknown[]> = (...args: T) => unknown;

type SystemFn<T extends unknown[]> = VoidCallback<T> | UnknownCallback<T>;

type SystemTable<T extends unknown[]> = {
    system: SystemFn<T>;
    phase: unknown;
};

type System<T extends unknown[]> = SystemFn<T> | SystemTable<T>;

type EventLike =
    | RBXScriptSignal
    | {
        connect: (self: EventLike, ...args: unknown[]) => unknown;
    } & Record<string, unknown>
    | {
        Connect: (self: EventLike, ...args: unknown[]) => unknown;
    } & Record<string, unknown>
    | {
        on: (self: EventLike, ...args: unknown[]) => unknown;
    } & Record<string, unknown>;

type EventInstance = Instance | {};

export declare class Phase {
    constructor(debugName: string);
    public PreStartup: Phase;
    public Startup: Phase;
    public PostStartup: Phase;
    public PreRender: Phase;
    public PreAnimation: Phase;
    public PreSimulation: Phase;
    public PostSimulation: Phase;
    public First: Phase;
    public PreUpdate: Phase;
    public Update: Phase;
    public PostUpdate: Phase;
    public Last: Phase;
}

export declare class Pipeline {
    constructor(debugName?: string);
    public Main: Pipeline;
    public Startup: Pipeline;
    insert: (phase: Phase) => Pipeline;
    insertAfter: (phase: Phase, after: Phase) => Pipeline;
}

declare class Plugin<T extends unknown[]> {
    build: (scheduler: T) => void;
}

export declare class Scheduler<T extends unknown[]> {
    constructor(...args: T);

    addPlugin: (plugin: Plugin<T>) => Scheduler<T>;

    addSystems: (systems: System<T> | Array<System<T>>, phase?: Phase) => Scheduler<T>;

    editSystem: (system: System<T>, newPhase: Phase) => Scheduler<T>;

    replaceSystem: (system: System<T>, newSystem: System<T>) => Scheduler<T>;

    removeSystem: (system: System<T>) => Scheduler<T>;

    setRunCondition: ((system: System<T>, fn: (...args: T) => boolean) => Scheduler<T>) &
        ((phase: Phase, fn: (...args: T) => boolean) => Scheduler<T>) &
        ((pipeline: Pipeline, fn: (...args: T) => boolean) => Scheduler<T>);

    run: ((system: System<T>) => Scheduler<T>) &
        ((phase: Phase) => Scheduler<T>) &
        ((pipeline: Pipeline) => Scheduler<T>);

    insert: ((phase: Phase) => Scheduler<T>) &
        ((pipeline: Pipeline) => Scheduler<T>) &
        ((
            phase: Phase,
            instance: EventInstance | EventLike,
            event: string | EventLike
        ) => Scheduler<T>) &
        ((
            pipeline: Pipeline,
            instance: EventInstance | EventLike,
            event: string | EventLike
        ) => Scheduler<T>);

    insertAfter: ((phase: Phase, after: Phase | Pipeline) => Scheduler<T>) &
        ((pipeline: Pipeline, after: Phase | Pipeline) => Scheduler<T>);
}
