import '../services/sound_service.dart';

class Emote {
  final String id;
  final String emoji;
  final String label;
  final AppSound sound;

  const Emote({
    required this.id,
    required this.emoji,
    required this.label,
    required this.sound,
  });

  static const List<Emote> all = [
    Emote(id: 'gg', emoji: '👑', label: 'GG!', sound: AppSound.notify),
    Emote(id: 'easy', emoji: '😎', label: 'TOO EASY!', sound: AppSound.notify),
    Emote(id: 'omg', emoji: '😱', label: 'OMG!', sound: AppSound.notify),
    Emote(id: 'fire', emoji: '😡', label: 'GRRR!', sound: AppSound.notify),
    Emote(id: 'think', emoji: '🤔', label: 'THINKING...', sound: AppSound.notify),
    Emote(id: 'bullseye', emoji: '🎯', label: 'NICE MOVE!', sound: AppSound.point),
    Emote(id: 'cry', emoji: '😭', label: 'NOOO!', sound: AppSound.notify),
    Emote(id: 'party', emoji: '🥳', label: 'PARTY TIME!', sound: AppSound.notify),
    Emote(id: 'bolt', emoji: '⚡', label: 'SPEED UP!', sound: AppSound.notify),
    Emote(id: 'handshake', emoji: '🤝', label: 'GOOD LUCK!', sound: AppSound.notify),
  ];
}
