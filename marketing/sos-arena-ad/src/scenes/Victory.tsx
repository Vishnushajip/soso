import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { lerp, pop } from "../anim";
import { BubbleText } from "../components/BubbleText";
import { Confetti } from "../components/Confetti";
import { Rays } from "../components/Rays";
import { BODY, C, HEADING } from "../theme";

// 21.5-24.5s: match_summary_screen "Victory! You ruled the arena".
export const Victory: React.FC = () => {
  const f = useCurrentFrame();
  const trophy = pop(f, 0, 9, 0.6);
  const title = pop(f, 8, 9, 0.6);
  const rows = [
    { n: "😎 YOU", s: 12, c: C.arenaBlue },
    { n: "😏 ALEX", s: 9, c: C.arenaPink },
  ];
  return (
    <AbsoluteFill style={{ alignItems: "center" }}>
      <div style={{ position: "absolute", left: 540, top: 380, width: 0, height: 0 }}>
        <Rays color={C.arenaGold} size={1600} opacity={0.3} />
      </div>
      <div style={{ position: "absolute", top: 150, fontSize: 320, scale: String(trophy), rotate: `${Math.sin(f / 8) * 5}deg`, filter: `drop-shadow(0 0 60px ${C.arenaGold})` }}>🏆</div>
      <div style={{ position: "absolute", top: 560, scale: String(lerp(title, [0, 1], [2.5, 1])), opacity: Math.min(1, title * 2) }}>
        <BubbleText color={C.arenaGold} size={200}>VICTORY!</BubbleText>
      </div>
      <div style={{ position: "absolute", top: 800, fontFamily: BODY, fontWeight: 800, fontSize: 52, color: C.onArena, opacity: lerp(f, [16, 26], [0, 1]) }}>
        You ruled the arena
      </div>
      <div style={{ position: "absolute", top: 900, width: 760, padding: 30, borderRadius: 40, background: `${C.arenaStone}EE`, border: `4px solid ${C.arenaStoneEdge}`, opacity: lerp(f, [22, 30], [0, 1]), translate: `0 ${lerp(f, [22, 34], [60, 0])}px` }}>
        <div style={{ fontFamily: HEADING, fontSize: 34, color: C.onArenaMuted, letterSpacing: 6, textAlign: "center", marginBottom: 16 }}>FINAL STANDINGS</div>
        {rows.map((r, i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 20, marginTop: 14 }}>
            <div style={{ width: 200, fontFamily: BODY, fontWeight: 800, fontSize: 40, color: "white" }}>{r.n}</div>
            <div style={{ flex: 1, height: 44, borderRadius: 22, background: C.arenaCell, overflow: "hidden" }}>
              <div style={{ width: `${lerp(f, [28 + i * 4, 56], [0, (r.s / 12) * 100])}%`, height: "100%", borderRadius: 22, background: r.c, boxShadow: `0 0 20px ${r.c}` }} />
            </div>
            <div style={{ width: 70, textAlign: "right", fontFamily: HEADING, fontSize: 52, color: C.arenaGold }}>{Math.round(lerp(f, [28 + i * 4, 56], [0, r.s]))}</div>
          </div>
        ))}
      </div>
      <Confetti start={6} />
    </AbsoluteFill>
  );
};
