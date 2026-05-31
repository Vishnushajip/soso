import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/view/sign_in_screen.dart';
import '../features/auth/view/splash_screen.dart';
import '../features/chat/view/chat_list_screen.dart';
import '../features/chat/view/chat_screen.dart';
import '../features/chat/view/global_chat_screen.dart';
import '../features/friends/view/add_friend_screen.dart';
import '../features/friends/view/friend_requests_screen.dart';
import '../features/friends/view/friends_screen.dart';
import '../features/game/view/game_board_screen.dart';
import '../features/game/view/game_mode_select_screen.dart';
import '../features/game/view/local_game_board_screen.dart';
import '../features/game/view/local_game_setup_screen.dart';
import '../features/game/view/match_summary_screen.dart';
import '../features/game/view/online_lobby_screen.dart';
import '../features/home/view/main_shell.dart';
import '../features/leaderboard/view/leaderboard_screen.dart';
import '../features/notifications/view/notifications_screen.dart';
import '../features/profile/view/about_screen.dart';
import '../features/profile/view/contact_support_screen.dart';
import '../features/profile/view/privacy_screen.dart';
import '../features/profile/view/profile_screen.dart';
import '../features/profile/view/terms_screen.dart';
import '../features/settings/view/settings_screen.dart';
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

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStream = ref.watch(authRepositoryProvider).authStateChanges;
  final refresh = _GoRouterRefresh(authStream);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final loc = state.matchedLocation;

      // Stream hasn't emitted yet — stay on splash so we don't flicker sign-in.
      if (auth.isLoading) {
        return loc == RouteNames.splash ? null : RouteNames.splash;
      }

      final loggedIn = auth.valueOrNull != null;

      if (loggedIn) {
        if (loc == RouteNames.splash || loc == RouteNames.signIn) {
          return RouteNames.home;
        }
        return null;
      }

      // Signed out — anywhere except the sign-in screen redirects to sign-in.
      return loc == RouteNames.signIn ? null : RouteNames.signIn;
    },
    routes: [
      GoRoute(path: RouteNames.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: RouteNames.signIn, builder: (_, __) => const SignInScreen()),

      // Shell with bottom navigation.
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: RouteNames.home, builder: (_, __) => const GameModeSelectScreen()),
          GoRoute(path: RouteNames.friends, builder: (_, __) => const FriendsScreen()),
          GoRoute(path: RouteNames.chatList, builder: (_, __) => const ChatListScreen()),
          GoRoute(path: RouteNames.leaderboard, builder: (_, __) => const LeaderboardScreen()),
          GoRoute(path: RouteNames.profile, builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Game flow.
      GoRoute(path: RouteNames.gameModes, builder: (_, __) => const GameModeSelectScreen()),
      GoRoute(path: RouteNames.localSetup, builder: (_, __) => const LocalGameSetupScreen()),
      GoRoute(path: RouteNames.localBoard, builder: (_, state) {
        final size = int.tryParse(state.uri.queryParameters['size'] ?? '') ?? 8;
        final names = (state.uri.queryParameters['names'] ?? '').split(',');
        return LocalGameBoardScreen(boardSize: size, playerNames: names);
      }),
      GoRoute(path: RouteNames.onlineLobby, builder: (_, __) => const OnlineLobbyScreen()),
      GoRoute(path: RouteNames.gameBoard, builder: (_, state) {
        final roomId = state.uri.queryParameters['roomId'] ?? '';
        return GameBoardScreen(roomId: roomId);
      }),
      GoRoute(path: RouteNames.matchSummary, builder: (_, state) {
        final roomId = state.uri.queryParameters['roomId'] ?? '';
        return MatchSummaryScreen(roomId: roomId);
      }),

      // Friends / chat detail screens.
      GoRoute(path: RouteNames.friendRequests, builder: (_, __) => const FriendRequestsScreen()),
      GoRoute(path: RouteNames.addFriend, builder: (_, __) => const AddFriendScreen()),
      GoRoute(path: RouteNames.chatRoom, builder: (_, state) {
        final roomId = state.uri.queryParameters['roomId'] ?? '';
        return ChatScreen(roomId: roomId);
      }),
      GoRoute(path: RouteNames.globalChat, builder: (_, __) => const GlobalChatScreen()),

      // Static / utility.
      GoRoute(path: RouteNames.notifications, builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: RouteNames.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: RouteNames.about, builder: (_, __) => const AboutScreen()),
      GoRoute(path: RouteNames.privacy, builder: (_, __) => const PrivacyScreen()),
      GoRoute(path: RouteNames.terms, builder: (_, __) => const TermsScreen()),
      GoRoute(path: RouteNames.contact, builder: (_, __) => const ContactSupportScreen()),
    ],
  );
});
