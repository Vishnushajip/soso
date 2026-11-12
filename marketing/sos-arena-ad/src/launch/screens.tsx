import React from "react";
import { lerp, pop } from "../anim";
import { Board, Placement, Strike } from "../components/Board";
import { C, HEADING } from "../theme";
import { AppAvatar, BALOO, BottomNav, FREDOKA, Icon, L, OUTFIT, SnackBar, StatusBar, Tap } from "./ui";

/* ---------------- Home: game_mode_select_screen.dart ---------------- */

const SectionLabel: React.FC<{ label: string; chip: React.ReactNode }> = ({ label, chip }) => (
  <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", margin: "18px 4px 10px" }}>
    <span style={{ fontFamily: HEADING, fontSize: 17, color: L.onSurface, letterSpacing: 0.5 }}>{label}</span>
    {chip}
  </div>
);

const ModeCard: React.FC<{ title: string; sub: string; badge: string; icon: string; bg: string; border: string; accent: string; action?: string; glow?: number }> = ({ title, sub, badge, icon, bg, border, accent, action = "PLAY", glow = 0 }) => (
  <div style={{ flex: 1, height: 172, borderRadius: 26, background: `linear-gradient(160deg, #fff, ${bg})`, border: `1.5px solid ${border}`, boxShadow: `0 8px ${16 + glow * 14}px ${accent}${glow ? "55" : "22"}`, padding: 12, boxSizing: "border-box", display: "flex", flexDirection: "column", scale: String(1 + glow * 0.03) }}>
    <span style={{ alignSelf: "flex-start", fontFamily: OUTFIT, fontWeight: 800, fontSize: 9, color: accent, background: `${accent}1F`, border: `1px solid ${accent}55`, borderRadius: 6, padding: "2px 6px", letterSpacing: 0.6 }}>{badge}</span>
    <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div style={{ width: 52, height: 52, borderRadius: 99, background: `radial-gradient(circle, ${accent}33, ${accent}10)`, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <Icon name={icon} size={32} color={accent} />
      </div>
    </div>
    <div style={{ fontFamily: BALOO, fontWeight: 800, fontSize: 15, color: L.onSurface, lineHeight: 1.1 }}>{title}</div>
    <div style={{ fontFamily: OUTFIT, fontSize: 10.5, color: L.muted, marginTop: 2, lineHeight: 1.2 }}>{sub}</div>
    <div style={{ marginTop: 7, alignSelf: "flex-start", display: "flex", alignItems: "center", gap: 3, background: accent, color: "#fff", borderRadius: 10, padding: "3px 9px", fontFamily: HEADING, fontSize: 11 }}>
      {action} <Icon name="arrow_forward" size={12} color="#fff" />
    </div>
  </div>
);

export const HomeScreen: React.FC<{ f: number; tapAt?: number }> = ({ f, tapAt = 9999 }) => {
  const glow = f >= tapAt - 8 ? lerp(f, [tapAt - 8, tapAt], [0, 1]) : 0;
  return (
    <div style={{ position: "absolute", inset: 0, background: L.bg }}>
      <StatusBar />
      {/* Header */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "6px 18px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <AppAvatar letter="V" color={C.primary} size={40} ring="#fff" />
          <div>
            <div style={{ fontFamily: HEADING, fontSize: 14, color: L.onSurface, letterSpacing: 0.5 }}>VISHNU</div>
            <div style={{ display: "flex", alignItems: "center", gap: 3, fontFamily: OUTFIT, fontWeight: 700, fontSize: 11, color: C.primary, letterSpacing: 0.8 }}>
              <Icon name="sports_esports" size={13} color={C.primary} /> Arena
            </div>
          </div>
        </div>
        <div style={{ display: "flex", gap: 10 }}>
          {["notifications", "chat"].map((n, i) => (
            <div key={n} style={{ position: "relative", width: 40, height: 40, borderRadius: 14, background: "#fff", boxShadow: "0 3px 10px rgba(106,56,212,.15)", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <Icon name={n} size={22} color={C.primary} />
              {i === 1 && <div style={{ position: "absolute", top: 7, right: 7, width: 9, height: 9, borderRadius: 9, background: C.danger, border: "1.5px solid #fff" }} />}
            </div>
          ))}
        </div>
      </div>
      <div style={{ padding: "6px 16px" }}>
        {/* Hero card */}
        <div style={{ height: 178, borderRadius: 24, background: "linear-gradient(135deg, #3F1973, #1A0A36 55%, #280E54)", position: "relative", overflow: "hidden", padding: 18, boxSizing: "border-box", boxShadow: "0 12px 26px rgba(63,25,115,.35)" }}>
          <div style={{ display: "inline-flex", alignItems: "center", gap: 5, padding: "3px 9px", borderRadius: 10, background: "rgba(255,255,255,.14)", border: "1px solid rgba(255,255,255,.2)" }}>
            <div style={{ width: 7, height: 7, borderRadius: 7, background: C.arenaGold, boxShadow: `0 0 8px ${C.arenaGold}` }} />
            <span style={{ fontFamily: HEADING, fontSize: 10, color: C.arenaGold, letterSpacing: 1 }}>LIVE MULTIPLAYER</span>
          </div>
          <div style={{ fontFamily: HEADING, fontSize: 25, color: "#fff", marginTop: 10, textShadow: `0 2px 4px rgba(0,0,0,.7), 0 0 10px ${C.secondary}80` }}>COMPETE & WIN</div>
          <div style={{ fontFamily: OUTFIT, fontSize: 11, color: "rgba(255,255,255,.75)", marginTop: 2 }}>Battle worldwide · Climb the ranks</div>
          <div style={{ marginTop: 14, display: "inline-flex", alignItems: "center", gap: 4, padding: "8px 16px", borderRadius: 14, background: "linear-gradient(180deg,#FFD54F,#FFB300)", fontFamily: HEADING, fontSize: 15, color: "#5a3300", boxShadow: "0 4px 0 #b97c00" }}>
            <Icon name="play_arrow" size={18} color="#5a3300" /> PLAY NOW
          </div>
          {[["S", C.accent, 250, 22, -12], ["O", C.secondary, 300, 70, 10]].map(([l, col, x, y, r], i) => (
            <div key={i} style={{ position: "absolute", left: x as number, top: (y as number) + Math.sin((f + i * 20) / 10) * 5, rotate: `${r}deg`, width: 54, height: 54, borderRadius: 14, background: `linear-gradient(145deg, ${col}, #1A0A36)`, border: "2px solid rgba(255,255,255,.35)", display: "flex", alignItems: "center", justifyContent: "center", fontFamily: OUTFIT, fontWeight: 800, fontSize: 30, color: "#fff", boxShadow: `0 0 18px ${col}` }}>{l}</div>
          ))}
        </div>
        <SectionLabel
          label="Online"
          chip={<span style={{ display: "flex", alignItems: "center", gap: 5, fontFamily: OUTFIT, fontWeight: 700, fontSize: 11, color: C.tertiary, background: `${C.tertiary}14`, padding: "3px 9px", borderRadius: 10 }}><span style={{ width: 7, height: 7, borderRadius: 7, background: C.tertiaryContainer }} />128 Online</span>}
        />
        <div style={{ display: "flex", gap: 14 }}>
          <ModeCard title="Ranked Match" sub="Climb the global leaderboard" badge="RANKED" icon="emoji_events" bg="#FFF7ED" border="#FFE5D0" accent={C.secondary} />
          <ModeCard title="Friend Challenge" sub="Invite your online friends" badge="ONLINE" icon="people_alt" bg="#F0FDF4" border="#DCF7E9" accent={C.tertiary} glow={glow} />
        </div>
        <SectionLabel
          label="Same Device & AI"
          chip={<span style={{ fontFamily: OUTFIT, fontWeight: 800, fontSize: 10, color: C.primary, background: `${C.primary}14`, padding: "3px 9px", borderRadius: 10, letterSpacing: 0.8 }}>OFFLINE</span>}
        />
        <div style={{ display: "flex", gap: 14 }}>
          <ModeCard title="Pass & Play" sub="Up to 4 players on one screen" badge="LOCAL" icon="sports_esports" bg="#F5F3FF" border="#EDE9FE" accent={C.primary} />
          <ModeCard title="VS AI Bot" sub="Easy • Medium • Hard AI" badge="OFFLINE" icon="smart_toy" bg="#F0FDFA" border="#CCFBF1" accent={C.tertiary} action="PRACTICE" />
        </div>
      </div>
      <BottomNav active="Play" />
      <Tap f={f} at={tapAt} x={292} y={432} />
    </div>
  );
};

/* ---------------- Friends: friends_screen.dart ---------------- */

const FriendTile: React.FC<{ name: string; letter: string; color: string; online: boolean; status: string; title?: string; pulse?: number }> = ({ name, letter, color, online, status, title, pulse = 0 }) => {
  const accent = online ? C.tertiary : C.primary;
  return (
    <div style={{ borderRadius: 24, background: `linear-gradient(135deg, ${L.surface}, #FFFFFFD0)`, border: `2px solid ${accent}59`, padding: "14px 14px 14px 16px", display: "flex", alignItems: "center", gap: 13, boxShadow: "0 6px 16px rgba(106,56,212,.08)" }}>
      <AppAvatar letter={letter} color={color} size={54} online={online} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
          <span style={{ fontFamily: BALOO, fontWeight: 800, fontSize: 17, color: L.onSurface, letterSpacing: 0.3 }}>{name}</span>
          {title && <span style={{ fontFamily: BALOO, fontWeight: 800, fontSize: 9, color: "#fff", background: `linear-gradient(90deg, ${C.secondary}, ${C.primary})`, borderRadius: 8, padding: "1px 7px" }}>{title}</span>}
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 3 }}>
          <span style={{ width: 7, height: 7, borderRadius: 7, background: online ? C.tertiary : `${L.muted}66` }} />
          <span style={{ fontFamily: FREDOKA, fontWeight: 500, fontSize: 12, color: online ? C.tertiary : L.muted }}>{status}</span>
        </div>
      </div>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 8 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 6, padding: "8px 13px", borderRadius: 15, background: `linear-gradient(135deg, ${C.secondary}, ${C.primary})`, border: "1.5px solid rgba(255,255,255,.3)", fontFamily: BALOO, fontWeight: 800, fontSize: 13, color: "#fff", scale: String(1 + pulse * 0.08), boxShadow: pulse ? `0 0 ${pulse * 18}px ${C.secondary}` : "none" }}>
          <Icon name="sports_esports" size={17} color="#fff" /> Challenge
        </div>
        <div style={{ display: "flex", gap: 8 }}>
          {[["chat_bubble", C.primary], ["person_remove", C.danger]].map(([n, c]) => (
            <div key={n} style={{ width: 32, height: 32, borderRadius: 11, background: `${c}14`, border: `1px solid ${c}33`, display: "flex", alignItems: "center", justifyContent: "center" }}>
              <Icon name={n} size={17} color={c} />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export const FriendsScreen: React.FC<{ f: number; tapAt: number }> = ({ f, tapAt }) => {
  const pulse = f >= tapAt - 6 ? lerp(f, [tapAt - 6, tapAt, tapAt + 10], [0, 1, 0]) : 0;
  return (
    <div style={{ position: "absolute", inset: 0, background: L.bg }}>
      <StatusBar />
      <div style={{ padding: "8px 18px 0" }}>
        <div style={{ fontFamily: HEADING, fontSize: 26, color: L.onSurface, letterSpacing: 0.5 }}>Friends</div>
        <div style={{ fontFamily: OUTFIT, fontSize: 13, color: L.muted, marginTop: 2 }}>Your squad · 3 friends</div>
        <div style={{ display: "flex", gap: 10, marginTop: 14 }}>
          {[["Add Friend", "person_add_alt_1", C.primary], ["Requests (1)", "mark_email_unread", C.secondary]].map(([l, ic, c]) => (
            <div key={l} style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center", gap: 7, padding: "11px 0", borderRadius: 16, background: `${c}14`, border: `1.5px solid ${c}55`, fontFamily: BALOO, fontWeight: 800, fontSize: 14, color: c }}>
              <Icon name={ic} size={19} color={c} /> {l}
            </div>
          ))}
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 12, marginTop: 18 }}>
          {[
            { name: "Anu", letter: "A", color: C.arenaPink, online: true, status: "Online now", title: "SOS LEGEND", pulse },
            { name: "Rahul", letter: "R", color: C.accent, online: true, status: "Online now" },
            { name: "Meera", letter: "M", color: C.secondary, online: false, status: "Last seen 2h ago", title: "STRATEGIST" },
          ].map((p, i) => (
            <div key={p.name} style={{ opacity: lerp(f, [i * 4, i * 4 + 8], [0, 1]), translate: `0 ${lerp(f, [i * 4, i * 4 + 10], [24, 0])}px` }}>
              <FriendTile {...p} />
            </div>
          ))}
        </div>
      </div>
      <BottomNav active="Friends" />
      <Tap f={f} at={tapAt} x={312} y={262} />
      <SnackBar f={f} at={tapAt + 6} text="Challenge sent to Anu!" icon="sports_esports" />
    </div>
  );
};

/* ---------------- Match: game_board_screen.dart + arena_widgets.dart ---------------- */

const PlayerBanner: React.FC<{ name: string; letter: string; color: string; score: number; active: boolean; align: "left" | "right" }> = ({ name, letter, color, score, active, align }) => (
  <div style={{ flex: 1, display: "flex", flexDirection: align === "left" ? "row" : "row-reverse", alignItems: "center", gap: 8, padding: "8px 10px", borderRadius: 14, background: `linear-gradient(135deg, ${color}8C, ${color}1F)`, border: `${active ? 2.2 : 1}px solid ${active ? color : color + "4D"}`, boxShadow: active ? `0 0 14px ${color}73` : "none" }}>
    <AppAvatar letter={letter} color={color} size={38} ring="rgba(255,255,255,.85)" />
    <div style={{ flex: 1, textAlign: align }}>
      <div style={{ display: "flex", alignItems: "center", gap: 4, justifyContent: align === "left" ? "flex-start" : "flex-end" }}>
        <Icon name="emoji_events" size={13} color={C.arenaGold} />
        <span style={{ fontFamily: OUTFIT, fontWeight: 800, fontSize: 13, color: "#fff" }}>{name}</span>
      </div>
      <div style={{ height: 6, borderRadius: 8, background: "rgba(0,0,0,.35)", marginTop: 5, overflow: "hidden" }}>
        <div style={{ width: `${Math.min(100, score * 12)}%`, height: "100%", background: `linear-gradient(90deg, ${color}aa, ${color})`, marginLeft: align === "right" ? "auto" : 0 }} />
      </div>
      <div style={{ fontFamily: OUTFIT, fontWeight: 600, fontSize: 11, color: "rgba(241,236,255,.85)", marginTop: 3 }}>{score} pts</div>
    </div>
  </div>
);

const MOVE = { you: 20, anu: 55, you2: 85 };
const placements: Placement[] = [
  ...([[0, "S"], [2, "O"], [4, "S"], [6, "O"], [8, "S"], [10, "O"], [14, "O"], [16, "S"], [18, "O"], [20, "S"], [21, "O"], [24, "S"]] as [number, "S" | "O"][]).map(([idx, letter]) => ({ idx, letter, at: -5 })),
  { idx: 12, letter: "S", at: MOVE.you },
  { idx: 17, letter: "O", at: MOVE.anu },
  { idx: 22, letter: "S", at: MOVE.you2 },
];
const strikes: Strike[] = [
  { cells: [0, 6, 12], at: MOVE.you + 3, color: C.arenaBlue },
  { cells: [12, 18, 24], at: MOVE.you + 6, color: C.arenaBlue },
  { cells: [20, 21, 22], at: MOVE.you2 + 3, color: C.arenaBlue },
  { cells: [12, 17, 22], at: MOVE.you2 + 6, color: C.arenaBlue },
];

export const MatchScreen: React.FC<{ f: number; chatAt?: number }> = ({ f, chatAt = 9999 }) => {
  const you = f >= MOVE.you2 + 6 ? 8 : f >= MOVE.you + 6 ? 6 : 4;
  const yourTurn = f < MOVE.you + 30 || f >= MOVE.anu + 6;
  return (
    <div style={{ position: "absolute", inset: 0, background: `linear-gradient(180deg, ${C.arenaBgTop}, ${C.arenaBgBottom})` }}>
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 260, background: `radial-gradient(ellipse 90% 60% at 50% 110%, ${C.arenaGlow}55, transparent 70%)` }} />
      <StatusBar dark />
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "4px 14px" }}>
        <Icon name="arrow_back_ios_new" size={20} color="#fff" />
        <span style={{ fontFamily: HEADING, fontSize: 17, color: "#fff", letterSpacing: 0.6 }}>SOS Arena Match</span>
        <Icon name="palette" size={22} color="#fff" />
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 6, padding: "10px 12px 0" }}>
        <PlayerBanner name="You" letter="V" color={C.arenaBlue} score={you} active={yourTurn} align="left" />
        <div style={{ width: 38, height: 38, borderRadius: 99, flexShrink: 0, background: `linear-gradient(135deg, ${C.arenaGold}, ${C.arenaGlow})`, border: "2px solid rgba(255,255,255,.6)", boxShadow: `0 0 12px ${C.arenaGlow}80`, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: HEADING, fontSize: 14, color: "#fff", paddingTop: 2 }}>VS</div>
        <PlayerBanner name="Anu" letter="A" color={C.arenaPink} score={5} active={!yourTurn} align="right" />
      </div>
      <div style={{ display: "flex", justifyContent: "center", marginTop: 14 }}>
        <div style={{ padding: "5px 16px", borderRadius: 20, background: yourTurn ? `${C.arenaBlue}33` : `${C.arenaPink}33`, border: `1.5px solid ${yourTurn ? C.arenaBlue : C.arenaPink}`, fontFamily: HEADING, fontSize: 13, color: "#fff", letterSpacing: 1 }}>
          {yourTurn ? "YOUR TURN" : "OPPONENT'S TURN"}
        </div>
      </div>
      <div style={{ display: "flex", justifyContent: "center", marginTop: 14 }}>
        <Board n={5} px={360} placements={placements} strikes={strikes} taps={[{ idx: 12, at: MOVE.you - 4 }, { idx: 22, at: MOVE.you2 - 4 }]} />
      </div>
      {/* Chat FAB */}
      <div style={{ position: "absolute", right: 18, bottom: 40, width: 58, height: 58, borderRadius: 99, background: `linear-gradient(135deg, ${C.primary}, ${C.accent})`, border: "2px solid rgba(255,255,255,.3)", boxShadow: `0 6px 18px ${C.primary}88`, display: "flex", alignItems: "center", justifyContent: "center", scale: String(1 + 0.06 * Math.max(0, Math.sin(f / 5))) }}>
        <Icon name="chat_bubble" size={27} color="#fff" />
        <div style={{ position: "absolute", top: 4, right: 4, minWidth: 18, height: 18, borderRadius: 9, background: C.danger, border: "2px solid #fff", fontFamily: OUTFIT, fontWeight: 800, fontSize: 10, color: "#fff", display: "flex", alignItems: "center", justifyContent: "center" }}>1</div>
      </div>
      <Tap f={f} at={chatAt - 2} x={351} y={775} />
      <ChatSheet f={f - chatAt} />
    </div>
  );
};

