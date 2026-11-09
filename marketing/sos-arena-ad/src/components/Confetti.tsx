import React from "react";
import { random, useCurrentFrame } from "remotion";
import { C } from "../theme";

const COLORS = [C.arenaBlue, C.secondary, C.arenaPink, C.arenaGold, C.tertiaryContainer, C.primaryContainer];

export const Confetti: React.FC<{ count?: number; start?: number; w?: number; h?: number }> = ({
  count = 90, start = 0, w = 1080, h = 1350,
}) => {
  const frame = useCurrentFrame() - start;
  if (frame < 0) return null;
  return (
    <>
      {Array.from({ length: count }, (_, i) => {
        const angle = random(`a${i}`) * Math.PI * 2;
        const v = 18 + random(`v${i}`) * 26;
        const t = frame;
        const x = w / 2 + Math.cos(angle) * v * t * 0.9;
        const y = h * 0.42 + Math.sin(angle) * v * t * 0.6 + 0.9 * t * t * 0.5;
        const sz = 12 + random(`sz${i}`) * 16;
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: x,
              top: y,
              width: sz,
              height: sz * (random(`r${i}`) > 0.5 ? 0.45 : 1),
              borderRadius: random(`c${i}`) > 0.6 ? sz : 3,
              background: COLORS[i % COLORS.length],
              rotate: `${t * (8 + random(`rot${i}`) * 14)}deg`,
              opacity: Math.max(0, 1 - t / 70),
            }}
          />
        );
      })}
    </>
  );
};
