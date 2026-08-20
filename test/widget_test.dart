import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:developer_workflow/app.dart';
import 'package:developer_workflow/core/di/service_locator.dart';

void main() {
  testWidgets('App bootstrap smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await configureDependencies();

    await tester.pumpWidget(const MyApp());

    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesion'), findsWidgets);
    expect(
      find.text('Autenticacion obligatoria para /develop-workflow'),
      findsOneWidget,
    );
  });
}
