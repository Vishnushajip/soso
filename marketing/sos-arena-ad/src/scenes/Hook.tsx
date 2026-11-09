import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { lerp, pop } from "../anim";
import { shake } from "../anim2";
import { BubbleText } from "../components/BubbleText";
import { Caption } from "../components/Caption";
import { C } from "../theme";

// 0-2.5s: thumb-stopping hook. S, O, S slam down, get struck through, tagline.
export const Hook: React.FC = () => {
  const f = useCurrentFrame();
  const impacts = [2, 10, 18];
  const letters: [string, string][] = [["S", C.logoOrange], ["O", C.logoBlue], ["S", C.logoOrange]];
  const strike = lerp(f, [26, 34], [0, 1]);
  return (
    <AbsoluteFill style={{ alignItems: "center", translate: shake(f, [...impacts, 30], 26) }}>
      <div style={{ position: "absolute", top: 300, display: "flex", gap: 10 }}>
        {letters.map(([l, col], i) => {
          const p = pop(f, impacts[i] - 2, 10, 0.6);
          return (
            <div key={i} style={{ scale: String(lerp(p, [0, 1], [3.2, 1])), opacity: Math.min(1, p * 3), rotate: `${(i - 1) * 6 * (1 - p)}deg` }}>
              <BubbleText color={col} size={340}>{l}</BubbleText>
            </div>
          );
        })}
        <div
          style={{
            position: "absolute",
            left: -30,
            top: 150,
            height: 34,
            width: `calc(${strike * 100}% + 60px)`,
            borderRadius: 30,
            background: C.arenaGold,
            boxShadow: `0 0 50px ${C.arenaGold}, 0 0 120px ${C.arenaGlow}`,
            opacity: strike > 0 ? 1 : 0,
            rotate: "-4deg",
          }}
        />
      </div>
      <div style={{ position: "absolute", top: 780, width: 1000 }}>
        <Caption text="3 LETTERS." size={110} delay={34} />
        <Caption text="ENDLESS *RIVALRY." size={110} delay={44} style={{ marginTop: 24 }} />
      </div>
    </AbsoluteFill>
  );
};
