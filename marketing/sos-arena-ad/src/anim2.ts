import { random } from "remotion";

// Camera shake that decays after each impact frame.
export const shake = (frame: number, impacts: number[], strength = 22) => {
  let x = 0, y = 0;
  for (const at of impacts) {
    const t = frame - at;
    if (t < 0 || t > 12) continue;
    const k = strength * (1 - t / 12);
    x += (random(`sx${at}-${t}`) - 0.5) * 2 * k;
    y += (random(`sy${at}-${t}`) - 0.5) * 2 * k;
  }
  return `${x}px ${y}px`;
};
