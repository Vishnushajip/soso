import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/match_record.dart';

class MatchHistoryRepository {
  MatchHistoryRepository(this._firestore, this._prefs);

  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  static const _localMatchKey = 'cached_match_history_records';
  final Map<String, MatchRecord> _memoryCache = {};

  CollectionReference<Map<String, dynamic>> _userMatchesCol(String uid) =>
      _firestore.collection(AppConstants.usersCollection).doc(uid).collection('matches');

  Future<void> saveMatch({
    required String? uid,
    required MatchRecord match,
  }) async {
    _memoryCache[match.id] = match;

    // Save locally
    try {
      final existingJson = _prefs.getStringList(_localMatchKey) ?? [];
      final encoded = jsonEncode(match.toMap());
      final updatedList = [encoded, ...existingJson];
      // Keep up to 25 local matches
      if (updatedList.length > 25) {
        updatedList.removeRange(25, updatedList.length);
      }
      await _prefs.setStringList(_localMatchKey, updatedList);
    } catch (_) {}

    // Save to Firestore if user has a uid
    if (uid != null && uid.isNotEmpty) {
      try {
        await _userMatchesCol(uid).doc(match.id).set(match.toMap());
      } catch (_) {}
    }
  }

  Future<List<MatchRecord>> getRecentMatches(String? uid, {int limit = 20}) async {
    final matches = <String, MatchRecord>{};

    // Load from memory
    matches.addAll(_memoryCache);

    // Load from local storage
    try {
      final localJson = _prefs.getStringList(_localMatchKey) ?? [];
      for (final raw in localJson) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final m = MatchRecord.fromMap(decoded);
          matches[m.id] = m;
        } catch (_) {}
      }
    } catch (_) {}

    // Load from Firestore if online
    if (uid != null && uid.isNotEmpty) {
      try {
        final snap = await _userMatchesCol(uid)
            .orderBy('playedAt', descending: true)
            .limit(limit)
            .get();
        for (final doc in snap.docs) {
          final m = MatchRecord.fromDoc(doc);
          matches[m.id] = m;
          _memoryCache[m.id] = m;
        }
      } catch (_) {}
    }

    final list = matches.values.toList()
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
    if (list.length > limit) {
      return list.sublist(0, limit);
    }
    return list;
  }

  Future<MatchRecord?> getMatchById(String? uid, String matchId) async {
    if (_memoryCache.containsKey(matchId)) {
      return _memoryCache[matchId];
    }

    // Check local storage
    try {
      final localJson = _prefs.getStringList(_localMatchKey) ?? [];
      for (final raw in localJson) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        if (decoded['id'] == matchId) {
          final m = MatchRecord.fromMap(decoded);
          _memoryCache[m.id] = m;
          return m;
        }
      }
    } catch (_) {}

    // Check Firestore
    if (uid != null && uid.isNotEmpty) {
      try {
        final doc = await _userMatchesCol(uid).doc(matchId).get();
        if (doc.exists) {
          final m = MatchRecord.fromDoc(doc);
          _memoryCache[m.id] = m;
          return m;
        }
      } catch (_) {}
    }
    return null;
  }
}
