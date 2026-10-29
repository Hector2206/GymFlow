import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/main.dart';
import 'package:mobile/pages/login_page.dart';
import 'package:mobile/pages/splash_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Simular un dispositivo sin sesión iniciada.
    // No utiliza una cuenta real ni consulta Backend.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GymFlow inicia correctamente', (WidgetTester tester) async {
    // Iniciar la aplicación.
    await tester.pumpWidget(const GymFlowApp());

    // Verificar que la aplicación se construye.
    expect(find.byType(GymFlowApp), findsOneWidget);

    // Verificar que comienza en Splash.
    expect(find.byType(SplashPage), findsOneWidget);

    // Avanzar los 5 segundos del Splash.
    await tester.pump(const Duration(seconds: 5));

    // Procesar la consulta local de sesión
    // y completar la navegación.
    await tester.pump();
    await tester.pumpAndSettle();

    // Sin sesión guardada, debe abrir Login.
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