/* ---------------- In-game chat: in_game_chat_sheet.dart ---------------- */

type Msg = { at: number; mine: boolean; text: string; reaction?: boolean };
const MSGS: Msg[] = [
  { at: 10, mine: false, text: "ready to lose? 😏" },
  { at: 32, mine: true, text: "you wish 😂 watch this" },
  { at: 58, mine: false, text: "ok that double SOS was good" },
  { at: 82, mine: false, text: "❤️", reaction: true },
  { at: 104, mine: true, text: "one more round after this?" },
];

const ChatSheet: React.FC<{ f: number }> = ({ f }) => {
  if (f < 0) return null;
  const y = lerp(f, [0, 10], [520, 0]);
  const typing = (f > 44 && f < 58) || (f > 70 && f < 82);
  const draft = "one more round after this?";
  const typed = f > 86 && f < 104 ? draft.slice(0, Math.floor(lerp(f, [86, 101], [0, draft.length]))) : "";
  return (
    <>
      <div style={{ position: "absolute", inset: 0, background: `rgba(7,4,16,${lerp(f, [0, 10], [0, 0.45])})` }} />
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 500, translate: `0 ${y}px`, background: `linear-gradient(180deg, ${C.arenaStone}, ${C.arenaBgBottom})`, borderTopLeftRadius: 28, borderTopRightRadius: 28, border: `1.5px solid ${C.arenaGold}59`, borderBottom: "none", boxShadow: "0 -10px 30px rgba(0,0,0,.5)", display: "flex", flexDirection: "column" }}>
        <div style={{ alignSelf: "center", width: 40, height: 4, borderRadius: 2, background: `${C.onArenaMuted}66`, marginTop: 10 }} />
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 18px", borderBottom: `1px solid ${C.arenaGold}2E` }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <Icon name="chat" size={20} color={C.arenaGold} />
            <span style={{ fontFamily: HEADING, fontSize: 16, color: C.arenaGold, letterSpacing: 1 }}>MATCH CHAT</span>
          </div>
          <div style={{ width: 30, height: 30, borderRadius: 99, background: `${C.arenaBgBottom}80`, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Icon name="close" size={18} color={C.onArenaMuted} />
          </div>
        </div>
        <div style={{ flex: 1, padding: "12px 16px", display: "flex", flexDirection: "column", justifyContent: "flex-end", gap: 8, overflow: "hidden" }}>
          {MSGS.filter((m) => f >= m.at).map((m, i) => {
            const p = pop(f, m.at, 12, 0.6);
            return (
              <div key={i} style={{ alignSelf: m.mine ? "flex-end" : "flex-start", maxWidth: "78%", scale: String(0.6 + 0.4 * p), opacity: Math.min(1, p * 2), transformOrigin: m.mine ? "right bottom" : "left bottom" }}>
                <div
                  style={{
                    padding: m.reaction ? "2px 6px" : "9px 14px",
                    borderRadius: 18,
                    borderBottomRightRadius: m.mine ? 4 : 18,
                    borderBottomLeftRadius: m.mine ? 18 : 4,
                    background: m.reaction ? "transparent" : m.mine ? `linear-gradient(135deg, ${C.primary}, ${C.accent})` : C.arenaStoneEdge,
                    fontFamily: OUTFIT,
                    fontSize: m.reaction ? 34 : 14,
                    fontWeight: 500,
                    color: m.mine ? "#fff" : C.onArena,
                  }}
                >
                  {m.text}
                </div>
              </div>
            );
          })}
        </div>
        <div style={{ height: 16, padding: "0 18px", fontFamily: OUTFIT, fontSize: 10, fontStyle: "italic", color: C.secondary, opacity: typing ? 1 : 0 }}>Opponent is typing…</div>
        <div style={{ display: "flex", gap: 8, padding: "6px 16px" }}>
          {["👍", "😂", "🔥", "😮", "❤️"].map((e, i) => (
            <div key={e} style={{ width: 40, height: 40, borderRadius: 12, background: `${C.arenaBgBottom}80`, border: `1px solid ${C.arenaGold}33`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20, scale: String(e === "❤️" && f > 78 && f < 86 ? 1.2 : 1) }}>{e}</div>
          ))}
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "8px 16px 30px" }}>
          <div style={{ flex: 1, height: 46, borderRadius: 24, background: `${C.arenaBgBottom}99`, border: `1px solid ${C.arenaGold}4D`, display: "flex", alignItems: "center", padding: "0 16px", fontFamily: OUTFIT, fontSize: 14, color: typed ? C.onArena : `${C.onArenaMuted}99` }}>
            {typed || "Send message…"}
            {typed && <span style={{ width: 2, height: 18, background: C.arenaGold, marginLeft: 1, opacity: Math.floor(f / 6) % 2 }} />}
          </div>
          <div style={{ width: 46, height: 46, borderRadius: 99, background: typed ? `linear-gradient(135deg, ${C.primary}, ${C.accent})` : `${C.onArenaMuted}33`, display: "flex", alignItems: "center", justifyContent: "center", border: "1px solid rgba(255,255,255,.2)" }}>
            <Icon name="send" size={20} color={typed ? "#fff" : C.onArenaMuted} />
          </div>
        </div>
      </div>
    </>
  );
};

