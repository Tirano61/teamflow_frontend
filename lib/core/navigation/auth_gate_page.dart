import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/user_context/presentation/pages/no_organization_page.dart';
import '../../features/user_context/presentation/pages/organization_selection_page.dart';
import '../../features/user_context/presentation/pages/user_context_error_page.dart';
import '../widgets/integration_menu_page.dart';
import 'post_auth_destination.dart';

/// Punto unico donde se aplica la decision de navegacion posterior al login.
///
/// No decide nada por su cuenta: renderiza el destino que resolvio
/// [PostAuthDestinationResolver] a partir del `AuthState`.
class AuthGatePage extends StatelessWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        switch (PostAuthDestinationResolver.resolve(state)) {
          case PostAuthDestination.pending:
            return const _AuthGateLoadingView();
          case PostAuthDestination.login:
            return const LoginPage();
          case PostAuthDestination.workspace:
            return const IntegrationMenuPage();
          case PostAuthDestination.organizationSelection:
            return const OrganizationSelectionPage();
          case PostAuthDestination.noOrganization:
            return const NoOrganizationPage();
          case PostAuthDestination.userContextError:
            return const UserContextErrorPage();
        }
      },
    );
  }
}

class _AuthGateLoadingView extends StatelessWidget {
  const _AuthGateLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
