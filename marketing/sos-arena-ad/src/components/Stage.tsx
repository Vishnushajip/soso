import React from "react";
import { AbsoluteFill, useVideoConfig } from "remotion";
import { STAGE_H, STAGE_W } from "../theme";

// Centers a 1080x1350 stage and scales it to fit any output format.
export const Stage: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { width, height } = useVideoConfig();
  const scale = Math.min(width / STAGE_W, height / STAGE_H);
  return (
    <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
      <div style={{ width: STAGE_W, height: STAGE_H, position: "relative", scale: String(scale), flexShrink: 0 }}>
        {children}
      </div>
    </AbsoluteFill>
  );
};
