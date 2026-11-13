# Project Guidelines & Coding Rules (SOS Arena)

## 1. State Management: Riverpod ONLY — Never use setState()
- **Strict Prohibition**: Do **NOT** use a single `setState()` anywhere in this project when fixing bugs or implementing new features.
- **Riverpod Exclusively**: All reactive state (dialogs, forms, screens, local widgets, global state) must be handled through Riverpod (`Notifier`, `AsyncNotifier`, `StateNotifier`, `StateProvider`, or `ConsumerWidget`).
- Every view must be a `ConsumerWidget` or `ConsumerStatefulWidget` (only for animations / controllers, never for state mutation with `setState`).

## 2. Reusability: Use Existing Classes Only
- **Colors**: Use the existing `AppColors` class only (`lib/core/theme/app_colors.dart`). Never hardcode hex codes or invent ad-hoc colors.
- **Typography**: Use standard existing font styling (`GoogleFonts.luckiestGuy` for game headings/titles and `GoogleFonts.outfit` for UI body, or project `AppFonts`).
- **Inputs & Dropdowns**: Always use existing dropdown and textfield components from the codebase. Never re-implement custom inputs when existing components are available.
- **Feedback & Feedback Buttons**: Use existing `AppButton`, `AppSnackBar`, `UserAvatar`, and `SoundService`.

## 3. Meta Ads (Instagram / Facebook): ask before running any ad
- Full playbook: `marketing/ads-project/PROJECT_INSTRUCTIONS.md` and
  `marketing/ads-project/SOS_ARENA_ADS_KNOWLEDGE.md`. Read both before any ads task.
- **Mandatory:** when asked to run, launch or boost an ad, do NOT create anything
  (not even a paused draft) until the user has answered, in one checklist message:
  total budget (₹), number of days, start date/time, stop date/time, account
  spending limit, click URL, platforms & split (default Instagram 70% / Facebook 30%),
  which video/post, location, age range, run hours, and button text. Show suggested
  defaults, but never silently fill in budget, days, stop date, spending limit or URL.
- Check that budget ÷ days ÷ ad sets ≥ ₹96/day before building; Meta rejects less.
- Placements are always manual (Instagram first, then Facebook). Never use Audience
  Network, Threads, Messenger or WhatsApp Status. Read placements back after creating.
- Use only ad account `1432751848521962` (vishnu.tech.ad). Build paused, show the
  plan, and activate only after the user explicitly says "launch".
