import { Audio } from "@remotion/media";
import React from "react";
import { AbsoluteFill, Img, interpolate, Sequence, staticFile, useCurrentFrame } from "remotion";
import { lerp, pop, smooth } from "../anim";
import { Background } from "../components/Background";
import { BubbleText } from "../components/BubbleText";
import { Caption } from "../components/Caption";
import "../fonts";
import { C, HEADING } from "../theme";
import { FriendsScreen, HomeScreen, MatchScreen, RequestsScreen } from "./screens";
import { FREDOKA, Icon, OUTFIT, Phone, SCREEN_W } from "./ui";

export const LAUNCH_FRAMES = 900;
const PHONE_IN = 105;
const PHONE_OUT = 760;
const SCALE = 1.42;

// Short, plain captions. Written for people, not algorithms.
const CAPTIONS: { from: number; to: number; text: string; sub: string; accent?: string }[] = [
  { from: 105, to: 230, text: "SOS Arena is now on *Google Play* 🎉", sub: "The game from the back of your notebook, now online." },
  { from: 230, to: 350, text: "Bored? Challenge your *girlfriend* 😉", sub: "Or your best friend. Or that cousin who always wins.", accent: C.arenaPink },
  { from: 350, to: 500, text: "Take turns. Make *S-O-S.* Score.", sub: "Most SOS wins. That's it." },
  { from: 500, to: 660, text: "*Chat* live while you play 💬", sub: "Tease, cheer, send a ❤️ mid-match." },
  { from: 660, to: 760, text: "Meet new players. Make *friends.*", sub: "Climb the global leaderboard together." },
];

const SCREENS: { start: number; end: number; el: (f: number) => React.ReactNode }[] = [
  { start: 0, end: 125, el: (f) => <HomeScreen f={f} tapAt={100} /> },
  { start: 125, end: 245, el: (f) => <FriendsScreen f={f} tapAt={85} /> },
  { start: 245, end: 555, el: (f) => <MatchScreen f={f} chatAt={155} /> },
  { start: 555, end: 9999, el: (f) => <RequestsScreen f={f} tapAt={55} /> },
];

const NotebookHook: React.FC<{ f: number }> = ({ f }) => {
  const line = (a: number) => lerp(f, [a, a + 10], [0, 1]);
  const cell = 150;
  const x0 = 540 - cell * 1.5;
  const y0 = 300;
  const letters: [number, number, string, number][] = [[0, 0, "S", 20], [1, 1, "O", 26], [2, 2, "S", 32], [2, 0, "O", 24], [0, 2, "S", 29]];
  const strike = line(38);
  const out = lerp(f, [92, 105], [1, 0]);
  return (
    <AbsoluteFill style={{ opacity: out }}>
      <svg width={1080} height={1920} style={{ position: "absolute", inset: 0 }}>
        {[1, 2].map((i) => (
          <g key={i} stroke="#F1ECFF" strokeWidth={8} strokeLinecap="round" opacity={0.9}>
            <line x1={x0 + cell * i} y1={y0} x2={x0 + cell * i} y2={y0 + cell * 3 * line(i * 3)} />
            <line x1={x0} y1={y0 + cell * i} x2={x0 + cell * 3 * line(i * 3 + 4)} y2={y0 + cell * i} />
          </g>
        ))}
        <line x1={x0 + 30} y1={y0 + 30} x2={x0 + 30 + (cell * 3 - 60) * strike} y2={y0 + 30 + (cell * 3 - 60) * strike} stroke={C.arenaGold} strokeWidth={14} strokeLinecap="round" style={{ filter: `drop-shadow(0 0 12px ${C.arenaGold})` }} />
      </svg>
      {letters.map(([c, r, l, at], i) => (
        <div key={i} style={{ position: "absolute", left: x0 + c * cell, top: y0 + r * cell, width: cell, height: cell, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: FREDOKA, fontWeight: 600, fontSize: 110, color: l === "S" ? C.arenaBlue : C.secondary, scale: String(pop(f, at, 10)), rotate: `${(i % 2 ? -1 : 1) * 6}deg` }}>{l}</div>
      ))}
      <div style={{ position: "absolute", top: 860, width: "100%" }}>
        <Caption text="Remember playing *SOS*" size={78} delay={6} />
        <Caption text="on the last page of your notebook?" size={60} delay={16} stagger={3} style={{ marginTop: 18 }} />
      </div>
      <div style={{ position: "absolute", top: 1180, width: "100%", opacity: lerp(f, [56, 64], [0, 1]) }}>
        <Caption text="It's back. Now *online.*" size={80} delay={58} accent={C.tertiaryContainer} />
      </div>
    </AbsoluteFill>
  );
};

