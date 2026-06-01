import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/user_providers.dart';
import '../../../routes/route_names.dart';

class LocalGameSetupScreen extends ConsumerStatefulWidget {
  const LocalGameSetupScreen({super.key});

  @override
  ConsumerState<LocalGameSetupScreen> createState() => _LocalGameSetupScreenState();
}

class _LocalGameSetupScreenState extends ConsumerState<LocalGameSetupScreen> {
  int _playerCount = 2;
  int _boardSize = Env.boardSize;
  late final List<TextEditingController> _names = List.generate(
    AppConstants.maxPlayersLocal,
    (i) => TextEditingController(text: 'Player ${i + 1}'),
  );
  bool _prefilledFromAuth = false;

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefilledFromAuth) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null && user.name.trim().isNotEmpty) {
        _names[0].text = user.name;
        _prefilledFromAuth = true;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pass & Play')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You play as Player 1 — your wins earn profile points.',
                    style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const Text('Players', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var i = AppConstants.minPlayersLocal; i <= AppConstants.maxPlayersLocal; i++)
                        ChoiceChip(
                          label: Text('$i'),
                          selected: _playerCount == i,
                          onSelected: (_) => setState(() => _playerCount = i),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Board size', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Slider(
                    value: _boardSize.toDouble(),
                    min: AppConstants.minBoardSize.toDouble(),
                    max: AppConstants.maxBoardSize.toDouble(),
                    divisions: AppConstants.maxBoardSize - AppConstants.minBoardSize,
                    label: '$_boardSize × $_boardSize',
                    onChanged: (v) => setState(() => _boardSize = v.round()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Names', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _playerCount; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _names[i],
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.playerPalette[i],
                              shape: BoxShape.circle,
                            ),
                            width: 8, height: 8,
                          ),
                          labelText: 'Player ${i + 1}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              expanded: true,
              icon: Icons.play_arrow_rounded,
              label: 'Start match',
              onPressed: () {
                final names = _names.take(_playerCount).map((c) => c.text.trim().isEmpty ? 'Player' : c.text.trim());
                context.push(
                  '${RouteNames.localBoard}?size=$_boardSize&names=${names.join(',')}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
