// Faithful re-creations of SOS Arena's real Flutter widgets (lib/features/**),
// laid out in 390-pt "app units" and scaled inside a phone frame.
import "@fontsource/baloo-2/800.css";
import "@fontsource/fredoka/500.css";
import "@fontsource/fredoka/600.css";
import "@fontsource/material-icons-round";
import React from "react";
import { continueRender, delayRender } from "remotion";
import { lerp } from "../anim";
import { C, HEADING, shade } from "../theme";

const h = delayRender("Loading app fonts");
Promise.all([
  document.fonts.load("800 20px 'Baloo 2'"),
  document.fonts.load("500 20px Fredoka"),
  document.fonts.load("600 20px Fredoka"),
  document.fonts.load("24px 'Material Icons Round'"),
]).then(() => continueRender(h)).catch(() => continueRender(h));

// Light theme tokens from AppColors.
export const L = {
  bg: "#FEF7FF",
  surface: "#FEF7FF",
  surfaceHigh: "#EDE5F3",
  onSurface: "#1D1A23",
  muted: "#494454",
  outline: "#CBC3D7",
  inverse: "#322F39",
};
export const BALOO = "'Baloo 2', sans-serif";
export const FREDOKA = "Fredoka, sans-serif";
export const OUTFIT = "Outfit, sans-serif";

export const Icon: React.FC<{ name: string; size?: number; color?: string; style?: React.CSSProperties }> = ({ name, size = 24, color = "currentColor", style }) => (
  <span style={{ fontFamily: "'Material Icons Round'", fontSize: size, lineHeight: 1, color, fontFeatureSettings: "'liga'", display: "inline-block", ...style }}>{name}</span>
);

// UserAvatar fallback: initial on a colored circle (no photos, no characters).
export const AppAvatar: React.FC<{ letter: string; color: string; size: number; online?: boolean; ring?: string }> = ({ letter, color, size, online, ring }) => (
  <div style={{ position: "relative", width: size, height: size, flexShrink: 0 }}>
    <div
      style={{
        width: size,
        height: size,
        borderRadius: size,
        background: `linear-gradient(135deg, ${shade(color, 0.15)}, ${shade(color, -0.2)})`,
        border: ring ? `2px solid ${ring}` : undefined,
        boxSizing: "border-box",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontFamily: HEADING,
        fontSize: size * 0.46,
        color: "white",
        paddingTop: size * 0.06,
      }}
    >
      {letter}
    </div>
    {online && (
      <div style={{ position: "absolute", right: 0, bottom: 0, width: size * 0.28, height: size * 0.28, borderRadius: 99, background: C.tertiary, border: `2.5px solid ${L.surface}` }} />
    )}
  </div>
);

export const StatusBar: React.FC<{ dark?: boolean }> = ({ dark }) => {
  const col = dark ? "#fff" : L.onSurface;
  return (
    <div style={{ height: 44, display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 26px", fontFamily: OUTFIT, fontWeight: 600, fontSize: 15, color: col }}>
      <span>9:41</span>
      <span style={{ display: "flex", gap: 4 }}>
        <Icon name="signal_cellular_alt" size={17} color={col} />
        <Icon name="wifi" size={17} color={col} />
        <Icon name="battery_full" size={17} color={col} />
      </span>
    </div>
  );
};

const TABS: [string, string][] = [
  ["Play", "sports_esports"],
  ["Friends", "group"],
  ["Shop", "storefront"],
  ["Ranks", "emoji_events"],
  ["Profile", "person"],
];

// main_shell.dart bottom navigation.
export const BottomNav: React.FC<{ active: string }> = ({ active }) => (
  <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 84, background: "#FFFFFF", boxShadow: "0 -4px 18px rgba(106,56,212,.10)", display: "flex", paddingBottom: 18 }}>
    {TABS.map(([label, icon]) => {
      const sel = label === active;
      const col = sel ? C.primary : L.muted;
      return (
        <div key={label} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "flex-end" }}>
          <div style={{ width: sel ? 26 : 0, height: 3.5, borderRadius: 10, background: C.primary, marginBottom: 5, boxShadow: sel ? `0 1px 6px ${C.primary}80` : "none" }} />
          <Icon name={icon} size={sel ? 28 : 24} color={col} />
          <span style={{ fontFamily: OUTFIT, fontSize: 10, fontWeight: sel ? 800 : 500, color: col, marginTop: 4 }}>{label}</span>
        </div>
      );
    })}
  </div>
);

