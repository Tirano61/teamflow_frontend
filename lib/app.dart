import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/discussions/presentation/pages/discussion_route_args.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/notifications/presentation/bloc/notification_event.dart';
import 'features/notifications/presentation/bloc/notification_state.dart';
import 'features/share_intent/presentation/bloc/share_intent_bloc.dart';
import 'features/share_intent/presentation/bloc/share_intent_event.dart';
import 'features/share_intent/presentation/bloc/share_intent_state.dart';
import 'features/share_intent/presentation/pages/share_intent_route_args.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AuthBloc _authBloc;
  late final NotificationBloc _notificationBloc;
  late final ShareIntentBloc _shareIntentBloc;
  bool _appWasInBackground = false;
  bool _shareComposerOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _authBloc = sl<AuthBloc>();
    _notificationBloc = sl<NotificationBloc>();
    _shareIntentBloc = sl<ShareIntentBloc>();
    _notificationBloc.add(const InitializeNotificationsEvent());
    _shareIntentBloc.add(const InitializeShareIntentEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shareIntentBloc.close();
    _notificationBloc.close();
    _authBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _appWasInBackground = true;
        break;
      case AppLifecycleState.resumed:
        if (_appWasInBackground) {
          _appWasInBackground = false;
          _notificationBloc.add(const NotificationAppLifecycleResumedEvent());
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<NotificationBloc>.value(value: _notificationBloc),
        BlocProvider<ShareIntentBloc>.value(value: _shareIntentBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.status != current.status ||
                previous.infoMessage != current.infoMessage,
            listener: (context, state) {
              if (AppRouter.isBrandingSplashActive.value) {
                return;
              }

              context.read<NotificationBloc>().add(
                NotificationAuthStateChangedEvent(
                  isAuthenticated: state.isAuthenticated,
                ),
              );
              context.read<ShareIntentBloc>().add(
                ShareIntentAuthStatusChangedEvent(
                  isAuthenticated: state.isAuthenticated,
                ),
              );

              final navigator = AppRouter.navigatorKey.currentState;
              final messenger = AppRouter.scaffoldMessengerKey.currentState;

              if (state.infoMessage.isNotEmpty) {
                messenger
                  ?..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.infoMessage)));
              }

              if (state.status == AuthStatus.authenticated) {
                navigator?.pushNamedAndRemoveUntil(
                  AppRoutes.home,
                  (route) => false,
                );
                return;
              }

              if (state.status == AuthStatus.unauthenticated) {
                navigator?.pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
          ),
          BlocListener<NotificationBloc, NotificationState>(
            listenWhen: (previous, current) =>
                previous.navigationRequestVersion !=
                current.navigationRequestVersion,
            listener: (context, state) {
              final discussionId = state.openDiscussionId?.trim();
              if (discussionId == null || discussionId.isEmpty) {
                return;
              }

              final navigator = AppRouter.navigatorKey.currentState;
              navigator?.pushNamed(
                AppRoutes.discussionDetail,
                arguments: DiscussionDetailRouteArgs(
                  discussionId: discussionId,
                ),
              );

              context.read<NotificationBloc>().add(
                const NotificationNavigationHandledEvent(),
              );
            },
          ),
          BlocListener<ShareIntentBloc, ShareIntentState>(
            listenWhen: (previous, current) =>
                previous.composerRequestVersion !=
                    current.composerRequestVersion ||
                previous.infoMessageVersion != current.infoMessageVersion,
            listener: (context, state) async {
              final messenger = AppRouter.scaffoldMessengerKey.currentState;

              if (state.infoMessage.trim().isNotEmpty) {
                messenger
                  ?..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.infoMessage)));
                context.read<ShareIntentBloc>().add(
                  const ShareIntentMessageConsumedEvent(),
                );
              }

              if (!state.isAuthenticated ||
                  state.pendingContent == null ||
                  _shareComposerOpen) {
                return;
              }

              _shareComposerOpen = true;
              final navigator = AppRouter.navigatorKey.currentState;
              final preferredDiscussionId = context
                  .read<NotificationBloc>()
                  .state
                  .activeDiscussionId;

              final result = await navigator?.pushNamed(
                AppRoutes.shareIntentCompose,
                arguments: ShareIntentComposeRouteArgs(
                  preferredDiscussionId: preferredDiscussionId,
                ),
              );

              _shareComposerOpen = false;

              final selectedDiscussionId = result is String
                  ? result.trim()
                  : '';
              if (selectedDiscussionId.isEmpty) {
                return;
              }

              navigator?.pushNamed(
                AppRoutes.discussionDetail,
                arguments: DiscussionDetailRouteArgs(
                  discussionId: selectedDiscussionId,
                ),
              );
            },
          ),
        ],
        child: MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          navigatorKey: AppRouter.navigatorKey,
          scaffoldMessengerKey: AppRouter.scaffoldMessengerKey,
          navigatorObservers: [AppRouter.routeObserver],
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
