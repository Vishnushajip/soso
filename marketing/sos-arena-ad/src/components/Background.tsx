import React from "react";
import { AbsoluteFill, random, useCurrentFrame, useVideoConfig } from "remotion";
import { C, HEADING, alpha } from "../theme";

// The "Dark Arena" backdrop: night sky to deep pit, lava glow, drifting letters.
export const Background: React.FC<{ tint?: string }> = ({ tint = C.primary }) => {
  const frame = useCurrentFrame();
  const { width, height } = useVideoConfig();
  const letters = Array.from({ length: 22 }, (_, i) => {
    const x = random(`x${i}`) * width;
    const speed = 0.6 + random(`s${i}`) * 1.4;
    const y = ((random(`y${i}`) * (height + 300) - frame * speed) % (height + 300) + height + 300) % (height + 300) - 150;
    const size = 50 + random(`z${i}`) * 140;
    const isS = random(`l${i}`) > 0.5;
    return (
      <div
        key={i}
        style={{
          position: "absolute",
          left: x,
          top: y,
          fontFamily: HEADING,
          fontSize: size,
          color: isS ? C.arenaBlue : C.secondary,
          opacity: 0.07 + random(`o${i}`) * 0.1,
          filter: `blur(${size > 140 ? 6 : 2}px)`,
          rotate: `${Math.sin((frame + i * 20) / 40) * 20}deg`,
        }}
      >
        {isS ? "S" : "O"}
      </div>
    );
  });
  const stars = Array.from({ length: 40 }, (_, i) => (
    <div
      key={i}
      style={{
        position: "absolute",
        left: random(`sx${i}`) * width,
        top: random(`sy${i}`) * height * 0.7,
        width: 4,
        height: 4,
        borderRadius: 4,
        background: "white",
        opacity: 0.15 + 0.5 * Math.abs(Math.sin(frame / 12 + i)),
      }}
    />
  ));
  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(180deg, ${C.arenaBgTop} 0%, ${C.arenaBgBottom} 100%)`,
        overflow: "hidden",
      }}
    >
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse 90% 45% at 50% 0%, ${alpha(tint, 0.45)} 0%, transparent 70%)`,
        }}
      />
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse 80% 30% at 50% 105%, ${alpha(C.arenaGlow, 0.5)} 0%, transparent 70%)`,
          opacity: 0.75 + 0.25 * Math.sin(frame / 15),
        }}
      />
      {stars}
      {letters}
    </AbsoluteFill>
  );
};
