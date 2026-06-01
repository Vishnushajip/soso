import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../models/app_user.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_providers.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});
  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _ctrl = TextEditingController();
  List<AppUser> _results = const [];
  bool _busy = false;
  String? _error;

  Future<void> _search() async {
    final query = _ctrl.text.trim();
    if (query.isEmpty) return;
    
    setState(() { _busy = true; _error = null; });
    try {
      final isNumeric = RegExp(r'^\d+$').hasMatch(query);
      if (isNumeric) {
        // Search by exact unique 8-digit numeric player ID
        final user = await ref.read(userRepositoryProvider).getUserByUniqueId(query);
        if (user != null) {
          _results = [user];
        } else {
          _results = const [];
        }
      } else {
        // Search alphabetically by user name
        _results = await ref.read(userRepositoryProvider).searchByName(query);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send(AppUser other) async {
    final me = ref.read(currentUserProvider).valueOrNull;
    if (me == null) return;
    try {
      await ref.read(friendRepositoryProvider).sendRequest(
            fromUid: me.uid, fromName: me.name, fromPhoto: me.photoUrl, toUid: other.uid,
          );
      ref.read(soundServiceProvider).play(AppSound.friendSent);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent to ${other.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Friend')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: (_) => _search(),
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      hintText: 'Search by name or player ID (e.g. 51234567)',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(label: 'Search', onPressed: _search, busy: _busy),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: _results.isEmpty
                  ? const SectionCard(child: Center(child: Text('No results yet — search above')))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final u = _results[i];
                        final isMe = u.uid == me?.uid;
                        return SectionCard(
                          child: Row(
                            children: [
                              UserAvatar(
                                name: u.name,
                                photoUrl: u.photoUrl,
                                online: u.isOnline,
                                frameColor: u.avatarFrameColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                        if (u.customTitle != null && u.customTitle!.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppColors.secondary.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              u.customTitle!,
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.secondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (u.uniqueId.isNotEmpty)
                                      Text(
                                        'ID: ${u.uniqueId}',
                                        style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 11),
                                      ),
                                  ],
                                ),
                              ),
                              if (!isMe)
                                AppButton(
                                  icon: Icons.person_add_alt_1,
                                  label: 'Add',
                                  onPressed: () => _send(u),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
