import React from "react";
import { useCurrentFrame } from "remotion";
import { pop } from "../anim";
import { BODY, C, HEADING, shade } from "../theme";
import { Avatar } from "./Avatar";

// Port of player_score_card.dart: banner-colored card with avatar, name, live score.
export const ScoreCard: React.FC<{
  name: string;
  emoji: string;
  color: string;
  score: number;
  bumpAt?: number[];
  active?: boolean;
  align?: "left" | "right";
}> = ({ name, emoji, color, score, bumpAt = [], active, align = "left" }) => {
  const frame = useCurrentFrame();
  const lastBump = bumpAt.filter((b) => frame >= b).pop();
  const bump = lastBump !== undefined ? 1 + 0.35 * Math.max(0, 1 - pop(frame, lastBump, 8)) * Math.sin(Math.min(1, (frame - lastBump) / 10) * Math.PI) : 1;
  return (
    <div
      style={{
        display: "flex",
        flexDirection: align === "left" ? "row" : "row-reverse",
        alignItems: "center",
        gap: 18,
        padding: "16px 24px",
        width: 420,
        borderRadius: 28,
        background: `linear-gradient(135deg, ${shade(color, -0.25)}, ${shade(C.arenaStone, 0)})`,
        border: `4px solid ${active ? C.arenaGold : shade(color, -0.1)}`,
        boxShadow: active ? `0 0 36px ${C.arenaGold}88` : "0 10px 30px rgba(0,0,0,.5)",
      }}
    >
      <Avatar emoji={emoji} color={color} size={92} ring={5} />
      <div style={{ flex: 1, textAlign: align }}>
        <div style={{ fontFamily: BODY, fontWeight: 800, fontSize: 34, color: C.onArena }}>{name}</div>
        <div style={{ fontFamily: BODY, fontWeight: 600, fontSize: 22, color: C.onArenaMuted }}>{active ? "YOUR TURN" : "WAITING"}</div>
      </div>
      <div style={{ fontFamily: HEADING, fontSize: 72, color: C.arenaGold, scale: String(bump), textShadow: `0 4px 0 ${shade(C.arenaGold, -0.5)}` }}>{score}</div>
    </div>
  );
};
