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
