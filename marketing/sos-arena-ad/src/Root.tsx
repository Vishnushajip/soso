import React from "react";
import { Composition } from "remotion";
import { SosAd, TOTAL_FRAMES } from "./SosAd";
import { FPS } from "./theme";

// Meta ad placements: Reels/Stories 9:16, Feed 4:5, Square 1:1.
const FORMATS = [
  { id: "Reel-9x16", width: 1080, height: 1920 },
  { id: "Feed-4x5", width: 1080, height: 1350 },
  { id: "Square-1x1", width: 1080, height: 1080 },
];

export const RemotionRoot: React.FC = () => (
  <>
    {FORMATS.map((f) => (
      <Composition key={f.id} id={f.id} component={SosAd} durationInFrames={TOTAL_FRAMES} fps={FPS} width={f.width} height={f.height} />
    ))}
  </>
);
