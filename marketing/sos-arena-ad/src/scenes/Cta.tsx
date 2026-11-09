import React from "react";
import { AbsoluteFill, Img, staticFile, useCurrentFrame } from "remotion";
import { lerp, pop } from "../anim";
import { BubbleText } from "../components/BubbleText";
import { Rays } from "../components/Rays";
import { BODY, C, HEADING, shade } from "../theme";

// 24.5-29s: logo, wordmark, CTA button, where to get it.
export const Cta: React.FC = () => {
  const f = useCurrentFrame();
  const icon = pop(f, 0, 9, 0.6);
  const word = pop(f, 10, 10);
  const btn = pop(f, 22, 9);
  const pulse = 1 + 0.05 * Math.max(0, Math.sin((f - 30) / 5));
  const shine = lerp(f % 45, [0, 30], [-120, 220], (t) => t);
  return (
    <AbsoluteFill style={{ alignItems: "center" }}>
      <div style={{ position: "absolute", left: 540, top: 330, width: 0, height: 0 }}>
        <Rays color={C.primaryContainer} size={1500} opacity={0.4} />
      </div>
      <div style={{ position: "absolute", top: 60, scale: String(icon), translate: `0 ${Math.sin(f / 10) * 10}px`, rotate: `${(1 - icon) * -20}deg` }}>
        <Img src={staticFile("app_icon.png")} style={{ width: 520, height: 520, borderRadius: 110, boxShadow: `0 0 100px ${C.primary}, 0 30px 60px rgba(0,0,0,.6)`, border: "6px solid rgba(255,255,255,.85)" }} />
      </div>
      <div style={{ position: "absolute", top: 620, display: "flex", gap: 18, alignItems: "baseline", scale: String(word), opacity: Math.min(1, word * 2) }}>
        <BubbleText color={C.logoOrange} size={150}>S</BubbleText>
        <BubbleText color={C.logoBlue} size={150} style={{ marginLeft: -14 }}>O</BubbleText>
        <BubbleText color={C.logoOrange} size={150} style={{ marginLeft: -14 }}>S</BubbleText>
        <BubbleText color={C.arenaGold} size={150} style={{ marginLeft: 20 }}>ARENA</BubbleText>
      </div>
      <div style={{ position: "absolute", top: 800, fontFamily: BODY, fontWeight: 600, fontSize: 40, color: C.onArena, opacity: lerp(f, [16, 26], [0, 1]), textAlign: "center" }}>
        The classic pen & paper game, now a live battle
      </div>
      <div
        style={{
          position: "absolute",
          top: 900,
          scale: String(btn * pulse),
          padding: "34px 90px",
          borderRadius: 999,
          background: `linear-gradient(180deg, ${C.tertiaryContainer}, ${C.tertiary})`,
          boxShadow: `0 12px 0 ${shade(C.tertiary, -0.45)}, 0 0 60px ${C.tertiaryContainer}AA`,
          border: "5px solid white",
          overflow: "hidden",
        }}
      >
        <div style={{ position: "absolute", top: 0, bottom: 0, left: `${shine}%`, width: 90, background: "rgba(255,255,255,.45)", rotate: "20deg", filter: "blur(6px)" }} />
        <span style={{ fontFamily: HEADING, fontSize: 84, color: "white", textShadow: `0 4px 0 ${shade(C.tertiary, -0.5)}`, letterSpacing: 3 }}>PLAY FREE NOW</span>
      </div>
      <div style={{ position: "absolute", top: 1100, display: "flex", gap: 22, opacity: lerp(f, [34, 44], [0, 1]), translate: `0 ${lerp(f, [34, 46], [30, 0])}px` }}>
        {[["▶", "Google Play"], ["🌐", "playsos.web.app"]].map(([e, l], i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 14, padding: "18px 32px", borderRadius: 24, background: "#000", border: `3px solid ${C.arenaStoneEdge}`, fontFamily: BODY, fontWeight: 800, fontSize: 38, color: "white" }}>
            <span style={{ color: i ? C.arenaBlue : C.tertiaryContainer }}>{e}</span>
            {l}
          </div>
        ))}
      </div>
      <div style={{ position: "absolute", top: 1230, fontFamily: HEADING, fontSize: 40, color: C.onArenaMuted, letterSpacing: 3, opacity: lerp(f, [44, 54], [0, 1]) }}>
        💑 COUPLES · 🎮 GAMERS · 👯 FRIENDS
      </div>
    </AbsoluteFill>
  );
};
