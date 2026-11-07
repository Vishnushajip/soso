import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/view/sign_in_screen.dart';
import '../../features/auth/view/splash_screen.dart';
import '../../features/chat/view/chat_list_screen.dart';
import '../../features/chat/view/chat_screen.dart';
import '../../features/chat/view/global_chat_screen.dart';
import '../../features/friends/view/add_friend_screen.dart';
import '../../features/friends/view/friend_requests_screen.dart';
import '../../features/friends/view/friends_screen.dart';
import '../../features/flappy_bird/view/flappy_difficulty_screen.dart';
import '../../features/game/view/ai_game_board_screen.dart';
import '../../features/game/view/game_board_screen.dart';
import '../../features/game/view/game_mode_select_screen.dart';
import '../../features/game/view/local_game_board_screen.dart';
import '../../features/game/view/local_game_setup_screen.dart';
import '../../features/game/view/match_summary_screen.dart';
import '../../features/game/view/online_lobby_screen.dart';
import '../../features/home/view/main_shell.dart';
import '../../features/leaderboard/view/leaderboard_screen.dart';
import '../../features/notifications/view/notifications_screen.dart';
import '../../features/profile/view/about_screen.dart';
import '../../features/profile/view/contact_support_screen.dart';
import '../../features/profile/view/match_history_screen.dart';
import '../../features/profile/view/privacy_screen.dart';
import '../../features/profile/view/profile_screen.dart';
import '../utils/bot_engine.dart';
import '../../features/profile/view/shop_screen.dart';
import '../../features/profile/view/terms_screen.dart';
import '../../features/settings/view/settings_screen.dart';
import '../providers/auth_providers.dart';
import '../providers/repository_providers.dart';
import 'route_names.dart';

class _GoRouterRefresh extends ChangeNotifier {
  _GoRouterRefresh(Stream stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Root navigator key — lets app-wide overlays (e.g. the update dialog) obtain
/// a navigator/overlay context regardless of the current route.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStream = ref.watch(authRepositoryProvider).authStateChanges;
  final refresh = _GoRouterRefresh(authStream);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final normalizedLoc = loc.endsWith('/') && loc.length > 1
          ? loc.substring(0, loc.length - 1)
          : loc;

      // Allow public routes without authentication or splash redirect.
      // Essential for Google Play Store compliance (e.g. Privacy Policy & Terms).
      const publicRoutes = {
        RouteNames.privacy,
        RouteNames.terms,
        RouteNames.about,
        RouteNames.contact,
      };

      if (publicRoutes.contains(normalizedLoc)) {
        return null;
      }

      final auth = ref.read(authStateProvider);

      if (auth.isLoading) {
        return loc == RouteNames.splash ? null : RouteNames.splash;
      }

      if (loc == RouteNames.splash) {
        return null;
      }

      final loggedIn = auth.valueOrNull != null;

      if (loggedIn) {
        if (loc == RouteNames.signIn) {
          return RouteNames.home;
        }
        return null;
      }

      return loc == RouteNames.signIn ? null : RouteNames.signIn;
    },
    routes: [
      GoRoute(path: RouteNames.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: RouteNames.signIn, builder: (context, state) => const SignInScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: RouteNames.home, builder: (context, state) => const GameModeSelectScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: RouteNames.friends, builder: (context, state) => const FriendsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: RouteNames.shop, builder: (context, state) => const ShopScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: RouteNames.leaderboard, builder: (context, state) => const LeaderboardScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: RouteNames.profile, builder: (context, state) => const ProfileScreen()),
            ],
          ),
        ],
      ),

      GoRoute(path: RouteNames.flappyGame, builder: (context, state) => const FlappyDifficultyScreen()),

      GoRoute(path: RouteNames.gameModes, builder: (context, state) => const GameModeSelectScreen()),
      GoRoute(path: RouteNames.localSetup, builder: (context, state) => const LocalGameSetupScreen()),
      GoRoute(path: RouteNames.localBoard, builder: (context, state) {
        final size = int.tryParse(state.uri.queryParameters['size'] ?? '') ?? 8;
        final names = (state.uri.queryParameters['names'] ?? '').split(',');
        final magic = state.uri.queryParameters['magicEnabled'] != 'false';
        return LocalGameBoardScreen(
          boardSize: size,
          playerNames: names,
          magicEnabled: magic,
        );
      }),
      GoRoute(path: RouteNames.onlineLobby, builder: (context, state) => const OnlineLobbyScreen()),
      GoRoute(path: RouteNames.gameBoard, builder: (context, state) {
        final roomId = state.uri.queryParameters['roomId'] ?? '';
        return GameBoardScreen(roomId: roomId);
      }),
      GoRoute(path: RouteNames.matchSummary, builder: (context, state) {
        final roomId = state.uri.queryParameters['roomId'] ?? '';
        return MatchSummaryScreen(roomId: roomId);
      }),

      GoRoute(path: RouteNames.friendRequests, builder: (context, state) => const FriendRequestsScreen()),
      GoRoute(path: RouteNames.addFriend, builder: (context, state) => const AddFriendScreen()),
      GoRoute(path: RouteNames.chatRoom, builder: (context, state) {
        final roomId = state.uri.queryParameters['roomId'] ?? '';
        final autoSend = state.uri.queryParameters['autoSend'];
        return ChatScreen(roomId: roomId, autoSend: autoSend);
      }),
      GoRoute(path: RouteNames.globalChat, builder: (context, state) => const GlobalChatScreen()),

      GoRoute(path: RouteNames.notifications, builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: RouteNames.settings, builder: (context, state) => const SettingsScreen()),
      GoRoute(path: RouteNames.about, builder: (context, state) => const AboutScreen()),
      GoRoute(path: RouteNames.privacy, builder: (context, state) => const PrivacyScreen()),
      GoRoute(path: RouteNames.terms, builder: (context, state) => const TermsScreen()),
      GoRoute(path: RouteNames.contact, builder: (context, state) => const ContactSupportScreen()),
      GoRoute(path: RouteNames.chatList, builder: (context, state) => const ChatListScreen()),
      GoRoute(path: RouteNames.profileDetail, builder: (context, state) {
        final uid = state.uri.queryParameters['uid'];
        return ProfileScreen(uid: uid);
      }),
      GoRoute(path: RouteNames.aiBoard, builder: (context, state) {
        final size = int.tryParse(state.uri.queryParameters['size'] ?? '') ?? 8;
        final diffStr = state.uri.queryParameters['difficulty'] ?? 'medium';
        final difficulty = BotDifficulty.values.firstWhere(
          (d) => d.name == diffStr,
          orElse: () => BotDifficulty.medium,
        );
        final magic = state.uri.queryParameters['magic'] != 'false';
        return AIGameBoardScreen(
          boardSize: size,
          difficulty: difficulty,
          magicEnabled: magic,
        );
      }),
      GoRoute(path: RouteNames.matchHistory, builder: (context, state) => const MatchHistoryScreen()),
      GoRoute(path: RouteNames.matchReplay, builder: (context, state) => const MatchHistoryScreen()),
    ],
  );
});
