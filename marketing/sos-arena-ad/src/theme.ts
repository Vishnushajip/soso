// Mirrors lib/core/theme/app_colors.dart and lib/core/theme/board_theme.dart
// so the ad uses the exact palette the game ships with.
export const C = {
  primary: "#6A38D4",
  primaryContainer: "#8455EE",
  inversePrimary: "#D0BCFF",
  secondary: "#FD9D06",
  tertiary: "#008730",
  tertiaryContainer: "#47E266",
  accent: "#3B82F6",
  danger: "#BA1A1A",

  arenaBgTop: "#1A1230",
  arenaBgBottom: "#070410",
  arenaGlow: "#FF6A00",
  arenaStone: "#231B3D",
  arenaStoneEdge: "#3A2F5C",
  arenaCell: "#150F28",
  arenaGold: "#FFC857",
  arenaBlue: "#2EA8FF",
  arenaPink: "#FF3D9A",
  onArena: "#F1ECFF",
  onArenaMuted: "#9C92C7",

  player5: "#FF3D9A",
  player6: "#00C2CB",
  // Logo letters (assets/branding/app_icon.png)
  logoOrange: "#FF8A1F",
  logoBlue: "#2E9BFF",
} as const;

export type BoardThemeDef = {
  name: string;
  boardBg: string;
  border: string;
  cell: string;
  s: string;
  o: string;
  highlight: string;
  glossy: boolean;
};

export const BOARD_THEMES: BoardThemeDef[] = [
  { name: "Classic", boardBg: "#F2EBF8", border: "#CBC3D7", cell: "#CBC3D7", s: C.accent, o: C.secondary, highlight: C.primary, glossy: false },
  { name: "Dark Arena", boardBg: C.arenaStone, border: C.arenaStoneEdge, cell: C.arenaCell, s: C.accent, o: C.secondary, highlight: C.arenaGold, glossy: true },
  { name: "Ice Frost", boardBg: "#E0F7FA", border: "#B2EBF2", cell: "#B2EBF2", s: "#0277BD", o: "#00695C", highlight: "#4FC3F7", glossy: true },
  { name: "Solar Flare", boardBg: "#FFF3E0", border: "#FFE0B2", cell: "#FFCC80", s: "#D84315", o: "#EF6C00", highlight: "#FFCA28", glossy: true },
  { name: "White Marble", boardBg: "#FAFAFA", border: "#E0E0E0", cell: "#EEEEEE", s: "#212121", o: "#D4AF37", highlight: "#D4AF37", glossy: false },
];

export const FPS = 30;
// Every scene is laid out on this stage; it matches 4:5 exactly, sits inside
// the Reels safe zone on 9:16, and is scaled down on 1:1.
export const STAGE_W = 1080;
export const STAGE_H = 1350;

export const HEADING = "'Luckiest Guy', cursive";
export const BODY = "Outfit, sans-serif";

export const shade = (hex: string, amt: number) => {
  const n = parseInt(hex.slice(1), 16);
  const f = (v: number) =>
    Math.max(0, Math.min(255, Math.round(amt < 0 ? v * (1 + amt) : v + (255 - v) * amt)));
  const r = f(n >> 16), g = f((n >> 8) & 255), b = f(n & 255);
  return `#${((r << 16) | (g << 8) | b).toString(16).padStart(6, "0")}`;
};

export const alpha = (hex: string, a: number) =>
  `${hex}${Math.round(a * 255).toString(16).padStart(2, "0")}`;
