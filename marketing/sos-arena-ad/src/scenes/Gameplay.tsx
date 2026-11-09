import React from "react";
import { AbsoluteFill, Sequence, useCurrentFrame } from "remotion";
import { lerp, pop } from "../anim";
import { BubbleText } from "../components/BubbleText";
import { Board, Placement, Strike } from "../components/Board";
import { Caption } from "../components/Caption";
import { ScoreCard } from "../components/ScoreCard";
import { C } from "../theme";

const initial: [number, "S" | "O"][] = [
  [0, "S"], [2, "O"], [4, "S"], [6, "O"], [8, "S"], [10, "O"], [14, "O"],
  [16, "S"], [18, "O"], [20, "S"], [21, "O"], [24, "S"],
];

export const MOVES = { blueDouble: 30, blueSetup: 72, pinkDouble: 100 };

const placements: Placement[] = [
  ...initial.map(([idx, letter], k) => ({ idx, letter, at: k })),
  { idx: 12, letter: "S", at: MOVES.blueDouble },
  { idx: 17, letter: "O", at: MOVES.blueSetup },
  { idx: 22, letter: "S", at: MOVES.pinkDouble },
];
const strikes: Strike[] = [
  { cells: [0, 6, 12], at: MOVES.blueDouble + 3, color: C.arenaBlue },
  { cells: [12, 18, 24], at: MOVES.blueDouble + 6, color: C.arenaBlue },
  { cells: [20, 21, 22], at: MOVES.pinkDouble + 3, color: C.arenaPink },
  { cells: [12, 17, 22], at: MOVES.pinkDouble + 6, color: C.arenaPink },
];
const taps = [
  { idx: 12, at: MOVES.blueDouble - 4 },
  { idx: 17, at: MOVES.blueSetup - 4 },
  { idx: 22, at: MOVES.pinkDouble - 4 },
];

const Burst: React.FC<{ at: number; text: string; color: string; x: number; y: number }> = ({ at, text, color, x, y }) => {
  const f = useCurrentFrame();
  if (f < at || f > at + 34) return null;
  const p = pop(f, at, 8, 0.5);
  return (
    <div style={{ position: "absolute", left: x, top: y, translate: `-50% ${-lerp(f, [at, at + 34], [0, 70])}px`, scale: String(p), opacity: lerp(f, [at + 24, at + 34], [1, 0]), rotate: "-6deg" }}>
      <BubbleText color={color} size={96}>{text}</BubbleText>
    </div>
  );
};

// 2.5-7.5s: real gameplay on the Dark Arena board.
export const Gameplay: React.FC = () => {
  const f = useCurrentFrame();
  const boardIn = pop(f, 0, 14);
  const blueScore = f >= MOVES.blueDouble + 4 ? 6 : 4;
  const pinkScore = f >= MOVES.pinkDouble + 4 ? 7 : 5;
  const pinkTurn = f >= MOVES.blueSetup + 6;
  return (
    <AbsoluteFill style={{ alignItems: "center" }}>
      <div style={{ position: "absolute", top: 40, width: 1040, height: 200, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <Sequence durationInFrames={28} layout="none"><Caption text="PLACE *S OR *O" size={100} /></Sequence>
        <Sequence from={28} durationInFrames={66} layout="none"><Caption text="MAKE *SOS = POINTS" size={100} /></Sequence>
        <Sequence from={94} layout="none"><Caption text="STEAL THE *LEAD!" size={100} accent={C.arenaPink} /></Sequence>
      </div>
      <div style={{ position: "absolute", top: 250, display: "flex", gap: 40, translate: `0 ${(1 - boardIn) * -200}px`, opacity: boardIn }}>
        <ScoreCard name="YOU" emoji="😎" color={C.arenaBlue} score={blueScore} bumpAt={[MOVES.blueDouble + 4]} active={!pinkTurn} />
        <ScoreCard name="ALEX" emoji="😏" color={C.arenaPink} score={pinkScore} bumpAt={[MOVES.pinkDouble + 4]} active={pinkTurn} align="right" />
      </div>
      <div style={{ position: "absolute", top: 410, scale: String(lerp(boardIn, [0, 1], [0.6, 1])), opacity: boardIn, rotate: `${(1 - boardIn) * 8}deg` }}>
        <Board n={5} px={880} placements={placements} strikes={strikes} taps={taps} />
      </div>
      <Burst at={MOVES.blueDouble + 6} text="DOUBLE SOS! +2" color={C.arenaBlue} x={540} y={760} />
      <Burst at={MOVES.pinkDouble + 6} text="COMBO! +2" color={C.arenaPink} x={540} y={980} />
    </AbsoluteFill>
  );
};