const CaptionWrap: React.FC<{ f: number }> = ({ f }) => {
  // Re-key per caption so word pops restart.
  const cap = CAPTIONS.find((c) => f >= c.from && f < c.to);
  if (!cap) return null;
  return <FrameShift by={cap.from}><CaptionBlockLocal cap={cap} /></FrameShift>;
};

// Minimal frame-offset helper so Caption's internal useCurrentFrame restarts per caption.
const FrameShift: React.FC<{ by: number; children: React.ReactNode }> = ({ by, children }) => (
  <Sequence from={by} layout="none">{children}</Sequence>
);
const CaptionBlockLocal: React.FC<{ cap: (typeof CAPTIONS)[number] }> = ({ cap }) => {
  const lf = useCurrentFrame();
  const dur = cap.to - cap.from;
  const outO = lerp(lf, [dur - 6, dur], [1, 0]);
  return (
    <div style={{ position: "absolute", top: 170, left: 50, right: 50, height: 330, display: "flex", flexDirection: "column", justifyContent: "center", alignItems: "center", opacity: outO }}>
      <Caption text={cap.text} size={66} stagger={3} accent={cap.accent ?? C.arenaGold} />
      <div style={{ marginTop: 22, fontFamily: OUTFIT, fontWeight: 600, fontSize: 36, color: "rgba(241,236,255,.85)", textAlign: "center", opacity: lerp(lf, [10, 18], [0, 1]), translate: `0 ${lerp(lf, [10, 20], [16, 0])}px` }}>{cap.sub}</div>
    </div>
  );
};

const PhoneStage: React.FC<{ f: number }> = ({ f }) => {
  const lf = f - PHONE_IN;
  const inP = smooth(f, PHONE_IN);
  const outP = lerp(f, [PHONE_OUT, PHONE_OUT + 14], [0, 1]);
  if (f < PHONE_IN || f > PHONE_OUT + 14) return null;
  return (
    <div style={{ position: "absolute", left: 540, top: 530, translate: `-50% ${(1 - inP) * 1300 + outP * 1300}px`, rotate: `${(1 - inP) * 6}deg` }}>
      <Phone scale={SCALE}>
        {SCREENS.map((s, i) => {
          if (lf < s.start || lf >= s.end + 12) return null;
          const enterX = i === 0 ? 0 : lerp(lf, [s.start, s.start + 12], [SCREEN_W, 0]);
          const exitX = lerp(lf, [s.end, s.end + 12], [0, -120]);
          return (
            <div key={i} style={{ position: "absolute", inset: 0, translate: `${enterX + exitX}px 0`, zIndex: i, boxShadow: enterX > 0 ? "-20px 0 40px rgba(0,0,0,.25)" : "none" }}>
              {s.el(lf - s.start)}
            </div>
          );
        })}
      </Phone>
    </div>
  );
};

