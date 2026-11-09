# SOS Arena: Ads knowledge base

_Last updated: 9 Nov 2026. Upload this file to the Claude Project's files._

## 1. The product
- **SOS Arena**: the classic pen-and-paper SOS game as a real-time online battle.
- Web (no download): https://playsos.web.app. An older link, `sosarena.web.app`,
  appears in old Instagram posts; check that it still works.
- Android package: `com.sosarena.app`. Public Play Store link (once live):
  https://play.google.com/store/apps/details?id=com.sosarena.app
- Features to advertise: ranked online matches, friend challenges, Pass & Play on
  one phone (up to 4 players), offline AI (Easy/Medium/Mastermind), emotes
  (GG!, TOO EASY!, OMG!…), 5 board themes, magic spells (Undo, Erase),
  rank titles (Rookie → SOS Legend), daily rewards, global leaderboard.
- Audiences: couples (date night), friends/besties, casual gamers, nostalgia
  (people who played SOS in school), age 18–34, India.

## 2. Meta account map (only use these)
| Item | Name | ID |
|---|---|---|
| Business | Soso | `1156189180677672` |
| Ad account | vishnu.tech.ad (INR) | `1432751848521962` |
| Facebook Page | Vishnu.tech | `1509305705590508` |
| Instagram | @_vishnu.tech | `17841427470506762` |
| Pixel / dataset | soso | `1177298888582680` |

- Min daily budget for this account: about **₹95.67/day**.
- The login also sees other businesses' accounts (Famous Bakery, GK CAFE, ALKA,
  VISHNU., one disabled account). **Never use them for SOS Arena.**
- Ads show as "Vishnu.tech". A dedicated SOS Arena Page and Instagram would
  build the brand better (to do).
- Pixel status on 9 Nov 2026: created, **never fired**. The website integration
  is not deployed yet. Integration prompt: see repo `marketing/` history.

## 3. Creatives
| File (repo `marketing/renders/`) | Size | Use |
|---|---|---|
| SOS-Arena-Ad-Reel-9x16.mp4 | 1080×1920, 29s | Reels, Stories |
| SOS-Arena-Ad-Feed-4x5.mp4 | 1080×1350, 29s | Feed |
| SOS-Arena-Ad-Square-1x1.mp4 | 1080×1080, 29s | Other placements |

The videos have a female AI voiceover, the game's theme music and on-screen
captions (they work muted).

Instagram posts on @_vishnu.tech that can be promoted:
| Media ID | Date | What |
|---|---|---|
| `18387971686239569` | 9 Nov 2026 | **SOS Arena ad Reel** (29s): use this for ads |
| `18106525528896521` | 4 Jun 2026 | Image: "SOS ARENA IS NOW LIVE ON WEB!" |
| `18108849485304062` | 4 Jun 2026 | Image: "MATCH CHAT IS HERE!" (14 likes) |
| `17970502035058580` | 4 Jun 2026 | Reel 10s: "Download Now" |
| `18098821361415436` | 9 Nov 2026 | ResumeAchieve (NOT SOS, don't use) |

## 4. Copy bank
**Hooks / first lines to A/B test**
- Loser picks the movie 🍿 (couples)
- Think you're smart? Prove it in 3 letters 🧠 (gamers)
- The SOS game from school is back ✏️ (nostalgia, strong on Facebook)
- 3 letters. Endless rivalry.

**Primary text:** Remember SOS from school? 📝 Now it's a live battle. Challenge
your partner, your bestie or the AI, and talk trash with emotes 😎 Free, no
download needed!

**Headlines:** Can you beat your partner at SOS? 💕 · SOS Arena: Play Free Now ·
Date night just got competitive

**Hashtags (max 5 on IG):** #sosgame #couplegames #mobilegames #gamenight #playwithfriends

## 5. Campaign history
### Test 1: launched 9 Nov 2026
| Level | Name | ID |
|---|---|---|
| Campaign | SOS Arena \| Traffic \| Test 1 \| Rs200 | `120247933834960658` |
| Ad set | India 18+ (18-34 suggested) \| Advantage+ \| Reel | `120247933835370658` |
| Ad | Reel \| SOS battle \| couples hook | `120247933837210658` |

- Boosted IG post `18387971686239569`, objective Traffic, optimize Link clicks.
- **Lifetime budget ₹200**, ends **11 Nov 2026 10:00 IST**.
- Targeting: India, 18+, Advantage+ audience (18–34 suggestion).
- Button: Learn More → https://playsos.web.app/
- UTM: `utm_source=instagram&utm_medium=paid_social&utm_campaign=sos_test1&utm_content=reel_couples`
- Note: ₹200 ending 11 Nov 22:00 was rejected (minimum ₹205.45), so the end
  date was moved earlier.
- Status at launch: campaign + ad set ACTIVE, ad IN_PROCESS (Meta review).
- Results: _to be filled after it ends_.

## 6. Benchmarks (rough, India gaming ads)
| Metric | Good | If bad |
|---|---|---|
| Hook rate (3-sec views ÷ impressions) | > 25% | Change the opening 2s |
| CTR (link) | > 1% | Change the first line/hook |
| CPC | ₹2–8 | Broaden audience / new creative |
| Landing page views ÷ link clicks | > 70% | Website too slow |

Decision rules: after about 1,000 impressions, pause ads with CTR < 0.7%. Scale
winners +20% every 2–3 days. Next stage: retarget 50% video viewers, then
lookalike of sign-ups (100+).

## 7. To-do before scaling
- [ ] Deploy the Meta Pixel + events (PlayGame, StartTrial, CompleteRegistration, DownloadApp)
- [ ] Fix site `<title>` (currently "SosArenaApp") + Open Graph tags
- [ ] Set the account spending limit in Billing
- [ ] Consider a dedicated SOS Arena Page + Instagram
- [ ] Rotate the Firebase key that is exposed in the repo README (security)
