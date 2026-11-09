import { Audio } from "@remotion/media";
import React from "react";
import { AbsoluteFill, interpolate, Sequence, staticFile, useCurrentFrame } from "remotion";
import { lerp } from "./anim";
import { Background } from "./components/Background";
import { Stage } from "./components/Stage";
import "./fonts";
import { Audiences, CARD_LEN } from "./scenes/Audiences";
import { Cta } from "./scenes/Cta";
import { EMOTE_TIMES, FEATURE_LEN, Features } from "./scenes/Features";
import { Gameplay, MOVES } from "./scenes/Gameplay";
import { Hook } from "./scenes/Hook";
import { Versus } from "./scenes/Versus";
import { Victory } from "./scenes/Victory";
import { C } from "./theme";

const SCENES = [
  { id: "hook", len: 75, C: Hook, tint: C.secondary },
  { id: "gameplay", len: 150, C: Gameplay, tint: C.primary },
  { id: "versus", len: 90, C: Versus, tint: C.arenaPink },
  { id: "audiences", len: 150, C: Audiences, tint: C.arenaBlue },
  { id: "features", len: FEATURE_LEN * 3, C: Features, tint: C.primary },
  { id: "victory", len: 90, C: Victory, tint: C.arenaGold },
  { id: "cta", len: 135, C: Cta, tint: C.primaryContainer },
] as const;

const starts: Record<string, number> = {};
let acc = 0;
for (const s of SCENES) {
  starts[s.id] = acc;
  acc += s.len;
}
export const TOTAL_FRAMES = acc;

// Punch-in entrance for every cut.
const SceneIn: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{ scale: String(lerp(f, [0, 9], [1.12, 1])), filter: `blur(${lerp(f, [0, 7], [12, 0])}px)` }}>
      {children}
    </AbsoluteFill>
  );
};

const Flash: React.FC = () => {
  const f = useCurrentFrame();
  return <AbsoluteFill style={{ background: "white", opacity: lerp(f, [0, 5], [0.55, 0]), pointerEvents: "none" }} />;
};

const Sfx: React.FC<{ at: number; src: string; volume?: number }> = ({ at, src, volume = 0.8 }) => (
  <Sequence from={at} layout="none">
    <Audio src={staticFile(`sfx/${src}.mp3`)} volume={volume} />
  </Sequence>
);

export const SosAd: React.FC = () => {
  const frame = useCurrentFrame();
  const current = [...SCENES].reverse().find((s) => frame >= starts[s.id]) ?? SCENES[0];
  const g = starts.gameplay, a = starts.audiences, ft = starts.features;
  return (
    <AbsoluteFill>
      <Background tint={current.tint} />
      {SCENES.map((s) => (
        <Sequence key={s.id} name={s.id} from={starts[s.id]} durationInFrames={s.len}>
          <Stage>
            <SceneIn>
              <s.C />
            </SceneIn>
          </Stage>
          {s.id !== "hook" && <Flash />}
        </Sequence>
      ))}

      {/* Music bed: the game's own theme */}
      <Audio
        src={staticFile("sfx/theme.mp3")}
        volume={(f) => interpolate(f, [0, 8, TOTAL_FRAMES - 30, TOTAL_FRAMES], [0, 0.55, 0.55, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })}
      />

      {/* Sound design, all from assets/sounds */}
      {[2, 10, 18].map((t) => <Sfx key={t} at={t} src="point" volume={0.9} />)}
      <Sfx at={28} src="sos" />
      {[MOVES.blueDouble, MOVES.blueSetup, MOVES.pinkDouble].map((t) => <Sfx key={t} at={g + t - 4} src="button_click" volume={0.6} />)}
      <Sfx at={g + MOVES.blueDouble + 3} src="sos" />
      <Sfx at={g + MOVES.pinkDouble + 3} src="sos" />
      <Sfx at={starts.versus + 12} src="versus" volume={1} />
      {[0, 1, 2, 3].map((i) => <Sfx key={i} at={a + 2 + i * CARD_LEN} src="button_click" volume={0.5} />)}
      {[0, 2, 4].map((i) => <Sfx key={i} at={ft + EMOTE_TIMES[i]} src="notify" volume={0.5} />)}
      {[0, 1, 2, 3, 4].map((i) => <Sfx key={i} at={ft + FEATURE_LEN + i * 11} src="button_click" volume={0.45} />)}
      <Sfx at={ft + FEATURE_LEN * 2 + 4} src="rank_up" volume={0.8} />
      <Sfx at={starts.victory + 4} src="win" volume={1} />
      <Sfx at={starts.cta + 2} src="point" />
      <Sfx at={starts.cta + 22} src="button_click" volume={0.7} />
    </AbsoluteFill>
  );
};
