import React from "react";
import { AbsoluteFill, Sequence, useCurrentFrame } from "remotion";
import { lerp, pop } from "../anim";
import { Avatar } from "../components/Avatar";
import { Board } from "../components/Board";
import { Caption } from "../components/Caption";
import { BOARD_THEMES, BODY, C, HEADING, shade } from "../theme";

// Emotes from lib/core/models/emote.dart
const EMOTES = [
  { e: "👑", l: "GG!" },
  { e: "😎", l: "TOO EASY!" },
  { e: "😱", l: "OMG!" },
  { e: "🎯", l: "NICE MOVE!" },
  { e: "😭", l: "NOOO!" },
  { e: "🥳", l: "PARTY TIME!" },
];
export const EMOTE_TIMES = [8, 14, 20, 26, 32, 38];

const Emotes: React.FC = () => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{ alignItems: "center" }}>
      <div style={{ position: "absolute", top: 60, width: 1000 }}>
        <Caption text="TRASH TALK WITH *EMOTES" size={96} />
      </div>
      <div style={{ position: "absolute", top: 640, scale: String(pop(f, 0)) }}>
        <Avatar emoji="😏" color={C.arenaPink} size={240} ring={8} />
      </div>
      {EMOTES.map((em, i) => {
        const a = (i / EMOTES.length) * Math.PI * 2 - Math.PI / 2;
        const p = pop(f, EMOTE_TIMES[i], 8, 0.5);
        const fl = Math.sin((f + i * 9) / 7) * 12;
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: 540 + Math.cos(a) * 370,
              top: 760 + Math.sin(a) * 340 + fl,
              translate: "-50% -50%",
              scale: String(p),
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              background: "white",
              borderRadius: 40,
              padding: "14px 26px 16px",
              boxShadow: `0 0 0 6px ${i % 2 ? C.arenaBlue : C.secondary}, 0 16px 30px rgba(0,0,0,.5)`,
              rotate: `${(i % 2 ? 1 : -1) * 6}deg`,
            }}
          >
            <div style={{ fontSize: 110, lineHeight: 1.05 }}>{em.e}</div>
            <div style={{ fontFamily: HEADING, fontSize: 38, color: C.primary, whiteSpace: "nowrap" }}>{em.l}</div>
          </div>
        );
      })}
    </AbsoluteFill>
  );
};

const Themes: React.FC = () => {
  const f = useCurrentFrame();
  const ti = Math.min(BOARD_THEMES.length - 1, Math.floor(f / 11));
  const t = BOARD_THEMES[ti];
  const flip = pop(f, ti * 11, 10);
  const placements = [
    [0, "S"], [1, "O"], [2, "S"], [3, "O"], [4, "S"], [5, "O"], [6, "S"], [7, "S"], [8, "O"],
  ].map(([idx, letter]) => ({ idx: idx as number, letter: letter as "S" | "O", at: -10 }));
  return (
    <AbsoluteFill style={{ alignItems: "center" }}>
      <div style={{ position: "absolute", top: 60, width: 1000 }}>
        <Caption text="5 BOARD *THEMES" size={104} />
      </div>
      <div style={{ position: "absolute", top: 260, scale: String(lerp(flip, [0, 1], [0.85, 1])), rotate: `${(1 - flip) * 10}deg` }}>
        <Board n={3} px={640} placements={placements} strikes={[{ cells: [0, 1, 2], at: -20, color: t.highlight }, { cells: [2, 4, 6], at: -20, color: t.highlight }]} theme={t} />
      </div>
      <div style={{ position: "absolute", top: 940, fontFamily: HEADING, fontSize: 64, color: t.highlight === "#212121" ? C.arenaGold : shade(t.highlight, 0.2), letterSpacing: 4, scale: String(flip) }}>
        {t.name.toUpperCase()}
      </div>
      <div style={{ position: "absolute", top: 1060, display: "flex", gap: 24 }}>
        {[["↩️", "UNDO MOVE"], ["🧽", "ERASE CELL"]].map(([e, l], i) => (
          <div key={i} style={{ scale: String(pop(f, 20 + i * 8)), display: "flex", alignItems: "center", gap: 12, padding: "16px 30px", borderRadius: 999, background: `linear-gradient(135deg, ${C.primaryContainer}, ${C.primary})`, border: `4px solid ${C.inversePrimary}`, fontFamily: BODY, fontWeight: 800, fontSize: 40, color: "white", boxShadow: `0 0 40px ${C.primary}` }}>
            <span style={{ fontSize: 44 }}>{e}</span>✨ {l}
          </div>
        ))}
      </div>
      <div style={{ position: "absolute", top: 1180, fontFamily: BODY, fontWeight: 600, fontSize: 36, color: C.onArenaMuted, opacity: lerp(f, [30, 40], [0, 1]) }}>
        Magic spells to flip the game
      </div>
    </AbsoluteFill>
  );
};

