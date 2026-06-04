import 'dart:math';

/// Real-sounding display names + uids for fill-in AI opponents, so a player
/// who can't be matched with a human never realises they're playing a bot.
class BotNames {
  BotNames._();

  static const List<String> _names = [
    'Liam Carter',
    'Olivia Bennett',
    'Noah Mitchell',
    'Emma Sullivan',
    'Lucas Reed',
    'Ava Morgan',
    'Ethan Brooks',
    'Sophia Hayes',
    'Mason Cole',
    'Isabella Ford',
    'Logan Price',
    'Mia Russell',
    'Jack Turner',
    'Amelia Foster',
    'Daniel Hughes',
    'Harper Ross',
    'Ryan Coleman',
    'Ella Brooks',
    'Nathan Wells',
    'Chloe Parker',
    'Caleb Grant',
    'Grace Newman',
    'Owen Fisher',
    'Lily Hudson',
    'Adrian Vance',
  ];

  /// A random realistic full name.
  static String randomName([Random? random]) {
    final rng = random ?? Random();
    return _names[rng.nextInt(_names.length)];
  }

  /// Opaque uid for a bot player. Prefixed so we can recognise it later.
  static String generateBotUid([Random? random]) {
    final rng = random ?? Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final suffix =
        List.generate(12, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'bot_$suffix';
  }

  /// Whether a player uid belongs to a fill-in bot.
  static bool isBotUid(String uid) => uid.startsWith('bot_');
}
