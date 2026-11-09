import React from "react";
import { useCurrentFrame } from "remotion";

export const Rays: React.FC<{ color: string; size?: number; opacity?: number }> = ({ color, size = 1800, opacity = 0.35 }) => {
  const f = useCurrentFrame();
  return (
    <div
      style={{
        position: "absolute",
        width: size,
        height: size,
        left: "50%",
        top: "50%",
        translate: "-50% -50%",
        rotate: `${f * 0.6}deg`,
        opacity,
        background: `repeating-conic-gradient(${color} 0deg 9deg, transparent 9deg 22.5deg)`,
        maskImage: "radial-gradient(circle, black 0%, transparent 62%)",
      }}
    />
  );
};
