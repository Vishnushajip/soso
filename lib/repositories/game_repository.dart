import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/env.dart';
import '../core/utils/bot_names.dart';
import '../core/utils/id_utils.dart';
import '../core/utils/sos_engine.dart';
import '../models/app_user.dart';
import '../models/game_room.dart';

class GameRepository {
  GameRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection(AppConstants.gameRoomsCollection);
  CollectionReference<Map<String, dynamic>> get _notifs =>
      _firestore.collection(AppConstants.notificationsCollection);

  Stream<GameRoom?> watchRoom(String roomId) => _rooms
      .doc(roomId)
      .snapshots()
      .map((d) => d.exists ? GameRoom.fromDoc(d) : null);

  Future<GameRoom?> findByCode(String code) async {
    final snap = await _rooms
        .where('code', isEqualTo: code.toUpperCase())
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : GameRoom.fromDoc(snap.docs.first);
  }

  Future<GameRoom?> findQuickMatch({
    GameRoomType type = GameRoomType.quick,
  }) async {
    final snap = await _rooms
        .where('type', isEqualTo: type.name)
        .where('status', isEqualTo: 'waiting')
        .orderBy('createdAt')
        .limit(5)
        .get();
    return snap.docs.isEmpty ? null : GameRoom.fromDoc(snap.docs.first);
  }

  Future<GameRoom> createRoom({
    required AppUser host,
    required GameRoomType type,
    int maxPlayers = 2,
    int? boardSize,
    bool magicEnabled = true,
  }) async {
    final ref = _rooms.doc();
    final size = boardSize ?? Env.boardSize;
    final room = {
      'code': type == GameRoomType.private || type == GameRoomType.friend
          ? IdUtils.generateRoomCode()
          : null,
      'type': type.name,
      'status': 'waiting',
      'hostId': host.uid,
      'players': [
        GamePlayer(uid: host.uid, name: host.name, photoUrl: host.photoUrl).toMap(),
      ],
      'playerIds': [host.uid],
      'maxPlayers': maxPlayers,
      'boardSize': size,
      'board': List<String>.filled(size * size, ''),
      'currentTurn': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'magicEnabled': magicEnabled,
    };
    await ref.set(room);
    return GameRoom.fromDoc(await ref.get());
  }

