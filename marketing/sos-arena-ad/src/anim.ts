import { Easing, interpolate, spring } from "remotion";
import { FPS } from "./theme";

const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

export const lerp = (
  f: number,
  input: number[],
  output: number[],
  easing: (t: number) => number = Easing.bezier(0.16, 1, 0.3, 1),
) => interpolate(f, input, output, { ...clamp, easing });

export const pop = (f: number, delay = 0, damping = 11, mass = 0.7) =>
  spring({ frame: f - delay, fps: FPS, config: { damping, mass, stiffness: 160 } });

export const smooth = (f: number, delay = 0) =>
  spring({ frame: f - delay, fps: FPS, config: { damping: 200 } });
