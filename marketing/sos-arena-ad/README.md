# SOS Arena: Meta ad video (Instagram + Facebook)

Motion-graphics ad built with [Remotion](https://remotion.dev). Every visual is
rebuilt from the game's own source: `AppColors`, `BoardTheme`s, the arena board
widget, the VS overlay, emotes, shop titles and match summary. The music and
sound effects come from `assets/sounds` and the logo from `assets/branding`.

## Outputs (`../renders/`)

| File | Size | Use in Meta Ads Manager |
|---|---|---|
| `SOS-Arena-Ad-Reel-9x16.mp4` | 1080×1920 | Instagram/Facebook **Reels** and **Stories** |
| `SOS-Arena-Ad-Feed-4x5.mp4` | 1080×1350 | Instagram/Facebook **Feed** post (recommended) |
| `SOS-Arena-Ad-Square-1x1.mp4` | 1080×1080 | Feed, Marketplace, right column |

29 s · 30 fps · H.264 + AAC. In 9:16, all text sits inside the central
1080×1350 area, so the Reels UI overlays never cover it.

## Storyboard

| Time | Scene | Hook for |
|---|---|---|
| 0–2.5 s | **S · O · S** slams in and is struck through, then "3 LETTERS. ENDLESS RIVALRY." | thumb-stop |
| 2.5–7.5 s | Real gameplay on the Dark Arena board: double SOS, combo, live scores | gamers |
| 7.5–10.5 s | VS screen, YOU 😎 vs BAE 😍, "Loser picks the movie 🍿" | couples, girls & boys |
| 10.5–15.5 s | Date Night · Gamers · Squad Goals · Solo AI cards | everyone |
| 15.5–21.5 s | Emotes → 5 board themes + magic spells → rank ladder to SOS Legend | engagement |
| 21.5–24.5 s | VICTORY! trophy, confetti, final standings | reward |
| 24.5–29 s | App icon, SOS ARENA wordmark, **PLAY FREE NOW**, Google Play · playsos.web.app | CTA |

## Voiceover

Upbeat female narration (Kokoro neural TTS, voice `af_heart`). The music ducks
under every line.

| Scene | Line |
|---|---|
| Hook | "Three letters. Endless rivalry!" |
| Gameplay | "Place an S, or an O. Make S.O.S… and steal the lead!" |
| VS | "Challenge your partner. Loser picks the movie!" |
| Audiences | "Date night. Gamers. Your squad. Or solo, against the A.I." |
| Features | "Trash talk with emotes, unlock themes and magic spells, and rise to S.O.S. Legend!" |
| Victory | "Victory never felt this good!" |
| CTA | "S.O.S. Arena. Play free, now!" |

To change the wording or the voice, edit `LINES` in `voiceover/generate_vo.py`
and run it (see the file header). Other Kokoro voices: `af_bella`, `af_nicole`,
`am_michael`, `am_fenrir`, `bf_emma`… To use a human voice actor instead,
replace the WAVs in `public/vo/` (same file names) and update
`public/vo/durations.json`.

## Suggested ad copy

- **Primary text:** Remember SOS from the back of your notebook? 📝 Now it's a live battle. Challenge your partner, your bestie or the whole world, and talk trash with emotes. 😎👑 Free to play!
- **Headline:** Can you beat your partner at SOS? 💕
- **Alt headlines:** "3 letters. Endless rivalry." · "Loser picks the movie 🍿" · "Date night just got competitive"
- **CTA button:** Install Now (link to Google Play) / Play Game (link to playsos.web.app)

## Editing / re-rendering

```bash
npm i
npm run dev                       # Remotion Studio preview
npx remotion render Reel-9x16 ../renders/SOS-Arena-Ad-Reel-9x16.mp4 --crf=18
```

In a sandbox without Remotion's Chrome download host, set
`REMOTION_BROWSER=/path/to/chrome-headless-shell`.

Scenes live in `src/scenes/`, shared pieces in `src/components/`, and the
palette in `src/theme.ts`.