  Future<void> inviteFriend({required GameRoom room, required String friendUid, required String hostName}) async {
    await _notifs.add({
      'toUid': friendUid,
      'type': 'matchInvite',
      'title': 'Match invite',
      'body': '$hostName invited you to a match',
      'data': {'roomId': room.id, 'code': room.code},
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> joinRoom({required String roomId, required AppUser user}) async {
    await _firestore.runTransaction((tx) async {
      final ref = _rooms.doc(roomId);
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Room not found');
      final room = GameRoom.fromDoc(snap);
      if (room.status != GameRoomStatus.waiting) throw StateError('Room is not joinable');
      if (room.playerIds.contains(user.uid)) return;
      if (room.players.length >= room.maxPlayers) throw StateError('Room full');

      final newPlayer = GamePlayer(uid: user.uid, name: user.name, photoUrl: user.photoUrl);
      final updatedPlayers = [...room.players, newPlayer];
      final shouldStart = updatedPlayers.length >= room.maxPlayers;

      tx.update(ref, {
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
        'playerIds': FieldValue.arrayUnion([user.uid]),
        if (shouldStart) 'status': 'active',
        if (shouldStart) 'startedAt': FieldValue.serverTimestamp(),
      });

      if (shouldStart) {
        for (final p in updatedPlayers) {
          tx.set(_notifs.doc(), {
            'toUid': p.uid,
            'type': 'matchStarted',
            'title': 'Match started',
            'body': 'Your match is now live',
            'data': {'roomId': roomId},
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  Future<void> startNow(String roomId) =>
      _rooms.doc(roomId).update({'status': 'active', 'startedAt': FieldValue.serverTimestamp()});

  /// Fills any empty seats in a still-waiting room with realistic-looking AI
  /// players and starts the match. Used as a matchmaking fallback so a player
  /// never gets stuck waiting for a human opponent. No-op if the room already
  /// started or filled (e.g. a real player joined first).
  Future<void> addBotAndStart(String roomId) async {
    await _firestore.runTransaction((tx) async {
      final ref = _rooms.doc(roomId);
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final room = GameRoom.fromDoc(snap);
      if (room.status != GameRoomStatus.waiting) return;
      if (room.players.length >= room.maxPlayers) return;

      final rng = Random();
      final players = [...room.players];
      while (players.length < room.maxPlayers) {
        String name;
        do {
          name = BotNames.randomName(rng);
        } while (players.any((p) => p.name == name));
        players.add(
          GamePlayer(uid: BotNames.generateBotUid(rng), name: name, isBot: true),
        );
      }

      tx.update(ref, {
        'players': players.map((p) => p.toMap()).toList(),
        'status': 'active',
        'startedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> abandon(String roomId) =>
      _rooms.doc(roomId).update({'status': 'abandoned', 'finishedAt': FieldValue.serverTimestamp()});

  /// Places a letter, recalculates score, advances/ends the game, all atomically.
  Future<int> placeLetter({
    required String roomId,
    required String playerId,
    required int position,
    required String letter, // 'S' | 'O'
  }) async {
    int sosGained = 0;
    await _firestore.runTransaction((tx) async {
      final ref = _rooms.doc(roomId);
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Room not found');
      final room = GameRoom.fromDoc(snap);
      if (room.status != GameRoomStatus.active) throw StateError('Game is not active');
      if (room.players[room.currentTurn].uid != playerId) throw StateError('Not your turn');
      if (room.board[position].isNotEmpty) throw StateError('Cell occupied');

      final engine = SosEngine(room.boardSize);
      final sosLines = engine.findSosCreated(
        board: room.board,
        pos: position,
        letter: letter == 'S' ? SosLetter.s : SosLetter.o,
      );

      final newBoard = [...room.board]..[position] = letter;
      sosGained = sosLines.length;
      final scored = sosGained > 0;

      final updatedPlayers = [...room.players];
      if (scored) {
        final cur = updatedPlayers[room.currentTurn];
        updatedPlayers[room.currentTurn] =
            cur.copyWith(score: cur.score + sosGained * AppConstants.pointsPerSos);
      }

      final boardFull = newBoard.every((c) => c.isNotEmpty);
      final nextTurn = scored
          ? room.currentTurn
          : (room.currentTurn + 1) % updatedPlayers.length;

      String? winnerId;
      String? newStatus;
      if (boardFull) {
        newStatus = 'finished';
        var topScore = -1;
        for (final p in updatedPlayers) {
          if (p.score > topScore) {
            topScore = p.score;
            winnerId = p.uid;
          } else if (p.score == topScore) {
            winnerId = null; // tie
          }
        }
      }

      final updates = <String, dynamic>{
        'board': newBoard,
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
        'currentTurn': nextTurn,
        'lastPlacedPosition': position,
        'lastPlacedLetter': letter,
        'lastPlacedPlayerId': playerId,
      };
      if (newStatus != null) {
        updates['status'] = newStatus;
        updates['finishedAt'] = FieldValue.serverTimestamp();
        updates['winnerId'] = winnerId;
      }
      tx.update(ref, updates);

      tx.set(ref.collection(AppConstants.movesSubcollection).doc(), {
        'roomId': roomId,
        'playerId': playerId,
        'position': position,
        'letter': letter,
        'sosCount': sosGained,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    return sosGained;
  }

  Future<void> eraseCellOnline({
    required String roomId,
    required int position,
  }) async {
    final ref = _rooms.doc(roomId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final room = GameRoom.fromDoc(snap);
      if (room.status != GameRoomStatus.active) return;
      
      final newBoard = [...room.board]..[position] = '';
      tx.update(ref, {
        'board': newBoard,
        'lastPlacedPosition': null,
        'lastPlacedLetter': null,
        'lastPlacedPlayerId': null,
      });
    });
  }
}
