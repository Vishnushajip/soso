import 'dart:math';

class IdUtils {
  IdUtils._();

  /// Stable id for a friendship between two users, independent of order.
  static String friendshipId(String a, String b) =>
      (a.compareTo(b) < 0) ? '${a}_$b' : '${b}_$a';

  /// Stable id for a 1-to-1 direct chat room.
  static String directChatRoomId(String a, String b) => friendshipId(a, b);

  /// 6-character uppercase room code (no ambiguous characters).
  static String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
