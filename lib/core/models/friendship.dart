import 'package:cloud_firestore/cloud_firestore.dart';

class Friendship {
  final String id;
  final List<String> users;
  final DateTime? createdAt;

  const Friendship({required this.id, required this.users, this.createdAt});

  factory Friendship.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Friendship(
      id: doc.id,
      users: ((d['users'] as List?) ?? const []).cast<String>(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  String otherUid(String me) => users.firstWhere((u) => u != me, orElse: () => '');
}
