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
import '../features/profile/view/shop_screen.dart';
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
      GoRoute(path: RouteNames.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: RouteNames.signIn, builder: (context, state) => const SignInScreen()),

      // Shell with bottom navigation.
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: RouteNames.home, builder: (context, state) => const GameModeSelectScreen()),
          GoRoute(path: RouteNames.friends, builder: (context, state) => const FriendsScreen()),
          GoRoute(path: RouteNames.chatList, builder: (context, state) => const ChatListScreen()),
          GoRoute(path: RouteNames.leaderboard, builder: (context, state) => const LeaderboardScreen()),
          GoRoute(path: RouteNames.profile, builder: (context, state) => const ProfileScreen()),
        ],
      ),

      // Game flow.
      GoRoute(path: RouteNames.gameModes, builder: (context, state) => const GameModeSelectScreen()),
      GoRoute(path: RouteNames.localSetup, builder: (context, state) => const LocalGameSetupScreen()),
      GoRoute(path: RouteNames.localBoard, builder: (context, state) {
        final size = int.tryParse(state.uri.queryParameters['size'] ?? '') ?? 8;
        final names = (state.uri.queryParameters['names'] ?? '').split(',');
        return LocalGameBoardScreen(boardSize: size, playerNames: names);
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

      // Friends / chat detail screens.
      GoRoute(path: RouteNames.friendRequests, builder: (context, state) => const FriendRequestsScreen()),
      GoRoute(path: RouteNames.addFriend, builder: (context, state) => const AddFriendScreen()),
      GoRoute(path: RouteNames.chatRoom, builder: (context, state) {
        final roomId = state.uri.queryParameters['roomId'] ?? '';
        return ChatScreen(roomId: roomId);
      }),
      GoRoute(path: RouteNames.globalChat, builder: (context, state) => const GlobalChatScreen()),

      // Static / utility.
      GoRoute(path: RouteNames.notifications, builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: RouteNames.settings, builder: (context, state) => const SettingsScreen()),
      GoRoute(path: RouteNames.about, builder: (context, state) => const AboutScreen()),
      GoRoute(path: RouteNames.privacy, builder: (context, state) => const PrivacyScreen()),
      GoRoute(path: RouteNames.terms, builder: (context, state) => const TermsScreen()),
      GoRoute(path: RouteNames.contact, builder: (context, state) => const ContactSupportScreen()),
      GoRoute(path: RouteNames.shop, builder: (context, state) => const ShopScreen()),
    ],
  );
});
