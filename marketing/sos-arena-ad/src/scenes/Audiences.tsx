import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { lerp } from "../anim";
import { BubbleText } from "../components/BubbleText";
import { Caption } from "../components/Caption";
import { BODY, C, shade } from "../theme";

export const CARD_LEN = 36;
const CARDS = [
  { emoji: "💑", title: "DATE NIGHT", sub: "Pass & Play on one phone", color: C.arenaPink },
  { emoji: "🎮", title: "GAMERS", sub: "Climb ranked online matches", color: C.arenaBlue },
  { emoji: "👯", title: "SQUAD GOALS", sub: "Challenge friends · up to 4 players", color: C.secondary },
  { emoji: "🤖", title: "SOLO MODE", sub: "Beat the Mastermind AI · offline", color: C.primaryContainer },
];

// 10.5-15.5s: one card per audience, whip-panned.
export const Audiences: React.FC = () => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{ alignItems: "center" }}>
      <div style={{ position: "absolute", top: 60 }}>
        <Caption text="MADE FOR *EVERYONE" size={100} />
      </div>
      {CARDS.map((c, i) => {
        const start = 6 + i * CARD_LEN;
        const lf = f - start;
        if (lf < -8 || lf > CARD_LEN + 8) return null;
        const last = i === CARDS.length - 1;
        const x = lerp(lf, [-8, 4], [1100, 0]) + (last ? 0 : lerp(lf, [CARD_LEN - 4, CARD_LEN + 8], [0, -1100]));
        const rot = lerp(lf, [-8, 6], [14, 0]) + (last ? 0 : lerp(lf, [CARD_LEN - 4, CARD_LEN + 8], [0, -14]));
        const emojiBounce = 1 + 0.08 * Math.sin(lf / 3);
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              top: 270,
              width: 900,
              height: 860,
              borderRadius: 60,
              translate: `${x}px 0`,
              rotate: `${rot}deg`,
              background: `linear-gradient(160deg, ${shade(c.color, 0.1)}, ${shade(c.color, -0.45)})`,
              border: `6px solid ${shade(c.color, 0.35)}`,
              boxShadow: `0 0 100px ${c.color}66, 0 40px 80px rgba(0,0,0,.6)`,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              justifyContent: "center",
              gap: 30,
            }}
          >
            <div style={{ fontSize: 300, scale: String(emojiBounce), filter: "drop-shadow(0 20px 20px rgba(0,0,0,.4))" }}>{c.emoji}</div>
            <BubbleText color="#FFFFFF" size={120}>{c.title}</BubbleText>
            <div style={{ fontFamily: BODY, fontWeight: 800, fontSize: 46, color: "white", background: "rgba(0,0,0,.28)", padding: "14px 34px", borderRadius: 999 }}>{c.sub}</div>
          </div>
        );
      })}
      <div style={{ position: "absolute", top: 1180, display: "flex", gap: 20 }}>
        {CARDS.map((c, i) => {
          const on = f >= 6 + i * CARD_LEN;
          return <div key={i} style={{ width: on ? 60 : 22, height: 22, borderRadius: 22, background: on ? c.color : C.arenaStoneEdge }} />;
        })}
      </div>
    </AbsoluteFill>
  );
};