// Titles from lib/features/profile/view/shop_screen.dart
const RANKS = ["ROOKIE", "TACTICIAN", "STRATEGIST", "GRANDMASTER", "WARLORD", "SOS LEGEND"];

const Ranks: React.FC = () => {
  const f = useCurrentFrame();
  const step = lerp(f, [4, 44], [0, RANKS.length - 1]);
  const ROW = 150;
  return (
    <AbsoluteFill style={{ alignItems: "center" }}>
      <div style={{ position: "absolute", top: 60, width: 1000 }}>
        <Caption text="RISE TO *SOS LEGEND" size={100} />
      </div>
      <div style={{ position: "absolute", top: 300, width: 860, height: 820, overflow: "hidden", maskImage: "linear-gradient(transparent, black 22%, black 78%, transparent)" }}>
        {RANKS.map((r, i) => {
          const d = i - step;
          const focus = Math.max(0, 1 - Math.abs(d));
          const legend = i === RANKS.length - 1;
          const gold = legend && focus > 0.5;
          return (
            <div
              key={r}
              style={{
                position: "absolute",
                left: 0,
                right: 0,
                top: 410 - ROW / 2 - d * ROW,
                height: ROW - 24,
                margin: "0 auto",
                width: 640 + 200 * focus,
                borderRadius: 34,
                background: gold ? `linear-gradient(135deg, ${C.arenaGold}, ${C.secondary})` : focus > 0.5 ? `linear-gradient(135deg, ${C.primaryContainer}, ${C.primary})` : C.arenaStone,
                border: `4px solid ${gold ? "#FFF3C4" : focus > 0.5 ? C.inversePrimary : C.arenaStoneEdge}`,
                boxShadow: focus > 0.5 ? `0 0 60px ${gold ? C.arenaGold : C.primary}` : "none",
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                padding: "0 40px",
                scale: String(0.9 + 0.12 * focus),
              }}
            >
              <span style={{ fontFamily: HEADING, fontSize: 60, color: gold ? C.arenaBgTop : C.onArena }}>{r}</span>
              <span style={{ fontSize: 60 }}>{legend ? "👑" : ["🌱", "🧠", "♟️", "🏅", "⚔️"][i]}</span>
            </div>
          );
        })}
      </div>
      <div style={{ position: "absolute", top: 1160, fontFamily: BODY, fontWeight: 600, fontSize: 36, color: C.onArenaMuted, opacity: lerp(f, [10, 20], [0, 1]) }}>
        🏆 Global leaderboard · Daily login rewards
      </div>
    </AbsoluteFill>
  );
};

export const FEATURE_LEN = 60;
// 15.5-21.5s
export const Features: React.FC = () => (
  <>
    <Sequence durationInFrames={FEATURE_LEN}><Emotes /></Sequence>
    <Sequence from={FEATURE_LEN} durationInFrames={FEATURE_LEN}><Themes /></Sequence>
    <Sequence from={FEATURE_LEN * 2} durationInFrames={FEATURE_LEN}><Ranks /></Sequence>
  </>
);