const EndCard: React.FC<{ f: number }> = ({ f }) => {
  const lf = f - PHONE_OUT;
  if (lf < 0) return null;
  const icon = pop(lf, 6, 10, 0.6);
  const play = pop(lf, 40, 11);
  const web = pop(lf, 52, 11);
  return (
    <AbsoluteFill style={{ alignItems: "center" }}>
      <div style={{ position: "absolute", top: 230, width: 980 }}>
        <Caption text="Your new *time pass* is here." size={76} delay={2} />
      </div>
      <div style={{ position: "absolute", top: 470, scale: String(icon), translate: `0 ${Math.sin(lf / 10) * 8}px` }}>
        <Img src={staticFile("app_icon.png")} style={{ width: 380, height: 380, borderRadius: 84, border: "6px solid rgba(255,255,255,.85)", boxShadow: `0 0 90px ${C.primary}, 0 30px 60px rgba(0,0,0,.6)` }} />
      </div>
      <div style={{ position: "absolute", top: 900, display: "flex", gap: 16, alignItems: "baseline", opacity: lerp(lf, [16, 26], [0, 1]) }}>
        <BubbleText color={C.logoOrange} size={120}>S</BubbleText>
        <BubbleText color={C.logoBlue} size={120} style={{ marginLeft: -12 }}>O</BubbleText>
        <BubbleText color={C.logoOrange} size={120} style={{ marginLeft: -12 }}>S</BubbleText>
        <BubbleText color={C.arenaGold} size={120} style={{ marginLeft: 16 }}>ARENA</BubbleText>
      </div>
      <div style={{ position: "absolute", top: 1100, scale: String(play), display: "flex", alignItems: "center", gap: 22, padding: "22px 46px", borderRadius: 28, background: "#000", border: "3px solid #5f5a72", boxShadow: "0 16px 40px rgba(0,0,0,.5)" }}>
        <Icon name="play_arrow" size={84} color={C.tertiaryContainer} />
        <div>
          <div style={{ fontFamily: OUTFIT, fontWeight: 600, fontSize: 28, color: "#cfcbe0", letterSpacing: 2 }}>DOWNLOAD FREE ON</div>
          <div style={{ fontFamily: OUTFIT, fontWeight: 800, fontSize: 60, color: "#fff", lineHeight: 1 }}>Google Play</div>
        </div>
      </div>
      <div style={{ position: "absolute", top: 1330, textAlign: "center", scale: String(web) }}>
        <div style={{ fontFamily: OUTFIT, fontWeight: 600, fontSize: 36, color: "rgba(241,236,255,.85)" }}>or play right now in your browser</div>
        <div style={{ marginTop: 18, display: "inline-flex", alignItems: "center", gap: 14, padding: "16px 36px", borderRadius: 999, background: `linear-gradient(135deg, ${C.primary}, ${C.accent})`, border: "3px solid rgba(255,255,255,.7)", fontFamily: OUTFIT, fontWeight: 800, fontSize: 50, color: "#fff", boxShadow: `0 0 50px ${C.primary}` }}>
          <Icon name="language" size={50} color="#fff" /> playsos.web.app
        </div>
      </div>
      <div style={{ position: "absolute", top: 1560, fontFamily: HEADING, fontSize: 34, color: C.onArenaMuted, letterSpacing: 2, opacity: lerp(lf, [70, 80], [0, 1]) }}>
        Search “SOS Arena” on Play Store
      </div>
    </AbsoluteFill>
  );
};

export const LaunchReel: React.FC = () => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill>
      <Background tint={C.primary} />
      {f < PHONE_IN && <NotebookHook f={f} />}
      <CaptionWrap f={f} />
      <PhoneStage f={f} />
      <EndCard f={f} />
      {/* Only the game's own theme music, kept soft. No voice, no effects. */}
      <Audio
        src={staticFile("sfx/theme.mp3")}
        volume={(fr) => interpolate(fr, [0, 15, LAUNCH_FRAMES - 40, LAUNCH_FRAMES], [0, 0.35, 0.35, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })}
      />
    </AbsoluteFill>
  );
};