/* ---------------- Friend requests: friend_requests_screen.dart ---------------- */

export const RequestsScreen: React.FC<{ f: number; tapAt: number }> = ({ f, tapAt }) => {
  const gone = f >= tapAt + 4 ? lerp(f, [tapAt + 4, tapAt + 14], [0, 1]) : 0;
  return (
    <div style={{ position: "absolute", inset: 0, background: L.bg }}>
      <StatusBar />
      <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "8px 16px" }}>
        <Icon name="arrow_back_ios_new" size={20} color={L.onSurface} />
        <span style={{ fontFamily: HEADING, fontSize: 22, color: L.onSurface }}>Friend Requests</span>
      </div>
      <div style={{ display: "flex", margin: "10px 16px", padding: 4, borderRadius: 16, background: L.surfaceHigh }}>
        {["Incoming", "Sent"].map((t, i) => (
          <div key={t} style={{ flex: 1, textAlign: "center", padding: "9px 0", borderRadius: 13, background: i === 0 ? "#fff" : "transparent", boxShadow: i === 0 ? "0 2px 8px rgba(106,56,212,.15)" : "none", fontFamily: BALOO, fontWeight: 800, fontSize: 14, color: i === 0 ? C.primary : L.muted }}>{t}</div>
        ))}
      </div>
      <div style={{ padding: "6px 16px", display: "flex", flexDirection: "column", gap: 12 }}>
        {[
          { n: "Arjun", l: "A", c: C.player6, id: "ID: SOS-4821" },
          { n: "Diya", l: "D", c: C.arenaPink, id: "ID: SOS-1307" },
        ].map((r, i) => (
          <div key={r.n} style={{ opacity: i === 0 ? 1 - gone : 1, translate: i === 0 ? `${gone * 380}px 0` : `0 ${-gone * 84}px`, borderRadius: 22, background: "#fff", border: `2px solid ${C.primary}2E`, padding: 14, display: "flex", alignItems: "center", gap: 12, boxShadow: "0 6px 16px rgba(106,56,212,.08)" }}>
            <AppAvatar letter={r.l} color={r.c} size={50} online />
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: BALOO, fontWeight: 800, fontSize: 17, color: L.onSurface }}>{r.n}</div>
              <div style={{ fontFamily: FREDOKA, fontWeight: 500, fontSize: 12, color: L.muted }}>Wants to be friends · {r.id}</div>
            </div>
            <div style={{ width: 40, height: 40, borderRadius: 13, background: `${C.tertiary}1F`, border: `1.5px solid ${C.tertiary}66`, display: "flex", alignItems: "center", justifyContent: "center" }}>
              <Icon name="check" size={22} color={C.tertiary} />
            </div>
            <div style={{ width: 40, height: 40, borderRadius: 13, background: `${C.danger}14`, border: `1.5px solid ${C.danger}44`, display: "flex", alignItems: "center", justifyContent: "center" }}>
              <Icon name="close" size={22} color={C.danger} />
            </div>
          </div>
        ))}
      </div>
      <BottomNav active="Friends" />
      <Tap f={f} at={tapAt} x={290} y={199} />
      <SnackBar f={f} at={tapAt + 8} text="You and Arjun are now friends" icon="person_add" />
    </div>
  );
};
