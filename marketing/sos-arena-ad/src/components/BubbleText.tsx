import React from "react";
import { HEADING, shade } from "../theme";

// Glossy, extruded "game title" lettering in the style of the SOS Arena logo.
export const BubbleText: React.FC<{
  children: React.ReactNode;
  color: string;
  size: number;
  depth?: number;
  stroke?: number;
  glow?: boolean;
  style?: React.CSSProperties;
}> = ({ children, color, size, depth, stroke, glow = true, style }) => {
  const d = depth ?? Math.max(3, Math.round(size * 0.07));
  const sw = stroke ?? Math.max(4, Math.round(size * 0.09));
  const dark = shade(color, -0.45);
  const layers = Array.from({ length: d }, (_, i) => `0 ${i + 1}px 0 ${dark}`);
  return (
    <span
      style={{
        fontFamily: HEADING,
        fontSize: size,
        lineHeight: 1,
        color,
        WebkitTextStroke: `${sw}px ${dark}`,
        paintOrder: "stroke fill",
        textShadow: [
          ...layers,
          `0 ${d + 6}px 14px rgba(0,0,0,0.55)`,
          glow ? `0 0 ${size * 0.5}px ${color}66` : "",
        ]
          .filter(Boolean)
          .join(", "),
        letterSpacing: size * 0.02,
        display: "inline-block",
        ...style,
      }}
    >
      {children}
    </span>
  );
};