// Tap feedback ring (a UI touch indicator, not a character).
export const Tap: React.FC<{ f: number; at: number; x: number; y: number }> = ({ f, at, x, y }) => {
  const t = f - at;
  if (t < -6 || t > 14) return null;
  const pre = lerp(t, [-6, 0], [0, 1]);
  const r = t < 0 ? 22 : lerp(t, [0, 14], [22, 46]);
  const o = t < 0 ? pre * 0.9 : lerp(t, [0, 14], [0.9, 0]);
  return (
    <>
      <div style={{ position: "absolute", left: x - 16, top: y - 16, width: 32, height: 32, borderRadius: 99, background: "rgba(255,255,255,.85)", boxShadow: "0 2px 10px rgba(0,0,0,.35)", opacity: t < 0 ? pre : lerp(t, [0, 8], [1, 0]) }} />
      <div style={{ position: "absolute", left: x - r, top: y - r, width: r * 2, height: r * 2, borderRadius: 99, border: "3px solid rgba(255,255,255,.95)", opacity: o, boxShadow: "0 0 12px rgba(0,0,0,.25)" }} />
    </>
  );
};

export const SnackBar: React.FC<{ f: number; at: number; text: string; icon?: string; bottom?: number }> = ({ f, at, text, icon = "check_circle", bottom = 100 }) => {
  const t = f - at;
  if (t < 0) return null;
  const y = lerp(t, [0, 8], [40, 0]);
  return (
    <div style={{ position: "absolute", left: 16, right: 16, bottom, translate: `0 ${y}px`, opacity: lerp(t, [0, 6], [0, 1]), background: L.inverse, color: "#F5EEFB", borderRadius: 14, padding: "13px 16px", display: "flex", alignItems: "center", gap: 10, fontFamily: OUTFIT, fontWeight: 600, fontSize: 14, boxShadow: "0 8px 20px rgba(0,0,0,.3)" }}>
      <Icon name={icon} size={20} color={C.tertiaryContainer} />
      {text}
    </div>
  );
};

// Phone shell; children are drawn on a 390x844 screen.
export const SCREEN_W = 390;
export const SCREEN_H = 844;
export const Phone: React.FC<{ scale: number; children: React.ReactNode }> = ({ scale, children }) => (
  <div
    style={{
      width: (SCREEN_W + 24) * scale,
      height: (SCREEN_H + 24) * scale,
      borderRadius: 62 * scale,
      background: "linear-gradient(145deg, #3a3550, #121019)",
      padding: 12 * scale,
      boxSizing: "border-box",
      boxShadow: `0 40px 90px rgba(0,0,0,.6), 0 0 0 ${2 * scale}px #4a4466, 0 0 120px ${C.primary}55`,
    }}
  >
    <div style={{ width: SCREEN_W * scale, height: SCREEN_H * scale, borderRadius: 50 * scale, overflow: "hidden", position: "relative", background: L.bg }}>
      <div style={{ width: SCREEN_W, height: SCREEN_H, scale: String(scale), transformOrigin: "0 0", position: "absolute", left: 0, top: 0 }}>
        {children}
        {/* dynamic island */}
        <div style={{ position: "absolute", top: 10, left: SCREEN_W / 2 - 55, width: 110, height: 30, borderRadius: 20, background: "#000" }} />
      </div>
    </div>
  </div>
);
