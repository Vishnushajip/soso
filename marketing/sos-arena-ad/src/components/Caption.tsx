import React from "react";
import { useCurrentFrame } from "remotion";
import { pop } from "../anim";
import { BubbleText } from "./BubbleText";

// Word-by-word kinetic caption. Words wrapped in *stars* get the accent color.
export const Caption: React.FC<{
  text: string;
  size?: number;
  delay?: number;
  stagger?: number;
  color?: string;
  accent?: string;
  style?: React.CSSProperties;
}> = ({ text, size = 92, delay = 0, stagger = 4, color = "#FFFFFF", accent = "#FFC857", style }) => {
  const frame = useCurrentFrame();
  const words = text.split(" ");
  return (
    <div
      style={{
        display: "flex",
        flexWrap: "wrap",
        justifyContent: "center",
        gap: `${size * 0.1}px ${size * 0.34}px`,
        textAlign: "center",
        ...style,
      }}
    >
      {words.map((w, i) => {
        const p = pop(frame, delay + i * stagger);
        const hi = w.startsWith("*");
        return (
          <span key={i} style={{ scale: String(p), opacity: Math.min(1, p * 2), display: "inline-block", translate: `0 ${(1 - p) * 40}px` }}>
            {/^[\p{L}\p{N}*!?.,'=+&#-]/u.test(w) ? (
              <BubbleText color={hi ? accent : color} size={size}>
                {w.replace(/\*/g, "")}
              </BubbleText>
            ) : (
              <span style={{ fontSize: size * 0.95, lineHeight: 1, filter: "drop-shadow(0 6px 10px rgba(0,0,0,.5))" }}>{w}</span>
            )}
          </span>
        );
      })}
    </div>
  );
};
