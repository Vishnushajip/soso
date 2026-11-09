import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { lerp, pop } from "../anim";
import { shake } from "../anim2";
import { Avatar } from "../components/Avatar";
import { BubbleText } from "../components/BubbleText";
import { Caption } from "../components/Caption";
import { BODY, C, HEADING } from "../theme";

// 7.5-10.5s: the in-game VS overlay, re-cast for couples.
export const Versus: React.FC = () => {
  const f = useCurrentFrame();
  const slideL = lerp(f, [0, 12], [-700, 0]);
  const slideR = lerp(f, [0, 12], [700, 0]);
  const vs = pop(f, 14, 9, 0.6);
  const ring = lerp(f, [16, 36], [0, 1]);
  const beat = 1 + 0.06 * Math.max(0, Math.sin((f - 20) / 4));
  return (
    <AbsoluteFill style={{ translate: shake(f, [16], 30) }}>
      <div style={{ position: "absolute", top: 60, width: "100%", textAlign: "center", fontFamily: HEADING, fontSize: 54, color: C.arenaGold, letterSpacing: 8, opacity: lerp(f, [0, 8], [0, 1]) }}>
        MATCH STARTING
      </div>
      <div style={{ position: "absolute", left: 0, top: 170, width: 600, height: 620, translate: `${slideL}px 0`, background: `linear-gradient(135deg, ${C.arenaBlue}, ${C.primary})`, clipPath: "polygon(0 0, 100% 0, 80% 100%, 0 100%)", boxShadow: "0 0 80px rgba(0,0,0,.5)" }} />
      <div style={{ position: "absolute", right: 0, top: 170, width: 600, height: 620, translate: `${slideR}px 0`, background: `linear-gradient(225deg, ${C.arenaPink}, ${C.secondary})`, clipPath: "polygon(20% 0, 100% 0, 100% 100%, 0 100%)" }} />
      <div style={{ position: "absolute", left: 90, top: 280, translate: `${slideL}px 0`, textAlign: "center", scale: String(beat) }}>
        <Avatar emoji="😎" color={C.arenaBlue} size={280} ring={10} />
        <div style={{ fontFamily: HEADING, fontSize: 70, color: "white", marginTop: 20 }}>YOU</div>
      </div>
      <div style={{ position: "absolute", right: 90, top: 280, translate: `${slideR}px 0`, textAlign: "center", scale: String(beat) }}>
        <Avatar emoji="😍" color={C.arenaPink} size={280} ring={10} />
        <div style={{ fontFamily: HEADING, fontSize: 70, color: "white", marginTop: 20 }}>BAE</div>
      </div>
      <div style={{ position: "absolute", left: 540, top: 460, width: 0, height: 0 }}>
        <div style={{ position: "absolute", left: -260 * ring, top: -260 * ring, width: 520 * ring, height: 520 * ring, borderRadius: 999, border: `${18 * (1 - ring)}px solid ${C.arenaGold}`, opacity: 1 - ring }} />
        <div style={{ position: "absolute", translate: "-50% -50%", scale: String(lerp(vs, [0, 1], [4, 1])), opacity: Math.min(1, vs * 3), rotate: `${(1 - vs) * -30}deg` }}>
          <BubbleText color={C.arenaGold} size={220}>VS</BubbleText>
        </div>
      </div>
      <div style={{ position: "absolute", top: 860, width: "100%" }}>
        <Caption text="COUPLES. BESTIES. RIVALS." size={78} delay={24} stagger={5} />
        <Caption text="LOSER PICKS THE *MOVIE 🍿" size={78} delay={48} accent={C.arenaPink} style={{ marginTop: 30 }} />
      </div>
      <div style={{ position: "absolute", bottom: 40, width: "100%", textAlign: "center", fontFamily: BODY, fontWeight: 600, fontSize: 34, color: C.onArenaMuted, opacity: lerp(f, [60, 70], [0, 1]) }}>
        💕 Real-time 1v1 · Pass & Play on one phone
      </div>
    </AbsoluteFill>
  );
};
