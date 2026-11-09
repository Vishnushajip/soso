import React from "react";
import { useCurrentFrame } from "remotion";
import { lerp, pop } from "../anim";
import { BODY, BOARD_THEMES, BoardThemeDef, shade } from "../theme";

export type Placement = { idx: number; letter: "S" | "O"; at: number; owner?: string };
export type Strike = { cells: [number, number, number]; at: number; color: string };

// Port of lib/features/game/widgets/game_board_widget.dart (arena cells + SOS lines).
export const Board: React.FC<{
  n: number;
  px: number;
  placements: Placement[];
  strikes?: Strike[];
  taps?: { idx: number; at: number }[];
  theme?: BoardThemeDef;
}> = ({ n, px, placements, strikes = [], taps = [], theme = BOARD_THEMES[1] }) => {
  const frame = useCurrentFrame();
  const pad = px * 0.025;
  const gap = px * 0.012;
  const cell = (px - pad * 2 - gap * (n - 1)) / n;
  const center = (i: number) => {
    const r = Math.floor(i / n), c = i % n;
    return [pad + c * (cell + gap) + cell / 2, pad + r * (cell + gap) + cell / 2];
  };
  const inSos = (i: number) => strikes.find((s) => frame >= s.at && s.cells.includes(i));

  return (
    <div
      style={{
        width: px,
        height: px,
        position: "relative",
        borderRadius: px * 0.045,
        background: theme.glossy
          ? `linear-gradient(160deg, ${shade(theme.boardBg, 0.08)}, ${theme.boardBg})`
          : theme.boardBg,
        border: `${theme.glossy ? 4 : 2}px solid ${theme.border}`,
        boxShadow: theme.glossy
          ? `0 0 60px ${theme.highlight}33, 0 30px 60px rgba(0,0,0,.6)`
          : "0 30px 60px rgba(0,0,0,.45)",
      }}
    >
      {Array.from({ length: n * n }, (_, i) => {
        const [cx, cy] = center(i);
        const p = placements.find((pl) => pl.idx === i && frame >= pl.at);
        const sos = inSos(i);
        const justPlaced = p && frame - p.at < 18;
        const s = p ? pop(frame, p.at, 9, 0.6) : 0;
        const color = p ? (p.letter === "S" ? theme.s : theme.o) : "#fff";
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: cx - cell / 2,
              top: cy - cell / 2,
              width: cell,
              height: cell,
              borderRadius: cell * 0.18,
              background: sos
                ? `${sos.color}33`
                : justPlaced
                  ? `${theme.highlight}40`
                  : theme.glossy
                    ? `linear-gradient(180deg, ${theme.cell}, ${shade(theme.cell, -0.2)})`
                    : theme.cell,
              border: sos
                ? `3px solid ${sos.color}AA`
                : justPlaced
                  ? `3px solid ${theme.highlight}`
                  : theme.glossy
                    ? `2px solid ${shade(theme.border, -0.1)}`
                    : "none",
              boxShadow: sos
                ? `0 0 ${cell * 0.35}px ${sos.color}88`
                : theme.glossy
                  ? "inset 0 4px 8px rgba(0,0,0,.45)"
                  : "none",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            {p && (
              <span
                style={{
                  fontFamily: BODY,
                  fontWeight: 800,
                  fontSize: cell * 0.62,
                  color,
                  scale: String(s),
                  textShadow: theme.glossy ? `0 0 ${cell * 0.25}px ${color}AA, 0 3px 0 ${shade(color, -0.5)}` : "none",
                }}
              >
                {p.letter}
              </span>
            )}
          </div>
        );
      })}

      {/* SOS strike lines */}
      <svg width={px} height={px} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
        {strikes.map((st, k) => {
          if (frame < st.at) return null;
          const [x1, y1] = center(st.cells[0]);
          const [x2, y2] = center(st.cells[2]);
          const t = lerp(frame, [st.at, st.at + 12], [0, 1]);
          return (
            <g key={k}>
              <line x1={x1} y1={y1} x2={x1 + (x2 - x1) * t} y2={y1 + (y2 - y1) * t} stroke={st.color} strokeWidth={cell * 0.2} strokeLinecap="round" opacity={0.35} style={{ filter: `blur(${cell * 0.08}px)` }} />
              <line x1={x1} y1={y1} x2={x1 + (x2 - x1) * t} y2={y1 + (y2 - y1) * t} stroke={st.color} strokeWidth={cell * 0.09} strokeLinecap="round" />
            </g>
          );
        })}
      </svg>

      {/* Finger-tap ripples */}
      {taps.map((tp, k) => {
        const f = frame - tp.at;
        if (f < 0 || f > 16) return null;
        const [cx, cy] = center(tp.idx);
        const r = lerp(f, [0, 16], [cell * 0.2, cell * 0.9]);
        return (
          <div
            key={k}
            style={{
              position: "absolute",
              left: cx - r,
              top: cy - r,
              width: r * 2,
              height: r * 2,
              borderRadius: r * 2,
              border: `5px solid white`,
              opacity: lerp(f, [0, 16], [0.9, 0]),
            }}
          />
        );
      })}
    </div>
  );
};
