import React from "react";
import { BODY, shade } from "../theme";

export const Avatar: React.FC<{ emoji: string; color: string; size: number; ring?: number }> = ({ emoji, color, size, ring = 6 }) => (
  <div
    style={{
      width: size,
      height: size,
      borderRadius: size,
      background: `radial-gradient(circle at 35% 30%, ${shade(color, 0.35)}, ${color} 55%, ${shade(color, -0.35)})`,
      border: `${ring}px solid white`,
      boxShadow: `0 0 ${size * 0.4}px ${color}AA, 0 10px 24px rgba(0,0,0,.5)`,
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      fontSize: size * 0.52,
      fontFamily: BODY,
    }}
  >
    {emoji}
  </div>
);
