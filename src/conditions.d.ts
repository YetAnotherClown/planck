export type Condition = () => boolean;

export const timePassed: (time: number) => Condition;

export const runOnce: () => Condition;

export const onEvent: () => LuaTuple<[]>;

export const isNot: (fn: () => boolean) => Condition;
