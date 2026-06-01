import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus { pending, accepted, rejected }

class FriendRequest {
  final String id;
  final String fromUid;
  final String toUid;
  final String fromName;
  final String? fromPhoto;
  final String? toName;
  final String? toPhoto;
  final FriendRequestStatus status;
  final DateTime? createdAt;
  final DateTime? respondedAt;

  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.fromName,
    this.fromPhoto,
    this.toName,
    this.toPhoto,
    required this.status,
    this.createdAt,
    this.respondedAt,
  });

  factory FriendRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return FriendRequest(
      id: doc.id,
      fromUid: (d['fromUid'] as String?) ?? '',
      toUid: (d['toUid'] as String?) ?? '',
      fromName: (d['fromName'] as String?) ?? '',
      fromPhoto: d['fromPhoto'] as String?,
      toName: d['toName'] as String?,
      toPhoto: d['toPhoto'] as String?,
      status: FriendRequestStatus.values.firstWhere(
        (s) => s.name == (d['status'] as String?),
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      respondedAt: (d['respondedAt'] as Timestamp?)?.toDate(),
    );
  }
}
